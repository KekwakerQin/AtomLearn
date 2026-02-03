import Foundation
import FirebaseFirestore

final class ManuallyCreateCardsRepository: ManuallyCreateCardsRepositoryProtocol {
    
    init(){}
    
    func addCards(boardId: String, ownerId: String, cards: [ManuallyCreateCardsPayload]) async throws {
        guard !cards.isEmpty else { return }
        
        let db = Firestore.firestore()
        let cardsRef = db.collection("boards").document(boardId).collection("cards")
        let batch = db.batch()
        
        for payload in cards {
            let doc = cardsRef.document()
            let data: [String: Any] = [
                "boardId": boardId,
                "ownerId": ownerId,
                "front": payload.question,
                "back": payload.answer,
                "type": Card.ContentType.text.rawValue,
                "language": "ru",
                "tags": [],
                "status": Card.Status.published.rawValue,
                "visibility": Card.Visibility.private.rawValue,
                "reviewStats": [
                    "correct": 0,
                    "wrong": 0
                ],
                "spacedRepetition": [
                    "ease": 2.5,
                    "intervalDays": 0,
                    "dueAt": FieldValue.serverTimestamp(),
                    "reps": 0,
                    "lapses": 0
                ],
                "source": [
                    "kind": Card.SourceKind.manual.rawValue
                ],
                "isDeleted": false,
                "version": 1,
                "views": 0,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            batch.setData(data, forDocument: doc)
        }
        
        try await batch.commit()
    }
}
