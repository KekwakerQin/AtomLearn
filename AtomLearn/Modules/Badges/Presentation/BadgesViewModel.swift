import Foundation

/// ViewModel для экрана бейджей.
final class BadgesViewModel {
    // MARK: - Dependencies
    private let service: BadgesService

    // MARK: - Public API
    /// Коллбэк для обновления списка бейджей.
    var onBadgesUpdated: (([Badge]) -> Void)?
    /// Коллбэк для ошибок загрузки.
    var onError: ((Error) -> Void)?

    // MARK: - Init
    /// Создаёт ViewModel с сервисом данных.
    init(service: BadgesService) {
        self.service = service
    }

    // MARK: - Lifecycle
    /// Обрабатывает событие загрузки экрана.
    func onViewDidLoad() {
        Task { await loadBadges() }
    }

    // MARK: - Private helpers
    private func loadBadges() async {
        do {
            let badges = try await service.fetchBadges()
            onBadgesUpdated?(badges)
        } catch {
            onError?(error)
        }
    }
}
