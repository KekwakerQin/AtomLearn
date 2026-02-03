import Foundation

struct ManuallyCreateCardsDraft: Identifiable, Equatable {

    /// Temporary id for diffing and UI binding
    let id: UUID

    /// Question text (front)
    var question: String

    /// Answer text (back)
    var answer: String

    init(
        id: UUID = UUID(),
        question: String = "",
        answer: String = ""
    ) {
        self.id = id
        self.question = question
        self.answer = answer
    }
}

struct ManuallyCreateCardsPayload: Equatable {
    let question: String
    let answer: String
}
