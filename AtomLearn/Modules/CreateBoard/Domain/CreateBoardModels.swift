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
