import UIKit

final class CreateBoardCoordinator {
    
    // MARK: - Dependencies
    private let navigationController: UINavigationController
    private let user: AppUser
    
    // MARK: - Init
    init(navigationController: UINavigationController,
         user: AppUser) {
        self.navigationController = navigationController
        self.user = user
    }
    
    // MARK: - Output
    var onCancel: (() -> Void)?
    
    // MARK: - Public API
    func start() {
        let viewModel = CreateBoardViewModel(user: user)
        
        viewModel.onCancel = { [weak self] in
            self?.onCancel?()
        }
        
        let vc = CreateBoardViewController(viewModel: viewModel)
        navigationController.pushViewController(vc, animated: true)
    }
    
}
