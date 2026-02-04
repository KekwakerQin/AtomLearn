import Foundation

/// ViewModel для экрана профиля.
final class ProfileViewModel {
    // MARK: - Dependencies
    private let service: ProfileService

    // MARK: - Output
    var onProfileUpdated: ((ProfileDraft) -> Void)?
    var onError: ((Error) -> Void)?

    // MARK: - Init
    /// Создаёт ViewModel профиля.
    init(service: ProfileService) {
        self.service = service
    }

    // MARK: - Lifecycle
    /// Обрабатывает событие загрузки экрана.
    func onViewDidLoad(userId: String) {
        Task { [weak self] in
            guard let self else { return }
            do {
                if let draft = try await service.fetchProfile(userId: userId) {
                    await MainActor.run { self.onProfileUpdated?(draft) }
                }
            } catch {
                await MainActor.run { self.onError?(error) }
            }
        }
    }
}
