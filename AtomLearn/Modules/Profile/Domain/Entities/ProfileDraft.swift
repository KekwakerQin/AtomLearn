import Foundation

struct ProfileDraft: Equatable {
    var displayName: String
    var username: String
    var bio: String
    var location: String
    var website: String
    var avatarPath: String?

    static func fromFirestore(_ data: [String: Any]) -> ProfileDraft? {
        guard let displayName = data["displayName"] as? String,
              let username = data["username"] as? String else { return nil }

        return ProfileDraft(
            displayName: displayName,
            username: username,
            bio: data["bio"] as? String ?? "",
            location: data["location"] as? String ?? "",
            website: data["website"] as? String ?? "",
            avatarPath: data["avatarPath"] as? String
        )
    }

    func toFirestore() -> [String: Any] {
        [
            "displayName": displayName,
            "username": username,
            "bio": bio,
            "location": location,
            "website": website,
            "avatarPath": avatarPath as Any
        ]
    }
}
