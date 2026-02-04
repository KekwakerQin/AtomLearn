import Foundation

@MainActor
final class AICreateCardsViewModel {
    struct State: Equatable {
        var inputText: String
        var selectedCountIndex: Int
        var isLoading: Bool
        var cards: [GeneratedCardItem]
        var errorMessage: String?
    }

    private let boardId: String
    private let boardTitle: String
    private let ownerId: String
    private let aiService: FlashcardsAIServiceProtocol
    private let cardsService: CardsService
    private let model: String

    private var existingKeys: Set<String> = []
    private var existingFronts: Set<String> = []
    private var existingSamples: [String] = []

    private(set) var state: State {
        didSet { onStateChange?(state) }
    }

    var onStateChange: ((State) -> Void)?

    let counts = [1, 5, 10, 20]

    init(
        boardId: String,
        boardTitle: String,
        ownerId: String,
        aiService: FlashcardsAIServiceProtocol = FlashcardsAIService(),
        cardsService: CardsService = CardsRepository(),
        model: String = "tngtech/deepseek-r1t2-chimera:free"
    ) {
        self.boardId = boardId
        self.boardTitle = boardTitle
        self.ownerId = ownerId
        self.aiService = aiService
        self.cardsService = cardsService
        self.model = model
        self.state = State(
            inputText: "",
            selectedCountIndex: 1,
            isLoading: false,
            cards: [],
            errorMessage: nil
        )
    }

    var hasCards: Bool {
        !state.cards.isEmpty
    }

    func onViewDidLoad() {
        Task { [weak self] in
            guard let self else { return }
            await self.loadExistingCards()
        }
    }

    func updateInput(_ text: String) {
        state.inputText = text
    }

    func updateCountIndex(_ index: Int) {
        state.selectedCountIndex = index
    }

    func toggleExpand(id: UUID) {
        guard let idx = state.cards.firstIndex(where: { $0.id == id }) else { return }
        state.cards[idx].isExpanded.toggle()
    }

    func toggleSelection(id: UUID) {
        guard let idx = state.cards.firstIndex(where: { $0.id == id }) else { return }
        guard state.cards[idx].status == .pending else { return }
        state.cards[idx].isSelected.toggle()
    }

    func generateTapped() {
        let prompt = state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            state.errorMessage = "Напиши тему или запрос"
            return
        }

        Task { [weak self] in
            guard let self else { return }
            await self.generate(prompt: prompt)
        }
    }

    func addSelected() {
        let items = state.cards.filter { $0.isSelected && $0.status == .pending }
        guard !items.isEmpty else { return }
        add(items: items)
    }

    func addAll() {
        let items = state.cards.filter { $0.status == .pending }
        guard !items.isEmpty else { return }
        add(items: items)
    }

    func deleteSelected() {
        let selectedIds = Set(state.cards.filter { $0.isSelected && $0.status == .pending }.map { $0.id })
        guard !selectedIds.isEmpty else { return }
        state.cards.removeAll { selectedIds.contains($0.id) }
    }

    private func add(items: [GeneratedCardItem]) {
        let drafts = items.map { $0.draft }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await cardsService.addCards(
                    boardId: boardId,
                    ownerId: ownerId,
                    drafts: drafts,
                    sourceKind: .ai,
                    sourceRef: "openrouter"
                )

                let ids = Set(items.map { $0.id })
                await MainActor.run {
                    for idx in state.cards.indices {
                        if ids.contains(state.cards[idx].id) {
                            state.cards[idx].status = .added
                            state.cards[idx].isSelected = false
                        }
                    }
                }

                items.forEach { item in
                    let key = makeKey(front: item.draft.front, back: item.draft.back)
                    existingKeys.insert(key)
                    existingFronts.insert(normalize(item.draft.front))
                    existingSamples.append(item.draft.front)
                }
            } catch {
                await MainActor.run {
                    self.state.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }

    private func generate(prompt: String) async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let count = counts[state.selectedCountIndex]
            let drafts = try await generateUniqueCards(prompt: prompt, count: count)
            state.cards = drafts.map { GeneratedCardItem(draft: $0) }
            state.isLoading = false
        } catch {
            state.isLoading = false
            state.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func loadExistingCards() async {
        do {
            let cards = try await cardsService.fetchCards(boardId: boardId)
            existingKeys = Set(cards.map { makeKey(front: $0.front, back: $0.back) })
            existingFronts = Set(cards.map { normalize($0.front) })
            existingSamples = cards.map { $0.front }
        } catch {
            await MainActor.run {
                self.state.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    private func generateUniqueCards(prompt: String, count: Int) async throws -> [FlashcardDraft] {
        let basePrompt = buildPrompt(userPrompt: prompt)
        var unique: [FlashcardDraft] = []
        var seenKeys = existingKeys
        var seenFronts = existingFronts

        var attempts = 0
        while unique.count < count && attempts < 3 {
            let needed = count - unique.count
            let drafts = try await aiService.generateFlashcards(prompt: basePrompt, count: needed, model: model)
            for draft in drafts {
                let key = makeKey(front: draft.front, back: draft.back)
                let frontKey = normalize(draft.front)
                if seenKeys.contains(key) || seenFronts.contains(frontKey) {
                    continue
                }
                seenKeys.insert(key)
                seenFronts.insert(frontKey)
                unique.append(draft)
            }
            attempts += 1
        }

        if unique.count < count {
            state.errorMessage = "Удалось создать \(unique.count) без дублей. Попробуй уточнить запрос."
        }

        return unique
    }

    private func buildPrompt(userPrompt: String) -> String {
        var parts: [String] = []
        if !boardTitle.isEmpty {
            parts.append("Контекст доски: \(boardTitle)")
        }
        parts.append("Запрос пользователя: \(userPrompt)")

        if !existingSamples.isEmpty {
            let sample = existingSamples.prefix(12).joined(separator: "; ")
            parts.append("Уже есть карточки (не повторяй): \(sample)")
        }

        parts.append("Ответ без Markdown, только JSON массив карточек.")
        return parts.joined(separator: "\n\n")
    }

    private func normalize(_ text: String) -> String {
        let lowered = text.lowercased()
        let collapsed = lowered.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func makeKey(front: String, back: String) -> String {
        "\(normalize(front))|\(normalize(back))"
    }
}
