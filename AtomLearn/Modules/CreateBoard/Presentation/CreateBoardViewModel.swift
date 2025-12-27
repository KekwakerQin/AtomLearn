import Foundation

final class CreateBoardViewModel {

    // MARK: Dependencies
    private let ownerUID: String
    private let useCase: CreateBoardUseCase

    // MARK: Output
    var onStateChanged: ((State) -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    var onFinish: ((String) -> Void)?
    var onCancel: (() -> Void)?

    // MARK: State
    private(set) var state: State {
        didSet { onStateChanged?(state) }
    }

    // MARK: Init
    init(
        ownerUID: String,
        useCase: CreateBoardUseCase
    ) {
        self.ownerUID = ownerUID
        self.useCase = useCase

        let lang = Locale.current.languageCode ?? "en"

        self.state = State(
            title: "",
            description: "",
            subject: "",
            lang: lang,
            tags: [],
            visibility: .public,
            intent: .study,
            repetitionModel: .fsrs,
            examDate: nil,
            extraCollaborators: [],
            suggestedTags: TagsCatalog.defaultTags(),
            fieldError: nil,
            canCreate: false,
            isExamDateVisible: false
        )
    }

    // MARK: Public API

    /// Экран загрузился
    func onViewDidLoad() {
        recomputeDerived()
    }

    /// Пользователь нажал "Отмена"
    func cancel() {
        onCancel?()
    }

    /// Обновить title
    func updateTitle(_ value: String) {
        state.title = value
        recomputeDerived()
    }

    /// Обновить description
    func updateDescription(_ value: String) {
        state.description = value
        recomputeDerived()
    }

    /// Обновить subject
    func updateSubject(_ value: String) {
        state.subject = value
        recomputeDerived()
    }

    /// Изменить visibility
    func selectVisibility(_ value: BoardVisibility) {
        state.visibility = value
        recomputeDerived()
    }

    /// Изменить intent
    func selectIntent(_ value: BoardLearningIntent) {
        state.intent = value

        // твои дефолты
        if value == .exam {
            state.repetitionModel = .fsrs_exam
        } else if state.repetitionModel == .fsrs_exam {
            state.repetitionModel = .fsrs
        }

        recomputeDerived()
    }

    /// Изменить repetitionModel
    func selectRepetitionModel(_ value: BoardRepetitionModel) {
        state.repetitionModel = value
        recomputeDerived()
    }

    /// Установить examDate
    func updateExamDate(_ date: Date) {
        state.examDate = date
        recomputeDerived()
    }

    /// Добавить тег (<= 5)
    func addTag(_ tag: String) {
        let t = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        guard state.tags.count < 5 else { return }
        guard !state.tags.contains(t) else { return }

        state.tags.append(t)
        recomputeDerived()
    }

    /// Удалить тег
    func removeTag(at index: Int) {
        guard state.tags.indices.contains(index) else { return }
        state.tags.remove(at: index)
        recomputeDerived()
    }

    /// Добавить коллаборатора (опционально)
    func addCollaborator(uid: String, role: BoardCollaboratorRole) {
        let u = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !u.isEmpty else { return }
        guard u != ownerUID else { return }
        guard !state.extraCollaborators.contains(where: { $0.uid == u }) else { return }

        state.extraCollaborators.append(.init(uid: u, role: role))
        recomputeDerived()
    }

    /// Удалить коллаборатора
    func removeCollaborator(at index: Int) {
        guard state.extraCollaborators.indices.contains(index) else { return }
        state.extraCollaborators.remove(at: index)
        recomputeDerived()
    }

    /// Создать борд
    func createBoard() {
        let trimmedTitle = state.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSubject = state.subject.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            onError?("Введите название доски")
            return
        }

        guard !trimmedSubject.isEmpty else {
            onError?("Укажите предмет (subject)")
            return
        }

        if state.intent == .exam, state.examDate == nil {
            onError?("Для режима экзамена укажите дату")
            return
        }

        onLoadingChanged?(true)

        let input = CreateBoardInput(
            title: trimmedTitle,
            description: state.description.trimmingCharacters(in: .whitespacesAndNewlines),
            subject: trimmedSubject,
            lang: state.lang,
            tags: state.tags,
            visibility: state.visibility,
            learningIntent: state.intent,
            repetitionModel: state.repetitionModel,
            examDate: state.examDate,
            extraCollaborators: state.extraCollaborators
        )

        Task { [weak self] in
            guard let self else { return }
            do {
                let boardId = try await useCase.createBoard(ownerUID: ownerUID, input: input)
                await MainActor.run {
                    self.onLoadingChanged?(false)
                    self.onFinish?(boardId)
                }
            } catch {
                await MainActor.run {
                    self.onLoadingChanged?(false)
                    self.onError?("Не удалось создать доску")
                }
            }
        }
    }

    // MARK: Private helpers

    private func recomputeDerived() {
        state.isExamDateVisible = (state.intent == .exam)

        // UI-возможность создать
        let hasTitle = !state.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasSubject = !state.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        let examOk = (state.intent != .exam) || (state.examDate != nil)
        state.canCreate = hasTitle && hasSubject && examOk
    }
}

// MARK: - View State

extension CreateBoardViewModel {

    struct State {
        var title: String
        var description: String
        var subject: String
        var lang: String
        var tags: [String]
        var visibility: BoardVisibility
        var intent: BoardLearningIntent
        var repetitionModel: BoardRepetitionModel
        var examDate: Date?

        var extraCollaborators: [BoardCollaboratorDraft]
        var suggestedTags: [String]

        var fieldError: String?
        var canCreate: Bool
        var isExamDateVisible: Bool
    }
}

// MARK: - Tags Catalog

private enum TagsCatalog {
    static func defaultTags() -> [String] {
        [
            "Programming", "Swift", "iOS", "Biology", "English",
            "Languages", "Hobby", "Math", "Physics", "Chemistry",
            "History", "Design", "Productivity"
        ]
    }
}

