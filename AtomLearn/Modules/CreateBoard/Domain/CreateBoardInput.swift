/**
 •    это состояние экрана
 •    пользователь может:
 •    не заполнить всё
 •    отменить
 •    поменять решение
 •    Board не должен существовать без id
 */
import Foundation

struct CreateBoardInput {
    let title: String
    let description: String?
    let subject: String
    let lang: String
    let tags: [String]
    let visibility: BoardVisibility
    let learningIntent: BoardLearningIntent
    let repetitionModel: BoardRepetitionModel
    let examDate: Date?
}


// MARK: - Domain enums

enum BoardVisibility: String {
    case `private`
    case `public`
}

enum BoardCollaboratorRole: String {
    case owner
    case editor
    case viewer
}

enum BoardLearningIntent: String {
    case study
    case exam
    case work
    case personal
}

enum BoardRepetitionModel: String {
    case fsrs
    case fsrs_exam
    case srs
    case everyday
    case fibonacci
    case linear
}

