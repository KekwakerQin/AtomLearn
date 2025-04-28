import RealmSwift
import UIKit

final class CardCacheManager {
    private let realm = try! Realm()
    
    func cacheCards(_ cards: [Card]) {
        DispatchQueue.main.async {
            let realm = try! Realm()
            let realmCards = cards.map { RealmCard(card: $0) }
            try! realm.write {
                realm.add(realmCards, update: .modified)
            }
        }
    }
    
    func getCachedCards(for boardID: String) -> [Card] {
        do {
            let realm = try Realm()
            return realm.objects(RealmCard.self)
                .filter("boardID == %@", boardID)
                .map { $0.toCard() }
        } catch {
            print("Failed to open Realm: \(error)")
            return []
        }
    }
    
}
