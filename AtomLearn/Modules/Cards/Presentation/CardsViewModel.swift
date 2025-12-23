import Foundation

/// ViewModel для экрана карточек.
final class CardsViewModel {
    // MARK: - Dependencies
    private let service: CardsService

    // MARK: - Init
    /// Создаёт ViewModel карточек.
    init(service: CardsService) {
        self.service = service
    }

    // MARK: - Lifecycle
    /// Обрабатывает событие загрузки экрана.
    func onViewDidLoad() {
        _ = service
    }
}
