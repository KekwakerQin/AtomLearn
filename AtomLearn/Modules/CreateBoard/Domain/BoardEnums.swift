import Foundation

enum BoardVisibility: String, CaseIterable {
    case `private`
    case `public`
}

enum BoardCollaboratorRole: String, CaseIterable {
    case owner
    case editor
    case viewer
}

enum BoardLearningIntent: String, CaseIterable {
    case study
    case exam
    case work
    case personal
}

enum BoardRepetitionModel {
    case fsrs
    case fsrs_exam
    case simple
    case srs

    static func available(for intent: BoardLearningIntent) -> [BoardRepetitionModel] {
        switch intent {
        case .exam:
            return [.fsrs_exam]
        case .study, .work, .personal:
            return [.fsrs, .srs, .simple]
        }
    }

    var displayTitle: String {
        switch self {
        case .fsrs: return "FSRS"
        case .srs: return "SRS"
        case .fsrs_exam: return "FSRS Exam"
        case .simple: return "Ежедневный"
        }
    }
}
