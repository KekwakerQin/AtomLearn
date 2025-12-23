import UIKit

/// Координатор экрана поиска.
final class SearchCoordinator {
    // MARK: - Dependencies
    private let navigationController: UINavigationController

    // MARK: - Init
    /// Создаёт координатор поиска.
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Public API
    /// Запускает экран поиска.
    func start() {
        let viewController = SearchViewController()
        navigationController.pushViewController(viewController, animated: true)
    }
}
