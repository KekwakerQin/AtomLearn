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
            .order(by: "createdAtClient", descending: order.descending)

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

            let boards = documents.compactMap { Board(id: $0.documentID, data: $0.data()) }
            print("[BoardsService] synced boards: \(boards.count)")
            onUpdate(.success(boards))
        }

        return listener
    }

    /// Загружает список досок один раз.
    func fetchBoardsOnce(ownerUID: String, order: BoardsOrder) async throws -> [Board] {
        let query = db.collection("boards")
            .whereField("ownerUID", isEqualTo: ownerUID)
            .order(by: "createdAtClient", descending: order.descending)

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { Board(id: $0.documentID, data: $0.data()) }
    }

    /// Создаёт новую доску.
    func createBoard(ownerUID: String, title: String, description: String) async throws {
        let now = Timestamp(date: Date())

        let data: [String: Any] = [
            "title": title,
            "description": description,
            "ownerUID": ownerUID,
            "createdAt": FieldValue.serverTimestamp(),
            "createdAtClient": now
        ]

        try await db.collection("boards").addDocument(data: data)
        print("[BoardsService] Board created for \(ownerUID)")
    }
}
