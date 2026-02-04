import Foundation
import PDFKit
import Vision
import UIKit

@MainActor
final class ImportCreateCardsViewModel {
    struct State: Equatable {
        var files: [BoardDocument]
        var query: String
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
    private let documentStore: BoardDocumentStore
    private let model: String

    private var existingKeys: Set<String> = []
    private var existingFronts: Set<String> = []
    private var existingSamples: [String] = []

    private(set) var state: State {
        didSet { onStateChange?(state) }
    }

    var onStateChange: ((State) -> Void)?

    let counts = [1, 5, 10, 20]

    private enum ImportGenerationError: LocalizedError {
        case emptyExtractedText
        case noGroundedCards

        var errorDescription: String? {
            switch self {
            case .emptyExtractedText:
                return "Не удалось извлечь текст из документов/изображений. Если это скан PDF — попробуй добавить изображения или PDF с текстовым слоем."
            case .noGroundedCards:
                return "Не удалось получить ни одной карточки, строго привязанной к документам. Проверь, что файл содержит текст (или попробуй изображение для OCR) и нажми «Сгенерировать» ещё раз."
            }
        }
    }

    init(
        boardId: String,
        boardTitle: String,
        ownerId: String,
        aiService: FlashcardsAIServiceProtocol = FlashcardsAIService(),
        cardsService: CardsService = CardsRepository(),
        documentStore: BoardDocumentStore = .shared,
        model: String = "tngtech/deepseek-r1t2-chimera:free"
    ) {
        self.boardId = boardId
        self.boardTitle = boardTitle
        self.ownerId = ownerId
        self.aiService = aiService
        self.cardsService = cardsService
        self.documentStore = documentStore
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

    var hasCards: Bool {
        !state.cards.isEmpty
    }

    func onViewDidLoad() {
        Task { [weak self] in
            guard let self else { return }
            await self.loadExistingCards()
            if self.state.files.isEmpty {
                let stored = self.documentStore.load(boardId: self.boardId)
                self.state.files = Array(stored.prefix(3))
            }
        }
    }

    func updateQuery(_ text: String) {
        state.query = text
    }

    func updateCountIndex(_ index: Int) {
        state.selectedCountIndex = index
    }

    func setFiles(_ urls: [URL]) {
        let stored = documentStore.addDocuments(boardId: boardId, urls: Array(urls.prefix(3)))
        state.files = stored
    }

    func removeFile(at index: Int) {
        guard index < state.files.count else { return }
        state.files.remove(at: index)
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
        let trimmedQuery = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !state.files.isEmpty else {
            state.errorMessage = "Выбери 1–3 документа или изображения"
            return
        }

        Task { [weak self] in
            guard let self else { return }
            await self.generate(query: trimmedQuery)
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
                    sourceKind: .`import`,
                    sourceRef: "documents"
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

    private func generate(query: String) async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let count = counts[state.selectedCountIndex]
            let contextRaw = await loadDocumentsText(from: state.files)
            let context = contextRaw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !context.isEmpty else {
                throw ImportGenerationError.emptyExtractedText
            }

            let prompt = buildPrompt(query: query, context: context, desiredCount: count)
            let drafts = try await generateUniqueCards(prompt: prompt, count: count, context: context)

            if drafts.isEmpty {
                state.isLoading = false
                state.errorMessage = ImportGenerationError.noGroundedCards.errorDescription
                return
            }

            state.cards = drafts.map { GeneratedCardItem(draft: $0) }
            state.isLoading = false

            if drafts.count < count {
                state.errorMessage = "Нашлось \(drafts.count) из \(count): в документах недостаточно новой информации для полного набора."
            }
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

    private func generateUniqueCards(prompt: String, count: Int, context: String) async throws -> [FlashcardDraft] {
        var unique: [FlashcardDraft] = []
        var seenKeys = existingKeys
        var seenFronts = existingFronts

        let contextTokens = tokens(context)
        let contextLoose = normalizeLoose(context)

        var attempts = 0
        while unique.count < count && attempts < 3 {
            let needed = count - unique.count
            let drafts = try await aiService.generateFlashcards(prompt: prompt, count: needed, model: model)

            let grounded = drafts.filter { isGrounded($0, contextTokens: contextTokens, contextLoose: contextLoose) }

            for draft in grounded {
                let key = makeKey(front: draft.front, back: draft.back)
                let frontKey = normalize(draft.front)
                if seenKeys.contains(key) || seenFronts.contains(frontKey) { continue }

                seenKeys.insert(key)
                seenFronts.insert(frontKey)
                unique.append(draft)
            }
            attempts += 1
        }

        return unique
    }

    private func isGrounded(
        _ draft: FlashcardDraft,
        contextTokens: Set<String>,
        contextLoose: String
    ) -> Bool {
        let frontTokens = tokens(draft.front)
        let backTokens = tokens(draft.back)
        let infoTokens = frontTokens.union(backTokens)

        // Fallback: if model didn't provide a quote, allow ONLY if most of the content words exist in the docs.
        guard let rawQuote = draft.sourceQuote?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawQuote.isEmpty else {
            // Strict fallback to keep "documents-only" promise.
            let overlap = infoTokens.intersection(contextTokens).count
            let required = max(2, Int(Double(max(infoTokens.count, 1)) * 0.4))
            return overlap >= required
        }

        // Avoid overly short "quotes" that don't really anchor anything.
        if rawQuote.count < 10 { return false }

        // Quote match: first try phrase match with a loose normalizer (tolerates punctuation/line breaks).
        let quoteLoose = normalizeLoose(rawQuote)
        if quoteLoose.count >= 8, contextLoose.contains(quoteLoose) {
            // ok
        } else {
            // Fuzzy token coverage fallback.
            let quoteTokens = tokens(rawQuote)
            guard quoteTokens.count >= 2 else { return false }

            let quoteOverlap = quoteTokens.intersection(contextTokens).count
            let minOverlap = max(2, Int(Double(quoteTokens.count) * 0.4))
            guard quoteOverlap >= minOverlap else { return false }
        }

        // The card content should overlap with document vocabulary.
        let infoOverlap = infoTokens.intersection(contextTokens).count
        let minInfo = max(1, Int(Double(infoTokens.count) * 0.25))
        guard infoOverlap >= minInfo else { return false }

        return true
    }

    private func tokens(_ text: String) -> Set<String> {
        let lowered = text.lowercased()
        let cleaned = lowered.replacingOccurrences(
            of: #"[^\p{L}\p{N}]+"#,
            with: " ",
            options: .regularExpression
        )
        let collapsed = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return Set(collapsed.split(separator: " ").map(String.init).filter { $0.count >= 2 })
    }

    private func normalizeLoose(_ text: String) -> String {
        let lowered = text.lowercased()
        let cleaned = lowered.replacingOccurrences(
            of: #"[^\p{L}\p{N}]+"#,
            with: " ",
            options: .regularExpression
        )
        return cleaned
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildPrompt(query: String, context: String, desiredCount: Int) -> String {
        var parts: [String] = []

        parts.append("""
        ЖЁСТКОЕ ПРАВИЛО: используй ТОЛЬКО факты из документов ниже. Запрещено использовать знания вне документов, домысливать или «добавлять контекст».
        Сгенерируй до \(desiredCount) новых уникальных карточек (без дублей с уже существующими). Если фактов мало — верни меньше карточек (вплоть до 0), но НЕ придумывай.
        """)

        parts.append("""
        Формат: JSON-массив объектов. Каждый объект: { "front": "...", "back": "...", "tags": ["..."], "sourceQuote": "..." }.
        Поле "sourceQuote" — это короткая ДОСЛОВНАЯ цитата из документов (должна встречаться в тексте документов).
        Поле "back" должно быть ответом, который полностью следует из sourceQuote (без добавления новых фактов).
        """)

        if !boardTitle.isEmpty { parts.append("Контекст доски: \(boardTitle)") }
        if !query.isEmpty { parts.append("Запрос пользователя: \(query)") }

        if !existingSamples.isEmpty {
            let sample = existingSamples.prefix(12).joined(separator: "; ")
            parts.append("Уже есть карточки (не повторяй): \(sample)")
        }

        parts.append("""
        ДОКУМЕНТЫ (используй только текст между маркерами):
        BEGIN_DOCUMENTS
        \(context)
        END_DOCUMENTS
        """)

        parts.append("Ответ без Markdown, только JSON.")
        return parts.joined(separator: "\n\n")
    }

    private func loadDocumentsText(from documents: [BoardDocument]) async -> String {
        await Task.detached(priority: .userInitiated) {
            await Self.loadDocumentsTextSync(from: documents)
        }.value
    }

    private static func loadDocumentsTextSync(from documents: [BoardDocument]) -> String {
        var blocks: [String] = []

        for doc in documents {
            let fileName = doc.fileName
            let text = readText(from: doc.url) ?? ""
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let snippet = trimmed.prefix(8000)
            let snippetString = String(snippet).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !snippetString.isEmpty else { continue }
            blocks.append("Файл: \(fileName)\n\(snippetString)")
        }

        return blocks.joined(separator: "\n\n---\n\n")
    }

    private static func readText(from url: URL) -> String? {
        let ext = url.pathExtension.lowercased()
        if ext == "pdf" {
            if let doc = PDFDocument(url: url) {
                if let text = doc.string?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !text.isEmpty {
                    return text
                }
                // Scanned PDFs often have no text layer — try OCR as a fallback.
                let ocr = ocrText(from: doc)
                let trimmed = ocr.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
            return nil
        }

        if ext == "rtf" {
            if let data = try? Data(contentsOf: url) {
                let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                    .documentType: NSAttributedString.DocumentType.rtf
                ]
                if let attr = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
                    return attr.string
                }
            }
        }

        // .docx is not supported by NSAttributedString on iOS without additional parsing.

        if ext == "html" || ext == "htm" {
            if let data = try? Data(contentsOf: url) {
                let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ]
                if let attr = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
                    return attr.string
                }
            }
        }

        if ["png", "jpg", "jpeg", "heic", "heif"].contains(ext) {
            if let image = UIImage(contentsOfFile: url.path) {
                return recognizeText(image: image)
            }
            return nil
        }

        if let data = try? Data(contentsOf: url) {
            if let utf8 = String(data: data, encoding: .utf8) {
                return utf8
            }
            if let cp1251 = String(data: data, encoding: .windowsCP1251) {
                return cp1251
            }
            if let latin1 = String(data: data, encoding: .isoLatin1) {
                return latin1
            }
            return String(data: data, encoding: .ascii)
        }

        return nil
    }

    private static func recognizeText(image: UIImage) -> String {
        guard let cgImage = image.cgImage else { return "" }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["ru-RU", "en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])

        let observations = request.results as? [VNRecognizedTextObservation] ?? []
        let strings = observations.compactMap { $0.topCandidates(1).first?.string }
        return strings.joined(separator: " ")
    }

    private static func ocrText(from doc: PDFDocument) -> String {
        let pageCount = doc.pageCount
        guard pageCount > 0 else { return "" }

        // Keep it fast: OCR only the first few pages.
        let maxPages = min(pageCount, 4)
        var blocks: [String] = []

        for i in 0..<maxPages {
            guard let page = doc.page(at: i) else { continue }
            let thumb = page.thumbnail(of: CGSize(width: 1200, height: 1600), for: .mediaBox)
            let text = recognizeText(image: thumb).trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                blocks.append(text)
            }
        }

        return blocks.joined(separator: "\n")
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
