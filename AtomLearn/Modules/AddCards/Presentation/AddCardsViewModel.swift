import Foundation

final class AddCardsViewModel {

    // MARK: - Dependencies
    private let boardId: String
    private let user: AppUser
    private let service: AddCardsServiceProtocol

    // MARK: - Output
    var onCancel: (() -> Void)?
    var onFinish: (() -> Void)?
    
    // MARK: - Init
    init(
        boardId: String,
        user: AppUser,
        service: AddCardsServiceProtocol = AddCardsService()
    ) {
        self.boardId = boardId
        self.user = user
        self.service = service
    }

    // MARK: - Lifecycle
    func onViewDidLoad() {
        print("AddCards открыт для boardId = \(boardId)")
    }

    // MARK: - Actions
    func addCard() {
        Task {
            do {
                try await service.addCard(
                    boardId: boardId,
                    ownerId: user.uid
                )
                print("[LOG:INFO] Карточка добавлена в board \(boardId)")
                onFinish?()
            } catch {
                print("[LOG:ERROR] \(error.localizedDescription)")
            }
        }
    }

    func cancel() {
        onCancel?()
    }
}
