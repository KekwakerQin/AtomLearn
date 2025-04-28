import UIKit
import RxSwift
import RealmSwift
import FirebaseFirestore

protocol BoardDetailInteractorInputProtocol {
    func viewWillAppear()
    func viewWillDisappear()
    func subscribeToCards()
    func addCard()
    func deleteCards()
}

protocol BoardDetailInteractorOutputProtocol: AnyObject {
    func didFetchCards(_ cards: [Card])
    func didFailFetchingCards(_ error: Error)
}

final class BoardDetailInteractor: BoardDetailInteractorInputProtocol {
    weak var presenter: BoardDetailInteractorOutputProtocol?
    private let service: BoardDetailServiceProtocol
    private let boardID: String
    private let cacheManager = CardCacheManager()
    private let disposeBag = DisposeBag()
    private let cacheCleaner = CacheCleaner()
    var cardListener: ListenerRegistration?

    init(service: BoardDetailServiceProtocol, boardID: String) {
        self.service = service
        self.boardID = boardID
    }
    
    func subscribeToCards() {
        cardListener?.remove()
        cardListener = service.listenerCards(for: boardID) { [weak self] result in
            switch result {
            case .success(let cards):
                self?.cacheManager.cacheCards(cards)
                self?.presenter?.didFetchCards(cards)
            case .failure(let error):
                self?.presenter?.didFailFetchingCards(error)
            }
        }
    }
    
    func addCard() {
        service.createCard(for: boardID)
            .subscribe(onSuccess: { [weak self] in
                // Успешно создано — ничего не делаем, т.к. listener сам обновит UI
            }, onFailure: { [weak self] error in
                self?.presenter?.didFailFetchingCards(error)
            })
            .disposed(by: disposeBag)
    }
    
    func deleteCards() {
        service.deleteCards(for: boardID)
            .subscribe(onCompleted: { [weak self] in
                self?.cacheCleaner.removeCacheFromCards()
            }, onError: { [weak self] error in
                self?.presenter?.didFailFetchingCards(error)
            })
            .disposed(by: disposeBag)
    }
    
    func viewWillAppear() {
        CardPreloadManager.shared.focus(on: boardID)
        CardPreloadManager.shared.subscribeToBoard(boardID)
        subscribeToCards()
    }

    func viewWillDisappear() {
        CardPreloadManager.shared.defocus()
        cardListener?.remove()
        cardListener = nil
    }
   
}
