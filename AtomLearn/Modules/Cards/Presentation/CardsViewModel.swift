import Foundation

/// ViewModel для экрана карточек.
final class CardsViewModel {
    // MARK: - Dependencies

    // MARK: - Output (Navigation)
    var onAddCard: (() -> Void)?

    // MARK: - Init
    /// Создаёт ViewModel карточек.
    init() {

    }

    deinit { print("CardsViewModel deinit:", ObjectIdentifier(self)) }
    
    // MARK: - Lifecycle
    /// Обрабатывает событие загрузки экрана.
    func onViewDidLoad() {
        
    }
    
    // MARK: - Actions
    func didTapAddCard() {
        print("VM onAddCard =", onAddCard == nil ? "nil" : "set")
        onAddCard?()
    }
}
