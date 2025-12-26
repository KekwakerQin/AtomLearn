import Foundation
import FirebaseFirestore

/// Репозиторий для работы с досками в Firestore.
final class BoardsRepository: BoardsService {
    // MARK: - Dependencies
    private let db = Firestore.firestore()
    
    // MARK: - Public API
    /// Подписывается на изменения списка досок.
    @discardableResult
    func observeBoards(ownerUID: String,
                       order: BoardsOrder,
                       onUpdate: @escaping (Result<[Board], Error>) -> Void) -> ListenerRegistration {
        let query = db.collection("boards")
            .whereField("ownerUID", isEqualTo: ownerUID)
            .order(by: "lastActivityAt", descending: order.descending)
        
        print(query)
        
        let listener = query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("[BoardsService] Listener error:", error)
                onUpdate(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                onUpdate(.success([]))
                return
            }
            
            let boards = documents.compactMap(BoardMapper.from)
            print("[BoardsService] synced boards: \(boards.count)")
            print("RAW documents count:", documents.count)
            onUpdate(.success(boards))
        }
        
        return listener
    }
    
    /// Загружает список досок один раз.
    func fetchBoardsOnce(ownerUID: String, order: BoardsOrder) async throws -> [Board] {
        let query = db.collection("boards")
            .whereField("ownerUID", isEqualTo: ownerUID)
            .order(by: "lastActivityAt", descending: order.descending)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap(BoardMapper.from)
    }
    
    /// Создаёт новую доску.
    func createBoard(
        ownerUID: String,
        input: CreateBoardInput
    ) async throws {
        let data = input.toFirestore(ownerUID: ownerUID)
        try await db.collection("boards").addDocument(data: data)
    }
}
