import Foundation

enum GeneratedCardStatus: Equatable {
    case pending
    case added
    case skipped
}

struct GeneratedCardItem: Identifiable, Equatable {
    let id: UUID
    var draft: FlashcardDraft
    var isExpanded: Bool
    var isSelected: Bool
    var status: GeneratedCardStatus

    init(
        draft: FlashcardDraft,
        isExpanded: Bool = false,
        isSelected: Bool = false,
        status: GeneratedCardStatus = .pending
    ) {
        self.id = UUID()
        self.draft = draft
        self.isExpanded = isExpanded
        self.isSelected = isSelected
        self.status = status
    }
}
