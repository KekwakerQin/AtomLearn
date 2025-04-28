import UIKit

protocol BoardListPresenterProtocol: AnyObject {
    func viewDidLoad()
    func viewWillDisappear()
    func didTapCreateButton()
    func didTapDeleteButton()
    func didSelectBoard(_ board: Board)
}

final class BoardListPresenter: BoardListPresenterProtocol, BoardListInteractorOutputProtocol {
    
    weak var view: BoardListViewProtocol?
    let interactor: BoardListInteractorInputProtocol
    let router: BoardListRouterProtocol
    let userID: String
    
    init(interactor: BoardListInteractorInputProtocol, router: BoardListRouterProtocol, userID: String) {
        self.interactor = interactor
        self.router = router
        self.userID = userID
    }
    
    func viewDidLoad() {
        interactor.fetchBoards()
    }
    
    func viewWillDisappear() {
        interactor.stopListening()
    }
    
    func didTapCreateButton() {
        print("Tapped Board List Presenter")
        interactor.createBoard()
    }
    
    func didTapDeleteButton() {
        print("Tapped Board List Presenter")
        interactor.deleteBoards()
    }
    
    func didSelectBoard(_ board: Board) {
        print("Router запускается")
        router.openBoardDetail(from: view, board: board)
    }
    
    func didFetchBoard(_ boards: [Board])      { view?.showBoards(boards) }
    func didFailFetchingBoard(_ error: Error)  { view?.showError(error)   }
    func didCreateBoard(_ board: Board)        { interactor.fetchBoards() }
    func didFailCreatingBoard(_ error: Error)  { view?.showError(error)   }
    
}
