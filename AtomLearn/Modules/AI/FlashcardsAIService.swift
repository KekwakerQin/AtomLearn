import Foundation

protocol FlashcardsAIServiceProtocol {
    func generateFlashcards(prompt: String, count: Int, model: String) async throws -> [FlashcardDraft]
}

final class FlashcardsAIService: FlashcardsAIServiceProtocol {
    struct Message: Codable {
        let role: String
        let content: String
    }

    struct RequestBody: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double
    }

    struct ResponseBody: Codable {
        struct Choice: Codable {
            struct Message: Codable { let content: String }
            let message: Message
        }
        let choices: [Choice]
    }

    func generateFlashcards(prompt: String, count: Int, model: String) async throws -> [FlashcardDraft] {
        let system = "Ты помощник, который генерирует карточки для обучения. Возвращай ТОЛЬКО JSON-массив без markdown и комментариев."
        let user = """
        Сгенерируй до \(count) карточек по запросу ниже.
        Формат ответа: JSON-массив объектов, каждый объект должен содержать поля \"front\", \"back\", \"tags\". Дополнительные поля допускаются.
        Запрос: \(prompt)
        """

        let body = RequestBody(
            model: model,
            messages: [
                Message(role: "system", content: system),
                Message(role: "user", content: user)
            ],
            temperature: 0.2
        )

        let apiKey = OpenRouterConfig.apiKey
        if apiKey.isEmpty {
            throw APIError.badStatus(401, "OPENROUTER_API_KEY не указан")
        }

        var request = URLRequest(url: OpenRouterConfig.baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        request.setValue(OpenRouterConfig.appTitle, forHTTPHeaderField: "X-Title")
        if let site = OpenRouterConfig.siteURL {
            request.setValue(site, forHTTPHeaderField: "HTTP-Referer")
        }

        request.httpBody = try JSONEncoder().encode(body)

        let response: ResponseBody = try await fetch(request, as: ResponseBody.self)
        guard let content = response.choices.first?.message.content else {
            throw APIError.emptyResponse
        }

        return try FlashcardParsing.parseDrafts(from: content)
    }
}
