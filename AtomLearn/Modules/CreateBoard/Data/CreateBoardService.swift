import Foundation
import FirebaseFirestore

protocol CreateBoardServiceProtocol {
    /// Создать борд и вернуть его boardId
    func createBoard(
        ownerUID: String,
        input: CreateBoardInput
    ) async throws -> String
}

final class CreateBoardService: CreateBoardServiceProtocol {

    // MARK: Dependencies
    private let db = Firestore.firestore()

    // MARK: Public API
    func createBoard(
        ownerUID: String,
        input: CreateBoardInput
    ) async throws -> String {

        let boardRef = db.collection("boards").document()
        let boardId = boardRef.documentID

        // Гарантия уникальности: retry-транзакция со сменой slug
        let maxAttempts = 6
        var lastError: Error?

        for _ in 0..<maxAttempts {
            let slugCandidate = makeSlugCandidate(from: input.title)

            do {
                try await runCreateTransaction(
                    boardRef: boardRef,
                    boardId: boardId,
                    ownerUID: ownerUID,
                    input: input,
                    shareSlug: slugCandidate
                )
                return boardId
            } catch {
                lastError = error

                // Если конфликт slug — повторим
                if isAlreadyExistsError(error) {
                    continue
                }
                throw error
            }
        }

        throw lastError ?? NSError(domain: "CreateBoardService", code: -1)
    }

    // MARK: Private helpers

    private func runCreateTransaction(
        boardRef: DocumentReference,
        boardId: String,
        ownerUID: String,
        input: CreateBoardInput,
        shareSlug: String
    ) async throws {

        let slugRef = db.collection("slugs").document(shareSlug)
        let userMetaRef = db.collection("users").document(ownerUID).collection("boards").document(boardId)

        try await db.runTransaction { transaction, errorPointer in
            do {
                // 1) reserve slug
                let slugSnap = try transaction.getDocument(slugRef)
                if slugSnap.exists {
                    // специально кидаем "already exists", чтобы поймать и retry
                    throw NSError(domain: FirestoreErrorDomain, code: FirestoreErrorCode.alreadyExists.rawValue)
                }

                transaction.setData([
                    "boardId": boardId,
                    "createdAt": FieldValue.serverTimestamp()
                ], forDocument: slugRef)

                // 2) board doc
                var boardData: [String: Any] = [
                    "id": boardId,
                    "shareSlug": shareSlug,

                    "title": input.title,
                    "description": input.description,
                    "subject": input.subject,
                    "lang": input.lang,
                    "tags": input.tags,

                    "ownerUID": ownerUID,
                    "visibility": input.visibility.rawValue,

                    "isArchived": false,
                    "isOfficial": false,
                    "isTemplate": false,

                    "learning": [
                        "intent": input.learningIntent.rawValue,
                        "repetitionModel": input.repetitionModel.rawValue
                    ],

                    "counts": [
                        "cards": 0,
                        "learnableNow": 0,   // <- твое поле "сколько можно уже начать учить"
                        "learners": 1,
                        "reviews": 0
                    ],

                    "rating": [
                        "avg": 0.0,
                        "count": 0
                    ],

                    "analytics": [
                        "createdFromUID": ownerUID
                    ],

                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp(),
                    "lastActivityAt": FieldValue.serverTimestamp()
                ]

                if input.learningIntent == .exam {
                    // examDate обязателен по твоим правилам
                    guard let examDate = input.examDate else {
                        throw NSError(
                            domain: "CreateBoardService",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "examDate is required"]
                        )
                    }

                    var learning = boardData["learning"] as? [String: Any] ?? [:]
                    learning["exam"] = ["date": Timestamp(date: examDate)]
                    boardData["learning"] = learning
                }

                transaction.setData(boardData, forDocument: boardRef)

                // 3) collaborators: owner + extra
                let ownerCollabRef = boardRef.collection("collaborators").document(ownerUID)
                transaction.setData([
                    "uid": ownerUID,
                    "role": BoardCollaboratorRole.owner.rawValue,
                    "addedAt": FieldValue.serverTimestamp()
                ], forDocument: ownerCollabRef)

                for c in input.extraCollaborators {
                    let ref = boardRef.collection("collaborators").document(c.uid)
                    transaction.setData([
                        "uid": c.uid,
                        "role": c.role.rawValue,
                        "addedAt": FieldValue.serverTimestamp()
                    ], forDocument: ref)
                }

                // 4) userMeta
                transaction.setData([
                    "pinned": false,
                    "progress": 0.0,
                    "lastOpenedAt": FieldValue.serverTimestamp()
                ], forDocument: userMetaRef)

                return nil
            } catch {
                // Firestore API here expects a NON-throwing closure; propagate via error pointer.
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    private func makeSlugCandidate(from title: String) -> String {
        let base = slugify(title)
        let suffix = randomSlugSuffix(length: 5)
        if base.isEmpty {
            return "board-\(suffix)"
        }
        return "\(base)-\(suffix)"
    }

    private func randomSlugSuffix(length: Int) -> String {
        let chars = Array("abcdefghijklmnopqrstuvwxyz0123456789")
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }

    /// Простой slugify + частичная транслитерация кириллицы (достаточно для shareSlug)
    private func slugify(_ input: String) -> String {
        let lowered = input.lowercased()
        let latin = transliterateRUToLatin(lowered)
        let allowed = latin.map { ch -> Character in
            if ("a"..."z").contains(ch) || ("0"..."9").contains(ch) { return ch }
            return "-"
        }
        let raw = String(allowed)
        let collapsed = raw
            .replacingOccurrences(of: "-{2,}", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return String(collapsed.prefix(40))
    }

    private func transliterateRUToLatin(_ s: String) -> String {
        let map: [Character: String] = [
            "а":"a","б":"b","в":"v","г":"g","д":"d","е":"e","ё":"e","ж":"zh","з":"z","и":"i","й":"y",
            "к":"k","л":"l","м":"m","н":"n","о":"o","п":"p","р":"r","с":"s","т":"t","у":"u","ф":"f",
            "х":"h","ц":"ts","ч":"ch","ш":"sh","щ":"sch","ъ":"","ы":"y","ь":"","э":"e","ю":"yu","я":"ya"
        ]
        var out = ""
        out.reserveCapacity(s.count)
        for ch in s {
            out += map[ch] ?? String(ch)
        }
        return out
    }

    private func isAlreadyExistsError(_ error: Error) -> Bool {
        let ns = error as NSError
        return ns.domain == FirestoreErrorDomain && ns.code == FirestoreErrorCode.alreadyExists.rawValue
    }
}
