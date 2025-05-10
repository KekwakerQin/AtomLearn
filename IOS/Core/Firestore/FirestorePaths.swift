import FirebaseFirestore
import FirebaseAuth

enum FirestorePaths {
    
    private static let db = Firestore.firestore()
    
    // MARK: - Users
    
    static func usersCollection() -> CollectionReference {
        db.collection("users")
    }
    
    static func userRef(uid: String) -> DocumentReference {
        usersCollection().document(uid)
    }
    

    // MARK: - Boards
    
    static func boardsCollection() -> CollectionReference {
        db.collection("boards")
    }
    
    static func boardRef(boardID: String) -> DocumentReference {
        boardsCollection().document(boardID)
    }
        
    
    // MARK: - Cards
    
    static func cardsCollection(forBoard boardID: String) -> CollectionReference {
        boardRef(boardID: boardID).collection(FirestoreFields.Board.cardsCollection)
    }
    
    // MARK: - Learn Progress (per user per card)
    
    static func progressCollection(uid: String) -> CollectionReference {
        userRef(uid: uid).collection("cards")
    }
    
    static func progressRef(uid: String, cardID: String) -> DocumentReference {
        progressCollection(uid: uid).document(cardID)
    }
    
    
    // MARK: - Stats
    
    static func statsCollection(uid: String) -> CollectionReference {
        userRef(uid: uid).collection("stats")
    }
    
    static func dailyStatRef(uid: String, dateKey: String) -> DocumentReference {
        statsCollection(uid: uid).document(dateKey) // dateKey = "2025-04-18"
    }
    
    
    // MARK: - Game Store
    
    static func storeItemsCollection() -> CollectionReference {
        db.collection("game_store")
    }
    
    static func storeItemRef(itemID: String) -> DocumentReference {
        storeItemsCollection().document(itemID)
    }
}
