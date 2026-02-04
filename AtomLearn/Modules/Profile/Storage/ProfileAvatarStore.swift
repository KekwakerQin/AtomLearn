import UIKit

final class ProfileAvatarStore {
    static let shared = ProfileAvatarStore()

    private init() {}

    func save(image: UIImage, for userId: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        let url = fileURL(for: userId)
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
            return url.path
        } catch {
            print("[ProfileAvatarStore] save error:", error.localizedDescription)
            return nil
        }
    }

    func loadImage(path: String?) -> UIImage? {
        guard let path, !path.isEmpty else { return nil }
        return UIImage(contentsOfFile: path)
    }

    private func fileURL(for userId: String) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("profile_avatars").appendingPathComponent("\(userId).jpg")
    }
}
