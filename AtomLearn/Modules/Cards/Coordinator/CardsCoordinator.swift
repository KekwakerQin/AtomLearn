import UIKit

/// Координатор экрана карточек.
final class CardsCoordinator {
    // MARK: - Dependencies
    private let navigationController: UINavigationController

    // MARK: - Init
    /// Создаёт координатор карточек.
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Public API
    /// Запускает экран карточек.
    func start(user: AppUser, board: Board) {
        let viewController = CardsViewController(user: user, board: board)
        navigationController.pushViewController(viewController, animated: true)
    }
}
