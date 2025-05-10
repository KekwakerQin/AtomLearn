import Foundation
import FirebaseFirestore

struct Board: Codable, Identifiable {
    var id: String { boardID }
    let boardID: String
    let ownerUID: String
    let profilePictures: [String]
    let title: String
    let description: String
    let createdAt: Date // date
}
