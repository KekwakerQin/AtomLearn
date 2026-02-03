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
    private let ownerId: String
    private let aiService: FlashcardsAIServiceProtocol
    private let cardsService: CardsService
    private let model: String

    private(set) var state: State {
        didSet { onStateChange?(state) }
    }

    var onStateChange: ((State) -> Void)?

    let counts = [1, 5, 10, 20]

    init(
        boardId: String,
        ownerId: String,
        aiService: FlashcardsAIServiceProtocol = FlashcardsAIService(),
        cardsService: CardsService = CardsRepository(),
        model: String = "tngtech/deepseek-r1t2-chimera:free"
    ) {
        self.boardId = boardId
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

    private func generate(prompt: String) async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let count = counts[state.selectedCountIndex]
            let drafts = try await aiService.generateFlashcards(prompt: prompt, count: count, model: model)
            state.cards = drafts.map { GeneratedCardItem(draft: $0) }
            state.isLoading = false
        } catch {
            state.isLoading = false
            state.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func accept(id: UUID) {
        guard let idx = state.cards.firstIndex(where: { $0.id == id }) else { return }
        guard state.cards[idx].status == .pending else { return }

        let draft = state.cards[idx].draft
        Task { [weak self] in
            guard let self else { return }
            do {
                try await cardsService.addCards(
                    boardId: boardId,
                    ownerId: ownerId,
                    drafts: [draft],
                    sourceKind: .ai,
                    sourceRef: "openrouter"
                )
                await MainActor.run {
                    self.state.cards[idx].status = .added
                }
            } catch {
                await MainActor.run {
                    self.state.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }

    func skip(id: UUID) {
        guard let idx = state.cards.firstIndex(where: { $0.id == id }) else { return }
        guard state.cards[idx].status == .pending else { return }
        state.cards[idx].status = .skipped
    }
}
