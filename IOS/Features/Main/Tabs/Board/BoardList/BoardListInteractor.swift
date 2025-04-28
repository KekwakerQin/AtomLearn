import UIKit
import RxSwift
import FirebaseFirestore

protocol BoardListInteractorInputProtocol {
    func fetchBoards()
    func createBoard()
    func deleteBoards()
    func stopListening()
}

protocol BoardListInteractorOutputProtocol: AnyObject {
    func didFetchBoard(_ boards: [Board])
    func didFailFetchingBoard(_ error: Error)
    func didCreateBoard(_ board: Board)
    func didFailCreatingBoard(_ error: Error)
}

final class BoardListInteractor: BoardListInteractorInputProtocol {
    weak var presenter: BoardListInteractorOutputProtocol?
    private let service: BoardServiceProtocol
    private let userID: String
    private let disposeBag = DisposeBag()
    private let cacheCleaner = CacheCleaner()
    private var boardListener: ListenerRegistration?
    
    init(service: BoardServiceProtocol, userID: String) {
        self.service = service
        self.userID = userID
    }
    
    func fetchBoards() {
        boardListener?.remove()
        
        boardListener = service.listenBoards(for: userID) { [weak self] result in
            switch result {
            case .success(let boards):
                self?.presenter?.didFetchBoard(boards)
            case .failure(let error):
                self?.presenter?.didFailFetchingBoard(error)
            }
        }
    }
    
    func stopListening() {
        boardListener?.remove()
        boardListener = nil
    }
  
    // СТАРАЯ РЕАЛИЗАЦИЯ
//    func fetchBoards() {
//        service.fetchBoards(for: (SessionManager.shared.currentUser?.id)!)
//            .subscribe(onSuccess: { [weak self] boards in
//                self?.presenter?.didFetchBoard(boards)
//            }, onFailure: { [weak self] error in
//                self?.presenter?.didFailFetchingBoard(error)
//            })
//            .disposed(by: disposeBag)
//    }
    
    func createBoard() {
        print("We are in create board")
        service.createBoard(for: userID)
            .subscribe(onSuccess: { [weak self] board in
                self?.presenter?.didCreateBoard(board)
            }, onFailure: { [weak self] error in
                self?.presenter?.didFailCreatingBoard(error)
            })
            .disposed(by: disposeBag)
    }
    
    func deleteBoards() {
        service.deleteBoards(for: userID)
            .subscribe(onSuccess: { [weak self] in
                print("Все доски удалены")
                self?.fetchBoards()
                CardPreloadManager.shared.resetQueue()
                self?.cacheCleaner.removeAllCache()

            }, onFailure: { [weak self] error in
                self?.presenter?.didFailCreatingBoard(error)
            })
            .disposed(by: disposeBag)
    }
}
