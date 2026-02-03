import Foundation
import PDFKit

@MainActor
final class ImportCreateCardsViewModel {
    struct State: Equatable {
        var files: [URL]
        var query: String
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
            files: [],
            query: "",
            selectedCountIndex: 1,
            isLoading: false,
            cards: [],
            errorMessage: nil
        )
    }

    func updateQuery(_ text: String) {
        state.query = text
    }

    func updateCountIndex(_ index: Int) {
        state.selectedCountIndex = index
    }

    func setFiles(_ urls: [URL]) {
        state.files = Array(urls.prefix(3))
    }

    func removeFile(at index: Int) {
        guard index < state.files.count else { return }
        state.files.remove(at: index)
    }

    func toggleExpand(id: UUID) {
        guard let idx = state.cards.firstIndex(where: { $0.id == id }) else { return }
        state.cards[idx].isExpanded.toggle()
    }

    func generateTapped() {
        let trimmedQuery = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if state.files.isEmpty && trimmedQuery.isEmpty {
            state.errorMessage = "Выбери документы или напиши запрос"
            return
        }

        Task { [weak self] in
            guard let self else { return }
            await self.generate(query: trimmedQuery)
        }
    }

    private func generate(query: String) async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let count = counts[state.selectedCountIndex]
            let context = loadDocumentsText(from: state.files)
            let prompt = buildPrompt(query: query, context: context)

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
                    sourceKind: .`import`,
                    sourceRef: "documents"
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

    private func buildPrompt(query: String, context: String) -> String {
        var parts: [String] = []
        if !query.isEmpty { parts.append("Запрос пользователя: \(query)") }
        if !context.isEmpty { parts.append("Документы:\n\(context)") }
        return parts.joined(separator: "\n\n")
    }

    private func loadDocumentsText(from urls: [URL]) -> String {
        var blocks: [String] = []

        for url in urls {
            let fileName = url.lastPathComponent
            let text = readText(from: url) ?? ""
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let snippet = trimmed.prefix(4000)
            blocks.append("Файл: \(fileName)\n\(snippet)")
        }

        return blocks.joined(separator: "\n\n---\n\n")
    }

    private func readText(from url: URL) -> String? {
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart { url.stopAccessingSecurityScopedResource() }
        }

        if url.pathExtension.lowercased() == "pdf" {
            if let doc = PDFDocument(url: url) {
                return doc.string
            }
            return nil
        }

        if let data = try? Data(contentsOf: url) {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }
}
