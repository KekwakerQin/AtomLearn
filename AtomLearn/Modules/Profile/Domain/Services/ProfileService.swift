import Foundation

protocol ProfileService {
    func fetchProfile(userId: String) async throws -> ProfileDraft?
    func saveProfile(userId: String, draft: ProfileDraft) async throws
}
