import UIKit

final class CreateBoardCoordinator {

    // MARK: Dependencies
    private let navigationController: UINavigationController
    private let ownerUID: String

    // MARK: Output
    var onFinish: ((String) -> Void)?
    var onCancel: (() -> Void)?

    // MARK: Init
    init(
        navigationController: UINavigationController,
        ownerUID: String
    ) {
        self.navigationController = navigationController
        self.ownerUID = ownerUID
    }

    // MARK: Public API

    /// Открыть создание борда
    func start() {
        let service = CreateBoardService()
        let useCase = CreateBoardUseCase(service: service)
        let viewModel = CreateBoardViewModel(ownerUID: ownerUID, useCase: useCase)

        viewModel.onFinish = { [weak self] boardId in
            self?.onFinish?(boardId)
        }

        viewModel.onCancel = { [weak self] in
            self?.onCancel?()
        }

        let vc = CreateBoardViewController(viewModel: viewModel)
        navigationController.pushViewController(vc, animated: true)
    }
}
