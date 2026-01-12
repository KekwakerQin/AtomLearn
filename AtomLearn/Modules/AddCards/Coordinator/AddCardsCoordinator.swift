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
            board: board,
            user: user
        )

        viewModel.onCancel = { [weak self] in
            self?.onCancel?()
        }

        let vc = AddCardsViewController(viewModel: viewModel)
        navigationController.pushViewController(vc, animated: true)
    }
}
