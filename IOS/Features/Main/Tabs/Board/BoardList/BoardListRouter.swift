import UIKit
// add comment
protocol BoardListRouterProtocol: AnyObject {
    func openBoardDetail(from view: BoardListViewProtocol?, board: Board)
}

final class BoardListRouter: BoardListRouterProtocol {
    func openBoardDetail(from view: (any BoardListViewProtocol)?, board: Board) {
        guard
        let vc = view as? UIViewController
        else {
            print("не кастуется к UIViewController")
            return }
        
        let detailVC = BoardDetailRouter.createModule(board: board)
        vc.navigationController?.pushViewController(detailVC, animated: true)
    }
    
    static func createModule(for userID: String) -> UIViewController {
        let service = BoardService()
        let interactor = BoardListInteractor(service: service, userID: userID)
        let router = BoardListRouter()
        let presenter = BoardListPresenter(interactor: interactor, router: router, userID: userID)
        let view = BoardListViewController(presenter: presenter)

        presenter.view = view
        interactor.presenter = presenter
        
        view.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "heart.text.clipboard.fill"),
            selectedImage: UIImage(systemName: "heart.text.clipboard.fill")
        )
   
        
        return view
    }
}


