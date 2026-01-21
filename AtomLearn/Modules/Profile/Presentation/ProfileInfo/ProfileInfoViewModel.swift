import Foundation

final class ProfileInfoViewModel {

    // MARK: - Dependencies
    private let authService: AuthService

    // MARK: - Output
    var onSignedOut: (() -> Void)?
    var onError: ((Error) -> Void)?

    // MARK: - Init
    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - Public API
    func signOutTapped() async {
        do {
            try await authService.signOut()
            onSignedOut?()
        } catch {
            onError?(error)
        }
    }
}
