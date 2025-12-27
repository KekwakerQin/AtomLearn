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

enum BoardRepetitionModel: String, CaseIterable {
    case fsrs
    case fsrs_exam
    case srs
    case everyday
    case fibonacci
    case linear
}
