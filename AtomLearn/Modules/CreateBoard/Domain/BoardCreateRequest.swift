import Foundation

struct BoardCreateRequest {
    let title: String
    let description: String
    let subject: String
    let lang: String
    let tags: [String]
    let visibility: BoardVisibility
    let learningIntent: BoardLearningIntent
    let repetitionModel: BoardRepetitionModel
    let examDate: Date?
    let extraCollaborators: [BoardCollaboratorRequest]
}

struct BoardCollaboratorRequest: Equatable {
    let uid: String
    let role: BoardCollaboratorRole
}
