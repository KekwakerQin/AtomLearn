import Foundation

/// ViewModel для домашнего экрана.
final class HomeViewModel {
    // MARK: - Dependencies
    private let service: HomeService

    // MARK: - Init
    /// Создаёт ViewModel домашнего экрана.
    init(service: HomeService) {
        self.service = service
    }

    // MARK: - Lifecycle
    /// Обрабатывает событие загрузки экрана.
    func onViewDidLoad() {
        _ = service
    }
}
