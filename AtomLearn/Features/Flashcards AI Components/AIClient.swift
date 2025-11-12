import Foundation

enum APIError: Error, LocalizedError {
    case emptyResponse
    case badStatus(Int, String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .emptyResponse: return "Пустой ответ от сервера"
        case .badStatus(let code, let body): return "HTTP \(code): \(body)"
        case .decoding(let e): return "Ошибка декодирования: \(e)"
        }
    }
}

func fetch<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
    let (data, resp) = try await URLSession.shared.data(for: request)
    let http = resp as? HTTPURLResponse
    let code = http?.statusCode ?? -1

    // если не 2xx — покажем тело как текст (полезно для ошибок API)
    if !(200...299).contains(code) {
        let body = String(data: data, encoding: .utf8) ?? "<no body>"
        throw APIError.badStatus(code, body)
    }

    // здесь твой крэш: сервер вернул 0 байт
    guard !data.isEmpty else {
        throw APIError.emptyResponse
    }

    do {
        return try JSONDecoder().decode(T.self, from: data)
    } catch {
        // Для дебага удобно увидеть «как выглядит» тело ответа
        let body = String(data: data, encoding: .utf8) ?? "<binary/invalid utf8>"
        print("DECODE FAIL. Raw body:\n\(body)")
        throw APIError.decoding(error)
    }
}
