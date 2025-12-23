import Foundation

/// ViewModel для экрана поиска.
final class SearchViewModel {
    // MARK: - Dependencies
    private let service: SearchService

    // MARK: - Init
    /// Создаёт ViewModel поиска.
    init(service: SearchService) {
        self.service = service
    }

    // MARK: - Lifecycle
    /// Обрабатывает событие загрузки экрана.
    func onViewDidLoad() {
        _ = service
    }
}
