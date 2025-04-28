import RealmSwift

protocol CacheCleanerProtocol {
    func removeCacheFromCards()
    func removeCacheFromBoards()
    func removeAllCache()
}

final class CacheCleaner: CacheCleanerProtocol {
    
    private let realm = try! Realm()
    
    func removeCacheFromCards() {
        print("Cache_cleared")
        let allCards = realm.objects(RealmCard.self)
        try? realm.write {
            realm.delete(allCards)
        }
    }
    
    func removeCacheFromBoards() {
    }
    
    func removeAllCache() {
        try? realm.write {
            print("Кэш был почистен")
            realm.deleteAll()
        }
        
        if let userID = SessionManager.shared.currentUser?.id {
                CardPreloadManager.shared.restartPreloading(for: userID)
        } else {
            print("Не удалось найти userID для перезапуска предзагрузки")
        }
    }
    
}
