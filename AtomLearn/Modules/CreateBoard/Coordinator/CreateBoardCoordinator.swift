import UIKit

final class CreateBoardCoordinator {

    // MARK: - Dependencies
    private let navigationController: UINavigationController
    private let user: AppUser

    // MARK: - Output
    var onFinish: (() -> Void)?
    var onCancel: (() -> Void)?

    // MARK: - Init
    init(
        navigationController: UINavigationController,
        user: AppUser
    ) {
        self.navigationController = navigationController
        self.user = user
    }

    // MARK: - Public API
    func start() {
        let service = CreateBoardService()
        let useCase = CreateBoardUseCase(service: service)

        let viewModel = CreateBoardViewModel(
            user: user,
            useCase: useCase
        )

        viewModel.onFinish = { [weak self] in
            self?.onFinish?()
        }
        
        viewModel.onCancel = { [weak self] in
            self?.onCancel?()
        }

        let vc = CreateBoardViewController(viewModel: viewModel)
        navigationController.pushViewController(vc, animated: true)
    }
}
