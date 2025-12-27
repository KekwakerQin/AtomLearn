final class CreateBoardViewModel {

    // MARK: - Dependencies
    private let user: AppUser

    // MARK: - Init
    init(user: AppUser) {
        self.user = user
    }

    /// Экран загрузился
    func onViewDidLoad() {}
}
