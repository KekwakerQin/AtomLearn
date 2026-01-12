import UIKit

/// Координатор экрана карточек.
final class CardsCoordinator {
    
    private var childCoordinators: [AnyObject] = []
    
    private let navigationController: UINavigationController
    private let board: Board
    private let user: AppUser
    
    // MARK: - Output
    var onFinish: (() -> Void)?
    
    init(navigationController: UINavigationController, board: Board, user: AppUser) {
        self.navigationController = navigationController
        self.board = board
        self.user = user
    }
    
    func start() {
        let viewModel = CardsViewModel(service: CardsRepository())
        let viewController = CardsViewController(user: user, board: board, viewModel: viewModel)
        
        viewModel.onAddCard = { [weak self] in
            self?.startAddCardsFlow()
        }
        
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func startAddCardsFlow() {
        let nav = UINavigationController()
        print("OPEN ADD CARDS")
        
        let coordinator = AddCardsCoordinator(
            navigationController: nav,
            board: board,
            user: user
        )
        
        coordinator.onCancel = { [weak self, weak nav, weak coordinator] in
            nav?.dismiss(animated: true)
            if let coordinator {
                self?.childCoordinators.removeAll { $0 === coordinator }
            }
        }
        
        coordinator.onFinish = { [weak self, weak nav, weak coordinator] in
            nav?.dismiss(animated: true)
            if let coordinator {
                self?.childCoordinators.removeAll { $0 === coordinator }
            }
        }
        
        childCoordinators.append(coordinator)
        coordinator.start()
        navigationController.present(nav, animated: true)
    }
}
