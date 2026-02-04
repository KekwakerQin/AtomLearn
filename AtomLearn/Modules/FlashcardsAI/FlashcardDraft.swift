import Foundation

// Ровно то, что ждём от LLM.
struct FlashcardDraft: Codable, Hashable {
    let front: String
    let back: String
    let tags: [String]
    /// Optional anchor to validate/ground cards against a provided context (e.g. documents).
    let sourceQuote: String?

    init(front: String, back: String, tags: [String] = [], sourceQuote: String? = nil) {
        self.front = front
        self.back = back
        self.tags = tags
        self.sourceQuote = sourceQuote
    }

    private enum CodingKeys: String, CodingKey {
        case front
        case back
        case tags

        case sourceQuote
        case sourceQuoteSnake = "source_quote"
        case quote
        case evidence
        case source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.front = try container.decode(String.self, forKey: .front)
        self.back = try container.decode(String.self, forKey: .back)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []

        // Avoid long chains of try/?? that can hinder type-checking.
        let candidateKeys: [CodingKeys] = [.sourceQuote, .sourceQuoteSnake, .quote, .evidence, .source]
        var foundSourceQuote: String? = nil
        for key in candidateKeys {
            if let value = try container.decodeIfPresent(String.self, forKey: key) {
                foundSourceQuote = value
                break
            }
        }
        self.sourceQuote = foundSourceQuote
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(front, forKey: .front)
        try container.encode(back, forKey: .back)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(sourceQuote, forKey: .sourceQuote)
    }
}
