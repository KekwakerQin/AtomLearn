import Foundation

/// Протокол работы с данными бейджей.
protocol BadgesService {
    /// Загружает все бейджи.
    func fetchBadges() async throws -> [Badge]
}
