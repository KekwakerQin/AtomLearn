import Foundation

// MARK: - Модель карточки (мок)
struct StudyCard: Identifiable, Equatable {
    let id: UUID = UUID()
    let deckTitle: String          // "Анатомия человека"
    let term: String               // "Синапсис"
    let answer: String             // "Синапс — это..."
}

// MARK: - Дни недели + стрик
enum StreakState {
    case done
    case current
    case missed
    case future
}

struct StreakDay: Identifiable, Equatable {
    let id: UUID = UUID()
    let shortName: String          // "Пн", "Вт"...
    let state: StreakState
    let isSpecial: Bool            // текущий день с "животным/огоньком"
}
