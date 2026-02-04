import Foundation

final class BoardDocumentStore {
    static let shared = BoardDocumentStore()

    private init() {}

    func load(boardId: String) -> [BoardDocument] {
        let url = indexURL(boardId: boardId)
        guard let data = try? Data(contentsOf: url) else { return [] }
        guard let docs = try? JSONDecoder().decode([BoardDocument].self, from: data) else { return [] }
        return docs.sorted { $0.createdAt > $1.createdAt }
    }

    @discardableResult
    func addDocuments(boardId: String, urls: [URL]) -> [BoardDocument] {
        var existing = load(boardId: boardId)
        var added: [BoardDocument] = []

        for url in urls {
            if let doc = copyToLocal(boardId: boardId, from: url) {
                existing.append(doc)
                added.append(doc)
            }
        }

        saveIndex(existing, boardId: boardId)
        return added
    }

    func rename(boardId: String, documentId: String, newTitle: String) -> BoardDocument? {
        var docs = load(boardId: boardId)
        guard let idx = docs.firstIndex(where: { $0.id == documentId }) else { return nil }
        docs[idx].title = newTitle
        saveIndex(docs, boardId: boardId)
        return docs[idx]
    }

    func delete(boardId: String, documentId: String) {
        var docs = load(boardId: boardId)
        guard let idx = docs.firstIndex(where: { $0.id == documentId }) else { return }
        let doc = docs[idx]
        try? FileManager.default.removeItem(at: doc.url)
        docs.remove(at: idx)
        saveIndex(docs, boardId: boardId)
    }

    // MARK: - Private
    private func copyToLocal(boardId: String, from url: URL) -> BoardDocument? {
        let didStart = url.startAccessingSecurityScopedResource()
        defer { if didStart { url.stopAccessingSecurityScopedResource() } }

        let ext = url.pathExtension.lowercased()
        let kind = kindFromExtension(ext)

        let fileName = url.lastPathComponent
        let id = UUID().uuidString
        let targetName = ext.isEmpty ? id : "\(id).\(ext)"
        let targetURL = boardDirectory(boardId: boardId).appendingPathComponent(targetName)

        do {
            try FileManager.default.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: targetURL.path) {
                try FileManager.default.removeItem(at: targetURL)
            }
            try FileManager.default.copyItem(at: url, to: targetURL)
        } catch {
            // Fallback: read/write data (useful for some security-scoped URLs).
            if let data = try? Data(contentsOf: url) {
                do {
                    try data.write(to: targetURL, options: .atomic)
                } catch {
                    print("[BoardDocumentStore] Copy error:", error.localizedDescription)
                    return nil
                }
            } else {
                print("[BoardDocumentStore] Read error for:", url)
                return nil
            }
        }

        let title = url.deletingPathExtension().lastPathComponent
        return BoardDocument(
            id: id,
            title: title.isEmpty ? fileName : title,
            fileName: fileName,
            localPath: targetURL.path,
            createdAt: Date(),
            kind: kind
        )
    }

    private func kindFromExtension(_ ext: String) -> BoardDocument.Kind {
        switch ext {
        case "pdf": return .pdf
        case "txt", "text": return .text
        case "rtf": return .rtf
        case "html", "htm": return .html
        case "png", "jpg", "jpeg", "heic", "heif": return .image
        default: return .other
        }
    }

    private func boardDirectory(boardId: String) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("board_documents").appendingPathComponent(boardId)
    }

    private func indexURL(boardId: String) -> URL {
        boardDirectory(boardId: boardId).appendingPathComponent("index.json")
    }

    private func saveIndex(_ documents: [BoardDocument], boardId: String) {
        let url = indexURL(boardId: boardId)
        let data = (try? JSONEncoder().encode(documents)) ?? Data()
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[BoardDocumentStore] Save error:", error.localizedDescription)
        }
    }
}
