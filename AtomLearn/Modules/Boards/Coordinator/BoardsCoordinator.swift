import UIKit

/// Координатор экрана досок.
final class BoardsCoordinator {
    // MARK: - Dependencies
    private let navigationController: UINavigationController

    // MARK: - Init
    /// Создаёт координатор досок.
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Public API
    /// Запускает экран досок.
    func start(user: AppUser) {
        let viewController = BoardsViewController(user: user, service: BoardsRepository())
        navigationController.pushViewController(viewController, animated: true)
    }
}
