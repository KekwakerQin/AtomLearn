import Foundation
import FirebaseFirestore

/// Репозиторий для работы с досками в Firestore.
final class BoardsRepository: BoardsService {
    // MARK: - Dependencies
    private let db = Firestore.firestore()
    
    // MARK: - Public API
    /// Подписывается на изменения списка досок.

    @discardableResult
    func observeBoards(
        ownerUID: String,
        order: BoardsOrder,
        onUpdate: @escaping (Result<[Board], Error>) -> Void
    ) -> ListenerRegistration {

        let ownerQuery = db.collection("boards")
            .whereField("ownerUID", isEqualTo: ownerUID)
            .order(by: "lastActivityAt", descending: order.descending)

        let memberQuery = db.collection("boards")
            .whereField("memberUIDs", arrayContains: ownerUID)
            .order(by: "lastActivityAt", descending: order.descending)

        var cache: [String: Board] = [:]

        func applyChanges(from snapshot: QuerySnapshot?) {
            guard let snapshot else { return }

            for change in snapshot.documentChanges {
                switch change.type {
                case .added, .modified:
                    if let board = BoardMapper.from(doc: change.document) {
                        cache[board.id] = board
                    }

                case .removed:
                    cache[change.document.documentID] = nil

                @unknown default:
                    break
                }
            }
        }

        func emit() {
            let boards = Array(cache.values)
                .sorted {
                    ($0.lastActivityAt ?? .distantPast) >
                    ($1.lastActivityAt ?? .distantPast)
                }

            onUpdate(.success(boards))
        }
        
        let ownerListener = ownerQuery.addSnapshotListener { snapshot, error in
            if let error {
                onUpdate(.failure(error))
                return
            }

            applyChanges(from: snapshot)
            emit()
        }

        let memberListener = memberQuery.addSnapshotListener { snapshot, error in
            if let error {
                onUpdate(.failure(error))
                return
            }

            applyChanges(from: snapshot)
            emit()
        }
        
        return CompositeListener(listeners: [ownerListener, memberListener])
    }
    
    /// Загружает список досок один раз.
    func fetchBoardsOnce(ownerUID: String, order: BoardsOrder) async throws -> [Board] {
        let base = db.collection("boards")

        async let ownedSnap = base
            .whereField("ownerUID", isEqualTo: ownerUID)
            .getDocuments()

        async let editableSnap = base
            .whereField("editorUIDs", arrayContains: ownerUID)
            .getDocuments()

        let (owned, editable) = try await (ownedSnap, editableSnap)

        let ownedBoards = owned.documents.compactMap(BoardMapper.from)
        let editableBoards = editable.documents.compactMap(BoardMapper.from)

        // merge + dedupe by board.id
        var map: [String: Board] = [:]
        for b in ownedBoards { map[b.id] = b }
        for b in editableBoards { map[b.id] = b }

        var result = Array(map.values)

        // Keep ordering consistent with observeBoards() (currently based on lastActivityAt)
        result.sort {
            let lhs = $0.lastActivityAt ?? .distantPast
            let rhs = $1.lastActivityAt ?? .distantPast
            return order.descending ? (lhs > rhs) : (lhs < rhs)
        }

        return result
    }
    
    func deleteBoard(boardId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Firestore.firestore()
            .collection("boards")
            .document(boardId)
            .delete { error in
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    private func fetchBoardIDsWhereUserIsCollaborator(
        ownerUID: String
    ) async throws -> [String] {

        let snapshot = try await db
            .collectionGroup("collaborators")
            .whereField("uid", isEqualTo: ownerUID)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            // путь: boards/{boardId}/collaborators/{docId}
            doc.reference.parent.parent?.documentID
        }
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

// Старое но рабочее

/*
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

 */

final class CompositeListener: NSObject, ListenerRegistration {
    private let listeners: [ListenerRegistration]

    init(listeners: [ListenerRegistration]) {
        self.listeners = listeners
    }

    func remove() {
        listeners.forEach { $0.remove() }
    }
}
