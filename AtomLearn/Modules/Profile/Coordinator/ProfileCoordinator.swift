import UIKit

/// Координатор экрана профиля.
final class ProfileCoordinator {
    // MARK: - Dependencies
    private let navigationController: UINavigationController

    // MARK: - Init
    /// Создаёт координатор профиля.
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Public API
    /// Запускает экран профиля.
    func start(user: AppUser) {
        let viewController = ProfileViewController(user: user)
        navigationController.pushViewController(viewController, animated: true)
    }
}
