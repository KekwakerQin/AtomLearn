import UIKit

final class AddEntityCoordinator {

    // MARK: - Dependencies
    private weak var presenter: UIViewController?
    private let user: AppUser
    private let boardsService: BoardsService

    // MARK: - Init
    init(presenter: UIViewController,
         user: AppUser,
         boardsService: BoardsService) {
        self.presenter = presenter
        self.user = user
        self.boardsService = boardsService
    }

    // MARK: - Public API
    func start() {
        let viewModel = AddEntityViewModel(
            user: user,
            boardsService: boardsService
        )

        let vc = AddEntityViewController(viewModel: viewModel)
        vc.modalPresentationStyle = .pageSheet

        if let sheet = vc.presentationController as? UISheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }

        presenter?.present(vc, animated: true)
    }
}
