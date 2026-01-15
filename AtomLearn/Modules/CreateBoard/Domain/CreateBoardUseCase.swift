import Foundation

struct CreateBoardUseCase {

    // MARK: Dependencies
    private let service: CreateBoardServiceProtocol

    // MARK: Init
    init(service: CreateBoardServiceProtocol) {
        self.service = service
    }

    // MARK: Public API

    /// Создать борд (атомарно: board + collaborators + userMeta + уникальный shareSlug)
    func createBoard(
        ownerUID: String,
        input: CreateBoardInput
    ) async throws -> String {
        try await service.createBoard(ownerUID: ownerUID, input: input)
    }
}
