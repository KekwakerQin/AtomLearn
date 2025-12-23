import UIKit

/// Координатор домашнего экрана.
final class HomeCoordinator {
    // MARK: - Dependencies
    private let navigationController: UINavigationController

    // MARK: - Init
    /// Создаёт координатор домашнего экрана.
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Public API
    /// Запускает домашний экран.
    func start() {
        let viewController = HomeViewController()
        navigationController.pushViewController(viewController, animated: true)
    }
}
