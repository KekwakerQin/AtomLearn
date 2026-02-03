import Foundation
import FirebaseFirestore

/// Репозиторий профиля пользователя.
final class ProfileRepository: ProfileService {
    private let db = Firestore.firestore()

    func fetchProfile(userId: String) async throws -> ProfileDraft? {
        let doc = try await db.collection("profiles").document(userId).getDocument()
        guard let data = doc.data() else { return nil }
        return ProfileDraft.fromFirestore(data)
    }

    func saveProfile(userId: String, draft: ProfileDraft) async throws {
        var data = draft.toFirestore()
        data["updatedAt"] = FieldValue.serverTimestamp()
        try await db.collection("profiles").document(userId).setData(data, merge: true)
    }
}
