import UIKit

final class AddCardsCoordinator {
    
    // MARK: - Dependencies
    private let navigationController: UINavigationController
    private let board: Board
    
    // MARK: - Init
    init(navigationController: UINavigationController,
         board: Board) {
        self.navigationController = navigationController
        self.board = board
    }
    
    // MARK: - Output
    var onCancel: (() -> Void)?
    
    // MARK: - Public API
    func start() {
        let viewModel = AddCardsViewModel(board: board)
        viewModel.onCancel = { [weak self] in
            self?.onCancel?()
        }
        
        let vc = AddCardsViewController(viewModel: viewModel)
        navigationController.pushViewController(vc, animated: true)
    }
}
