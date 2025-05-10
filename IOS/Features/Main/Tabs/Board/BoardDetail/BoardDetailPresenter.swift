import UIKit

protocol BoardDetailPresenterProtocol {
    func viewDidLoad()
    func didTapCreateButton()
    func didTapDeleteButton()
    func didSelectCard(_ card: Card)
    
    func viewWillAppear()
    func viewWillDisappear()
}

final class BoardDetailPresenter: BoardDetailPresenterProtocol {

    weak var view: BoardDetailViewProtocol?
    private let interactor: BoardDetailInteractor
    private let router: BoardDetailRouterProtocol
    private let board: Board
    
    init(board: Board, interactor: BoardDetailInteractor, router: BoardDetailRouterProtocol) {
        self.board = board
        self.interactor = interactor
        self.router = router
    }
    
    func viewDidLoad() {
        view?.displayBoardInfo(title: board.title, description: board.description)
    }
    
    func viewWillAppear() {
        interactor.viewWillAppear()
    }

    func viewWillDisappear() {
        CardPreloadManager.shared.defocus()
        interactor.viewWillDisappear()
    }
    
    func didSelectCard(_ card: Card) {
        guard let view = view else { return }
        router.navigateToCardDetail(from: view, card: card)
    }
    
    func didTapCreateButton() {
        interactor.addCard()
    }
    
    func didTapDeleteButton() {
        interactor.deleteCards()
    }
    
}

extension BoardDetailPresenter: BoardDetailInteractorOutputProtocol {
    func didFetchCards(_ cards: [Card]) {
        view?.showCards(cards)
    }
    
    func didFailFetchingCards(_ error: any Error) {
        view?.showError(error)
    }

}
