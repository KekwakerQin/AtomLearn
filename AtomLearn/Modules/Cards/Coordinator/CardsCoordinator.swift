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
    
    deinit { print("CardsCoordinator deinit") }
    
    func start() {
        let viewModel = CardsViewModel()
        let viewController = CardsViewController(user: user, board: board, viewModel: viewModel)
        print("Coordinator VM:", ObjectIdentifier(viewModel))
        
        viewModel.onAddCard = { [weak self] in
            print("Closure fired, self is nil? ->", self == nil)
            self?.startAddCardsFlow()
        }
        
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func startAddCardsFlow() {
        print("PUSH ADD CARDS")
        
        let coordinator = AddCardsCoordinator(
            navigationController: navigationController,
            board: board,
            user: user
        )
        
        coordinator.onCancel = { [weak self, weak coordinator] in
            self?.navigationController.popViewController(animated: true)
            if let coordinator {
                self?.childCoordinators.removeAll { $0 === coordinator }
            }
        }
        
        coordinator.onFinish = { [weak self, weak coordinator] in
            self?.navigationController.popViewController(animated: true)
            if let coordinator {
                self?.childCoordinators.removeAll { $0 === coordinator }
            }
        }
        
        childCoordinators.append(coordinator)
        coordinator.start()
    }
}
