import Foundation
import Supabase

/// Репозиторий домашнего экрана.
final class HomeRepository: HomeService {
    // MARK: - Dependencies
    private let client: SupabaseClient
    private let bucket: String
    private let badgesPath: String

    // MARK: - Init
    /// Создаёт репозиторий домашнего экрана.
    init(
        client: SupabaseClient = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        ),
        bucket: String = SupabaseConfig.bucket,
        badgesPath: String = "badges/badge_icons"
    ) {
        self.client = client
        self.bucket = bucket
        self.badgesPath = badgesPath
    }

    // MARK: - HomeService
    func fetchBadgeList() async throws -> [HomeBadgeFile] {
        let storage = client.storage.from(bucket)
        let files = try await storage.list(path: badgesPath, options: .init(limit: 1000))
        let sorted = files.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        var results: [HomeBadgeFile] = []
        results.reserveCapacity(sorted.count)

        for file in sorted {
            let fullPath = "\(badgesPath)/\(file.name)"
            let url = (try? storage.getPublicURL(path: fullPath))
            ?? try await storage.createSignedURL(path: fullPath, expiresIn: 600)
            results.append(HomeBadgeFile(name: file.name, url: url))
        }

        return results
    }

    func loadImage(url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
