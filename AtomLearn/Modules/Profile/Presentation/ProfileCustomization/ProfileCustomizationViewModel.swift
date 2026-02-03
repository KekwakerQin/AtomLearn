import Foundation

@MainActor
final class ProfileCustomizationViewModel {
    struct State: Equatable {
        var draft: ProfileDraft
        var initial: ProfileDraft
        var isSaving: Bool
        var errorMessage: String?

        var isDirty: Bool { draft != initial }
    }

    private let userId: String
    private let service: ProfileService

    private(set) var state: State {
        didSet { onStateChange?(state) }
    }

    var onStateChange: ((State) -> Void)?

    init(userId: String, initialDraft: ProfileDraft, service: ProfileService = ProfileRepository()) {
        self.userId = userId
        self.service = service
        self.state = State(draft: initialDraft, initial: initialDraft, isSaving: false, errorMessage: nil)
    }

    func onViewDidLoad() {
        Task { [weak self] in
            guard let self else { return }
            do {
                if let remote = try await service.fetchProfile(userId: userId) {
                    await MainActor.run {
                        self.state.draft = remote
                        self.state.initial = remote
                    }
                }
            } catch {
                await MainActor.run {
                    self.state.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }

    func updateDraft(_ draft: ProfileDraft) {
        state.draft = draft
    }

    func saveTapped() {
        guard state.isDirty else { return }
        state.isSaving = true
        state.errorMessage = nil

        let draft = state.draft
        Task { [weak self] in
            guard let self else { return }
            do {
                try await service.saveProfile(userId: userId, draft: draft)
                await MainActor.run {
                    self.state.initial = draft
                    self.state.isSaving = false
                }
            } catch {
                await MainActor.run {
                    self.state.isSaving = false
                    self.state.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }
}
