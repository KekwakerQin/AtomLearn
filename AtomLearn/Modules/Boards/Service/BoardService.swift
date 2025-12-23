import Foundation
import FirebaseFirestore

protocol BoardsService {
    // Живые обновления коллекции досок пользователя
    @discardableResult
    func observeBoards(ownerUID: String,
                       order: BoardsOrder,
                       onUpdate: @escaping (Result<[Board], Error>) -> Void) -> ListenerRegistration

    // Однократная загрузка (без listener)
    func fetchBoardsOnce(ownerUID: String, order: BoardsOrder) async throws -> [Board]

    // Создание новой доски
    func createBoard(ownerUID: String, title: String, description: String) async throws
}

extension BoardsService {
    // Удобные дефолтные вызовы (новые сверху)
    @discardableResult
    func observeBoards(ownerUID: String,
                       onUpdate: @escaping (Result<[Board], Error>) -> Void) -> ListenerRegistration {
        observeBoards(ownerUID: ownerUID, order: .createdAtDesc, onUpdate: onUpdate)
    }

    func fetchBoardsOnce(ownerUID: String) async throws -> [Board] {
        try await fetchBoardsOnce(ownerUID: ownerUID, order: .createdAtDesc)
    }
}
