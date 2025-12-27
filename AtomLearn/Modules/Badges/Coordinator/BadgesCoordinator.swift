import UIKit

/// Координатор флоу бейджей.
final class BadgesCoordinator {
    // MARK: - Dependencies
    private let navigationController: UINavigationController

    // MARK: - Init
    /// Создаёт координатор бейджей.
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Public API
    /// Запускает экран бейджей.
    func start() {
        let viewController = BadgesViewController()
        navigationController.pushViewController(viewController, animated: true)
    }
}
