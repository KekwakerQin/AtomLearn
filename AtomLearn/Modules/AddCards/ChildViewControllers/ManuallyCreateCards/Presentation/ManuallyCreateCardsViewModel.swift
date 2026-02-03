import Foundation

final class ManuallyCreateCardsViewModel {

    // MARK: - Dependencies
    private let boardId: String
    private let ownerId: String
    private let service: ManuallyCreateCardsServiceProtocol

    // MARK: - Public API
    struct State: Equatable {
        var items: [ManuallyCreateCardsDraft]
        var isSaving: Bool
        var errorMessage: String?
    }

    enum Route: Equatable {
        case close
        case saved
    }

    enum ValidationIssue: Equatable {
        case noCards
        case emptyQuestion(index: Int)
        case emptyAnswer(index: Int)
    }

    var onStateChange: ((State) -> Void)?
    var onRoute: ((Route) -> Void)?
    var onValidationFailed: ((ValidationIssue) -> Void)?

    /// Call from VC when user updates question.
    func updateQuestion(id: UUID, text: String) {
        guard let idx = state.items.firstIndex(where: { $0.id == id }) else { return }
        state.items[idx].question = text
    }

    /// Call from VC when user updates answer.
    func updateAnswer(id: UUID, text: String) {
        guard let idx = state.items.firstIndex(where: { $0.id == id }) else { return }
        state.items[idx].answer = text
    }

    /// Adds one more empty card draft.
    func addCard() {
        state.items.append(ManuallyCreateCardsDraft())
        publish()
    }
    
    /// Removes card draft by id.
    func removeCard(id: UUID) {
        state.items.removeAll { $0.id == id }
        publish()
    }

    /// Validates and saves all cards.
    func saveTapped() {
        if let issue = firstValidationIssue() {
            onValidationFailed?(issue)
            return
        }

        Task { [weak self] in
            guard let self else { return }
            await self.save()
        }
    }

    /// Call from VC on first load.
    func onViewDidLoad() {
        if state.items.isEmpty {
            state.items = [ManuallyCreateCardsDraft()]
            publish()
        }
    }

    // MARK: - Private helpers
    private var state: State

    init(boardId: String, ownerId: String, service: ManuallyCreateCardsServiceProtocol) {
        self.boardId = boardId
        self.ownerId = ownerId
        self.service = service
        self.state = State(
            items: [],
            isSaving: false,
            errorMessage: nil
        )
    }

    private func publish() {
        onStateChange?(state)
    }

    private func firstValidationIssue() -> ValidationIssue? {
        if state.items.isEmpty { return .noCards }
        for (index, item) in state.items.enumerated() {
            let q = item.question.trimmingCharacters(in: .whitespacesAndNewlines)
            if q.isEmpty { return .emptyQuestion(index: index) }

            let a = item.answer.trimmingCharacters(in: .whitespacesAndNewlines)
            if a.isEmpty { return .emptyAnswer(index: index) }
        }
        return nil
    }

    @MainActor
    private func setSaving(_ isSaving: Bool) {
        state.isSaving = isSaving
        state.errorMessage = nil
        publish()
    }

    private func save() async {
        await MainActor.run { setSaving(true) }

        do {
            let payload = state.items.map {
                ManuallyCreateCardsPayload(
                    question: $0.question.trimmingCharacters(in: .whitespacesAndNewlines),
                    answer: $0.answer.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }

            try await service.addCards(boardId: boardId, ownerId: ownerId, cards: payload)

            await MainActor.run {
                setSaving(false)
                state.items = [ManuallyCreateCardsDraft()]
                publish()
            }
            onRoute?(.saved)
        } catch {
            await MainActor.run {
                setSaving(false)
                state.errorMessage = "Не удалось сохранить. Попробуй ещё раз."
                publish()
            }
        }
    }
}
