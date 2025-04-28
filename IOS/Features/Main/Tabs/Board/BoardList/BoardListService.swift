import UIKit
import RxSwift
import Foundation
import Firebase

protocol BoardServiceProtocol {
    func fetchBoards(for uid: String) -> Single<[Board]>
    func createBoard(for uid: String) -> Single<Board>
    func deleteBoards(for uid: String) -> Single<Void>
    func listenBoards(for uid: String, listener: @escaping (Result<[Board], Error>) -> Void) -> ListenerRegistration
}

final class BoardService: BoardServiceProtocol {
    func fetchBoards(for uid: String) -> Single<[Board]> {
        Single.create { single in
            FirestorePaths.boardsCollection()
                .whereField(FirestoreFields.Board.ownerUID, isEqualTo: uid)
                .getDocuments { snapshot, error in
                    if let error = error {
                        single(.failure(error))
                    } else if let documents = snapshot?.documents {
                        do {
                            let boards = try documents.map { try $0.data(as: Board.self) }
                            single(.success(boards))
                        } catch {
                            single(.failure(error))
                        }
                    } else {
                        single(.success([]))
                    }
                }
            return Disposables.create()
        }
    }
    
    func listenBoards(for uid: String, listener: @escaping (Result<[Board], Error>) -> Void) -> ListenerRegistration {
        return FirestorePaths.boardsCollection()
            .whereField(FirestoreFields.Board.ownerUID, isEqualTo: uid)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    listener(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    listener(.success([]))
                    return
                }
                
                do {
                    let boards = try documents.map { try $0.data(as: Board.self) }
                    listener(.success(boards))
                } catch {
                    listener(.failure(error))
                }
            }
    }
    
    // Заглушка
    func generateRandomBoardTitleWithNumber() -> String {
        let number = Int.random(in: 1...100)
        return "Board #\(number)"
    }
    
    func createBoard(for uid: String) -> Single<Board> {
        Single.create { single in
            let boardID = UUID().uuidString
            let board = Board(
                boardID: boardID,
                ownerUID: uid,
                profilePictures: [],
                title: self.generateRandomBoardTitleWithNumber(),
                description: "Desription",
                createdAt: Date()
            )
            
            do {
                try FirestorePaths.boardRef(boardID: boardID).setData(from: board) { error in
                    if let error = error {
                        single(.failure(error))
                    } else {
                        single(.success(board))
                    }
                }
            } catch {
                single(.failure(error))
            }
            
            return Disposables.create()
        }
    }
    
    func deleteBoards(for uid: String) -> Single<Void> {
        Single<Void>.create { single in
            let query = FirestorePaths.boardsCollection()
                .whereField(FirestoreFields.Board.ownerUID, isEqualTo: uid)
            
            query.getDocuments { snapshot, error in
                if let error = error {
                    single(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    single(.success(())) // нет досок — это не ошибка
                    return
                }
                
                let batch = Firestore.firestore().batch()
                
                for doc in documents {
                    batch.deleteDocument(doc.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        single(.failure(error))
                    } else {
                        single(.success(())) // успешно удалены
                    }
                }
            }
            
            return Disposables.create()
        }
    }
}
