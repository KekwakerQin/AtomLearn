import UIKit

final class AddCardsCoordinator {

    // MARK: - Dependencies
    private let navigationController: UINavigationController
    private let board: Board
    private let user: AppUser

    // MARK: - Init
    init(
        navigationController: UINavigationController,
        board: Board,
        user: AppUser
    ) {
        self.navigationController = navigationController
        self.board = board
        self.user = user
    }

    // MARK: - Output
    var onCancel: (() -> Void)?
    var onFinish: (() -> Void)?

    // MARK: - Public API
    func start() {
        let viewModel = AddCardsViewModel(
            boardId: board.id,
            user: user
        )

        viewModel.onFinish = { [weak self] in
            self?.onFinish?()
        }

        viewModel.onCancel = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }

        let vc = AddCardsViewController(viewModel: viewModel)
        navigationController.pushViewController(vc, animated: true)
    }
}
