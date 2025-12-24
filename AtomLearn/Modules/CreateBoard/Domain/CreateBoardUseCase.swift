struct CreateBoardUseCase {

    // MARK: - Dependencies
    private let service: CreateBoardServiceProtocol

    // MARK: - Init
    init(service: CreateBoardServiceProtocol) {
        self.service = service
    }

    /// Создать борд
    func createBoard(
        title: String,
        ownerUID: String
    ) async throws {
        try await service.createBoard(
            title: title,
            ownerUID: ownerUID
        )
    }
}
