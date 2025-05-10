import RealmSwift

final class RealmCard: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var term: String
    @Persisted var definition: String
    @Persisted var boardID: String
    @Persisted var createdBy: String

    // convenience init <- Card
    convenience init(card: Card) {
        self.init()
        self.id         = card.id
        self.term       = card.term
        self.definition = card.definition
        self.boardID    = card.boardID
        self.createdBy  = card.createdBy
    }

    // обратное преобразование
    func toCard() -> Card {
        Card(id: id, term: term, definition: definition, boardID: boardID, createdBy: createdBy)
    }
}
