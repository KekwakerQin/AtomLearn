import UIKit

final class ProfileInfoCoordinator {

    // MARK: - Dependencies
    private let navigationController: UINavigationController
    private let user: AppUser
    private let authService: AuthService

    // MARK: - Output
    var onSignedOut: (() -> Void)?

    // MARK: - Init
    init(
        navigationController: UINavigationController,
        user: AppUser,
        authService: AuthService
    ) {
        self.navigationController = navigationController
        self.user = user
        self.authService = authService
    }

    // MARK: - Public API
    func start() {
        let viewModel = ProfileInfoViewModel(authService: authService)
        let vc = ProfileInfoViewController(user: user, viewModel: viewModel)

        viewModel.onSignedOut = { [weak self] in
            self?.onSignedOut?()
        }

        navigationController.pushViewController(vc, animated: true)
    }
}
