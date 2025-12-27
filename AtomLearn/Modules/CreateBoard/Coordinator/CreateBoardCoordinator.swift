import UIKit

final class CreateBoardCoordinator {

    // MARK: - Dependencies
    private let navigationController: UINavigationController
    private let user: AppUser

    // MARK: - Init
    init(navigationController: UINavigationController,
         user: AppUser) {
        self.navigationController = navigationController
        self.user = user
    }

    // MARK: - Public API
    func start() {
        let viewModel = CreateBoardViewModel(user: user)
        let vc = CreateBoardViewController(viewModel: viewModel)
        navigationController.pushViewController(vc, animated: true)
    }
}
