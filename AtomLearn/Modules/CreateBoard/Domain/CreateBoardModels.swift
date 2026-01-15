import Foundation

// MARK: - Domain Models

struct CreateBoardInput {
    let title: String
    let description: String
    let subject: String
    let lang: String
    let tags: [String]
    let visibility: BoardVisibility
    let learningIntent: BoardLearningIntent
    let repetitionModel: BoardRepetitionModel
    let examDate: Date?
    let extraCollaborators: [BoardCollaboratorDraft]
}

struct BoardCollaboratorDraft: Equatable {
    let uid: String
    let role: BoardCollaboratorRole
}

extension BoardRepetitionModel {

    /// Строковое значение для хранения в Firestore
    var firestoreValue: String {
        switch self {
        case .fsrs:
            return "fsrs"
        case .srs:
            return "srs"
        case .fsrs_exam:
            return "fsrs_exam"
        case .simple:
            return "simple"
        }
    }
}
