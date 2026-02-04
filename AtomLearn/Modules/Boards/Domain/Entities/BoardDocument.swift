import Foundation

struct BoardDocument: Codable, Identifiable, Equatable {
    enum Kind: String, Codable {
        case pdf
        case text
        case rtf
        case html
        case image
        case other
    }

    let id: String
    var title: String
    let fileName: String
    let localPath: String
    let createdAt: Date
    let kind: Kind

    var url: URL { URL(fileURLWithPath: localPath) }
}
