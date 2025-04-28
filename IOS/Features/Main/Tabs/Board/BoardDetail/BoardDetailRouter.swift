import UIKit

protocol BoardDetailRouterProtocol: AnyObject {
    func navigateToCardDetail(from view: BoardDetailViewProtocol, card: Card)
}

final class BoardDetailRouter: BoardDetailRouterProtocol {

    static func createModule(board: Board) -> UIViewController {
        let service = BoardDetailService()
        let interactor = BoardDetailInteractor(service: service, boardID: board.boardID)
        let router = BoardDetailRouter()
        let presenter = BoardDetailPresenter(board: board, interactor: interactor, router: router)
        let view = BoardDetailViewController(presenter: presenter)

        presenter.view = view
        interactor.presenter = presenter

        return view
    }

    // Навигация к экрану одной карточки (можно реализовать позже)
    func navigateToCardDetail(from view: BoardDetailViewProtocol, card: Card) {
        guard let viewController = view as? UIViewController else { return }

        let cardDetailVC = UIViewController() // временно
        cardDetailVC.view.backgroundColor = .systemBackground
        cardDetailVC.title = card.term

        viewController.navigationController?.pushViewController(cardDetailVC, animated: true)
    }
}
