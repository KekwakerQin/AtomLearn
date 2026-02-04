import Foundation

final class ProfileInfoViewModel {

    // MARK: - Dependencies
    private let authService: AuthService
    private let profileService: ProfileService

    // MARK: - Output
    var onSignedOut: (() -> Void)?
    var onError: ((Error) -> Void)?
    var onProfileUpdated: ((ProfileDraft) -> Void)?

    // MARK: - Init
    init(authService: AuthService, profileService: ProfileService = ProfileRepository()) {
        self.authService = authService
        self.profileService = profileService
    }

    // MARK: - Public API
    func onViewDidLoad(userId: String) {
        Task { [weak self] in
            guard let self else { return }
            do {
                if let draft = try await profileService.fetchProfile(userId: userId) {
                    await MainActor.run { self.onProfileUpdated?(draft) }
                }
            } catch {
                await MainActor.run { self.onError?(error) }
            }
        }
    }

    func signOutTapped() async {
        do {
            try await authService.signOut()
            onSignedOut?()
        } catch {
            onError?(error)
        }
    }
}
