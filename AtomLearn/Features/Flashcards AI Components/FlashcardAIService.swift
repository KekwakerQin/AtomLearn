import Foundation
import FirebaseFirestore

protocol FlashcardAIServiceProtocol {
    func generateCards(sourceText: String,
                       boardId: String,
                       ownerId: String,
                       countHint: Int) async throws -> [Card]
    func saveToFirestore(_ cards: [Card]) async throws
}

final class FlashcardAIService: FlashcardAIServiceProtocol {

    private let apiKey: String
    private let model: String
    private let db = Firestore.firestore()

    init(apiKey: String, model: String = "nvidia/nemotron-nano-9b-v2:free") {
        self.apiKey = apiKey
        self.model = model
    }

    func generateCards(sourceText: String,
                       boardId: String,
                       ownerId: String,
                       countHint: Int) async throws -> [Card] {

        // 1) Вызов LLM
        let raw = try await callLLM(sourceText: sourceText, countHint: countHint)

        // 2) Парсинг JSON > drafts
        let drafts = try FlashcardParsing.parseDrafts(from: raw)

        // 3) Маппинг draft > Card (твоя модель)
        let cards = drafts.map { FlashcardMapping.toCard(boardId: boardId, ownerId: ownerId, draft: $0) }
        return cards
    }

    func saveToFirestore(_ cards: [Card]) async throws {
        guard let boardId = cards.first?.boardId else { return }
        let batch = db.batch()
        let col = db.collection("boards").document(boardId).collection("cards")

        for card in cards {
            let ref = col.document() // позволь серверу создать id
            let data = FlashcardMapping.toFirestoreData(card)
            batch.setData(data, forDocument: ref)
        }
        try await batch.commit()
    }

    // MARK: - Low-level HTTP → OpenRouter
    private func callLLM(sourceText: String, countHint: Int) async throws -> String {
        struct ChatMessage: Codable { let role: String; let content: String }
        struct ChatRequest: Codable {
            let model: String
            let messages: [ChatMessage]
            let max_tokens: Int
            let temperature: Double
        }
        struct Choice: Codable { let message: ChatMessage }
        struct ChatResponse: Codable { let choices: [Choice] }

        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let system = """
        Ты генератор карточек. Отвечай ТОЛЬКО JSON.
        Формат:
        [
          {"front":"...", "back":"...", "tags":["...","..."]},
          ...
        ]
        Никакого текста до/после. Теги — короткие, без #.
        """

        let user = """
        Создай \(countHint) карточек по тексту ниже.
        Текст:
        \(sourceText)
        """

        let body = ChatRequest(
            model: model,
            messages: [.init(role: "system", content: system),
                       .init(role: "user", content: user)],
            max_tokens: 1500,
            temperature: 0.7
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            throw NSError(domain: "OpenRouterHTTPError",
                          code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode). Body: \(bodyString)"])
        }

        do {
            let chat = try JSONDecoder().decode(ChatResponse.self, from: data)
            if let content = chat.choices.first?.message.content {
                return content
            } else {
                let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                throw NSError(domain: "OpenRouterDecodeError",
                              code: -2,
                              userInfo: [NSLocalizedDescriptionKey: "Empty choices in response. Body: \(bodyString)"])
            }
        } catch {
            let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            throw NSError(domain: "OpenRouterDecodeError",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to decode ChatResponse. Error: \(error). Body: \(bodyString)"])
        }
    }
}
