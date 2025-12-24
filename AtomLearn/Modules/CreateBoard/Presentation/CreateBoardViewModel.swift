import Foundation

final class CreateBoardViewModel {

    // MARK: - Dependencies
    private let user: AppUser
    private let useCase: CreateBoardUseCase

    // MARK: - Outputting
    var onCancel: (() -> Void)?
    var onFinish: (() -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Init
    init(
        user: AppUser,
        useCase: CreateBoardUseCase
    ) {
        self.user = user
        self.useCase = useCase
    }

    // MARK: - Public API

    /// Экран загрузился
    func onViewDidLoad() {}

    /// Пользователь нажал "Отмена"
    func cancel() {
        onCancel?()
    }

    /// Создать борд
    func createBoard(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onError?("Введите название доски")
            return
        }

        Task {
            do {
                try await useCase.createBoard(
                    title: trimmed,
                    ownerUID: user.uid
                )
                onFinish?()
            } catch {
                onError?("Не удалось создать доску")
            }
        }
    }
}
