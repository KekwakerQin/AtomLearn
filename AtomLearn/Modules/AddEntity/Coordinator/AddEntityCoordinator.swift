import UIKit

final class AddEntityCoordinator {
    
    // MARK: - Dependencies
    private let navigationController: UINavigationController
    private let user: AppUser
    private let boardsService: BoardsService
    private var childCoordinators: [AnyObject] = []
    
    // MARK: - Init
    init(navigationController: UINavigationController,
         user: AppUser,
         boardsService: BoardsService) {
        self.navigationController = navigationController
        self.user = user
        self.boardsService = boardsService
    }
    
    deinit {
        print("AddEntityCoordinator deinit")
    }
    
    // MARK: - Output
    var onFinish: (() -> Void)?
    var onCreateBoard: (() -> Void)?
    var onSelectBoard: ((Board) -> Void)?
    
    // MARK: - Public API
    func start() {
        let viewModel = AddEntityViewModel(
            user: user,
            boardsService: boardsService
        )

        viewModel.onCreateBoard = { [weak self] in
            self?.onCreateBoard?()
        }

        viewModel.onSelectBoard = { [weak self] board in
            guard let self else { return }
            self.navigationController.popViewController(animated: true)
            self.onSelectBoard?(board)
            self.onFinish?()
        }
        
        viewModel.onClose = { [weak self] in
            guard let self else { return }
            self.navigationController.popViewController(animated: true)
            self.onFinish?()
        }

        let vc = AddEntityViewController(viewModel: viewModel)
        vc.title = "Добавить"
        navigationController.pushViewController(vc, animated: true)
    }
    
    // MARK: - Finish
    private func finish() {
        onFinish?()
    }
}

// MARK: - Navigation
private extension AddEntityCoordinator {
    
}
