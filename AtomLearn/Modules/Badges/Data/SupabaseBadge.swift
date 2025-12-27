import Supabase
import Foundation

// Класс для работы с изображениями из Supabase
final class SupabaseImages {
    // Базовый URL проекта
    private let baseURL: URL
    // Клиент Supabase
    private let client: SupabaseClient
    // Имя бакета (хранилища)
    private let bucket: String

    // Инициализация с зависимостями
    init(client: SupabaseClient, bucket: String, baseURL: URL) {
        self.client = client
        self.bucket = bucket
        self.baseURL = baseURL
    }

    // Формирование URL для миниатюры (через CDN)
    func thumbnailURL(for path: String,
                      width: Int = 88,
                      quality: Int = 70,
                      format: String = "webp") throws -> URL {
        let base = baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let escapedBucket = bucket.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? bucket
        let escapedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path

        let urlString = "\(base)/storage/v1/render/image/public/\(escapedBucket)/\(escapedPath)?width=\(width)&quality=\(quality)&format=\(format)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        return url
    }

    // Получение оригинального URL (public или signed)
    func originalURL(for path: String) async throws -> URL {
        if let publicURL = try? client.storage.from(bucket).getPublicURL(path: path) {
            return publicURL
        }
        return try await client.storage.from(bucket).createSignedURL(path: path, expiresIn: 600)
    }

    // Универсальный метод: возвращает лучшее доступное изображение
    // Если бакет публичный — вернёт CDN-миниатюру, иначе — signed оригинал.
    func bestURL(for path: String, width: Int = 88, quality: Int = 70) async throws -> URL {
        if (try? client.storage.from(bucket).getPublicURL(path: path)) != nil {
            return try thumbnailURL(for: path, width: width, quality: quality, format: "webp")
        } else {
            return try await originalURL(for: path)
        }
    }
}
