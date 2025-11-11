import Foundation

// Ровно то, что ждём от LLM.
struct FlashcardDraft: Codable, Hashable {
    let front: String
    let back: String
    let tags: [String]
}
