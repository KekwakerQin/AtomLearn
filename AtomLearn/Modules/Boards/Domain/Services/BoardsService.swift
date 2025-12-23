import Foundation
import FirebaseFirestore

/// Протокол сервиса досок.
protocol BoardsService {
    /// Живые обновления коллекции досок пользователя.
    @discardableResult
    func observeBoards(ownerUID: String,
                       order: BoardsOrder,
                       onUpdate: @escaping (Result<[Board], Error>) -> Void) -> ListenerRegistration

    /// Однократная загрузка (без listener).
    func fetchBoardsOnce(ownerUID: String, order: BoardsOrder) async throws -> [Board]

    /// Создание новой доски.
    func createBoard(ownerUID: String, title: String, description: String) async throws
}

extension BoardsService {
    /// Удобный вызов с сортировкой по умолчанию.
    @discardableResult
    func observeBoards(ownerUID: String,
                       onUpdate: @escaping (Result<[Board], Error>) -> Void) -> ListenerRegistration {
        observeBoards(ownerUID: ownerUID, order: .createdAtDesc, onUpdate: onUpdate)
    }

    /// Удобный вызов загрузки с сортировкой по умолчанию.
    func fetchBoardsOnce(ownerUID: String) async throws -> [Board] {
        try await fetchBoardsOnce(ownerUID: ownerUID, order: .createdAtDesc)
    }
}
