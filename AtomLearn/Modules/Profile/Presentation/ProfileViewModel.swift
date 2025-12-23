import Foundation

/// ViewModel для экрана профиля.
final class ProfileViewModel {
    // MARK: - Dependencies
    private let service: ProfileService

    // MARK: - Init
    /// Создаёт ViewModel профиля.
    init(service: ProfileService) {
        self.service = service
    }

    // MARK: - Lifecycle
    /// Обрабатывает событие загрузки экрана.
    func onViewDidLoad() {
        _ = service
    }
}
