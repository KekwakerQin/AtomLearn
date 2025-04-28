import UIKit
import RxSwift
import Firebase
import FirebaseFirestore
import RealmSwift

protocol BoardDetailServiceProtocol {
    func createCard(for boardID: String) -> Single<Void>
    func deleteCards(for boardID: String) -> Completable
    func fetchCards(for boardID: String, limit: Int?) -> Single<[Card]>
    func listenerCards(for boardID: String, listener: @escaping (Result<[Card], Error>) -> Void) -> ListenerRegistration
}

final class BoardDetailService: BoardDetailServiceProtocol {
    
    func listenerCards(for boardID: String, listener: @escaping (Result<[Card], Error>) -> Void) -> ListenerRegistration {
        return FirestorePaths.cardsCollection(forBoard: boardID)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    listener(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    listener(.success([]))
                    return
                }
                
                do {
                    let cards = try documents.map { try $0.data(as: Card.self) }
                    listener(.success(cards))
                } catch {
                    listener(.failure(error))
                }
            }
    }
    
    func fetchCards(for boardID: String, limit: Int?) -> Single<[Card]> {
        Single.create { single in
            var query: FirebaseFirestore.Query = FirestorePaths.cardsCollection(forBoard: boardID)

            if let limit = limit {
                query = query.limit(to: limit)
            }

            query.getDocuments { snapshot, error in
                if let error = error {
                    single(.failure(error))
                } else {
                    do {
                        let cards = try snapshot?.documents.map { try $0.data(as: Card.self) } ?? []
                        single(.success(cards))
                    } catch {
                        single(.failure(error))
                    }
                }
            }

            return Disposables.create()
        }
    }
    
    // Заглушка
    func generateRandomCardTitleWithNumber() -> String {
        let number = Int.random(in: 1...100)
        return "Card #\(number)"
    }
    
    func createCard(for boardID: String) -> Single<Void> {
        let cardID = UUID().uuidString
        let card = Card(
            id: cardID,
            term: generateRandomCardTitleWithNumber(),
            definition: "Learn",
            boardID: boardID,
            createdBy: SessionManager.shared.currentUser?.uid ?? "unknown"
        )
        
        let cardRef = FirestorePaths.cardsCollection(forBoard: boardID).document(cardID)
        
        return Single.create { single in
            do {
                try cardRef.setData(from: card) { error in
                    if let error = error {
                        single(.failure(error))
                    } else {
                        single(.success(()))
                    }
                }
            } catch {
                single(.failure(error))
            }
            return Disposables.create()
        }
    }
    
    func deleteCards(for boardID: String) -> Completable {
        let cardsRef = FirestorePaths.cardsCollection(forBoard: boardID)
        
        return Completable.create { completable in
            cardsRef.getDocuments { snapshot, error in
                if let error = error {
                    completable(.error(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completable(.completed)
                    return
                }
                
                let batch = Firestore.firestore().batch()
                for doc in documents {
                    batch.deleteDocument(doc.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        completable(.error(error))
                    } else {
                        completable(.completed)
                    }
                }
            }
            
            return Disposables.create()
        }
    }
   
}
