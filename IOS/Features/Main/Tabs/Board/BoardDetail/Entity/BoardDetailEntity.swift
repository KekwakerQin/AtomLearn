import Foundation

struct Card: Codable, Identifiable {
    var id: String
    let term: String
    let definition: String
    let boardID: String
    let createdBy: String
}
