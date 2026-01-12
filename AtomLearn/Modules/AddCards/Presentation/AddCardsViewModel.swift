import Foundation

final class AddCardsViewModel {

    // MARK: - Dependencies
    private let board: Board
    private let user: AppUser
    private let service: AddCardsServiceProtocol

    // MARK: - Output
    var onCancel: (() -> Void)?

    // MARK: - Init
    init(
        board: Board,
        user: AppUser,
        service: AddCardsServiceProtocol = AddCardsService()
    ) {
        self.board = board
        self.user = user
        self.service = service
    }

    // MARK: - Lifecycle
    func onViewDidLoad() {
        print("AddCards открыт для boardId = \(board.id)")
    }

    // MARK: - Actions
    func addCard() {
        Task {
            do {
                try await service.addCard(
                    boardId: board.id,
                    ownerId: user.uid
                )
                print("[LOG:INFO] Карточка добавлена в board \(board.id)")
            } catch {
                print("[LOG:ERROR] \(error.localizedDescription)")
            }
        }
    }

    func cancel() {
        onCancel?()
    }
}
