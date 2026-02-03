import UIKit

final class ManuallyCreateCardsCoordinator {

    // MARK: - Dependencies
    private let navigationController: UINavigationController
    private let boardId: String
    private let ownerId: String

    // MARK: - Init
    init(navigationController: UINavigationController, boardId: String, ownerId: String) {
        self.navigationController = navigationController
        self.boardId = boardId
        self.ownerId = ownerId
    }

    // MARK: - Public API
    /// Starts manually create cards flow.
    func start() {
        let vc = makeScreen()
        navigationController.pushViewController(vc, animated: true)
    }

    // MARK: - Private helpers
    private func makeScreen() -> UIViewController {
        let repository = ManuallyCreateCardsRepository()
        let service = ManuallyCreateCardsService(repository: repository)
        let viewModel = ManuallyCreateCardsViewModel(
            boardId: boardId,
            ownerId: ownerId,
            service: service
        )

        let viewController = ManuallyCreateCardsViewController(viewModel: viewModel)

        viewModel.onRoute = { [weak self] route in
            self?.handle(route)
        }

        return viewController
    }

    private func handle(_ route: ManuallyCreateCardsViewModel.Route) {
        switch route {
        case .close:
            navigationController.popViewController(animated: true)
        case .saved:
            navigationController.popViewController(animated: true)
        }
    }
}
