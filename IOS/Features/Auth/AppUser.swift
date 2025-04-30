import Foundation
import FirebaseFirestore

struct AppUser: Codable {
    @DocumentID var id: String?
    let uid: String
    let username: String
    let photoURL: String
    let registeredAt: Date
    let coins: Int
}
