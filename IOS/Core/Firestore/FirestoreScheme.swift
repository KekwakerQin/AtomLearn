enum FirestoreCollections {
    static let users = "users"
    static let boards = "boards"
    static let cards = "cards"
    static let progress = "learn_progress"       // Прогресс по карточкам
    static let stats = "stats"
    static let storeItems = "game_store"
}

enum FirestoreFields {
    enum User {
        static let uid = "uid"
        static let username = "username"
        static let photoURL = "photoURL"
        static let registeredAt = "registeredAt" 
        static let coins = "coins"
    }
    
    enum Board {
        static let boardID = "boardID"
        static let ownerUID = "ownerUID"
        static let profilePictures = "profilePictures"
        static let title = "title"
        static let description = "description"
        static let cardsCollection = "cards"
        static let createdAt = "createdAt"
    }
    
    enum CardFields {
        static let id = "id"
        static let term = "term"
        static let definition = "definition"
        static let boardID = "boardID"
        static let createdBy = "createdBy"
    }
    
    enum CardProgressFields {
        static let cardID = "cardID"
        static let boardID = "boardID"
        static let level = "level"
        static let xp = "xp"
        static let lastReviewed = "lastReviewed"
        static let nextReviewAt = "nextReviewAt"
        static let timesCorrect = "timesCorrect"
        static let timesWrong = "timesWrong"
    }
}
