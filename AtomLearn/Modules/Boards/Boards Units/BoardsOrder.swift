import Foundation

public enum BoardsOrder: Sendable {
    case createdAtAsc
    case createdAtDesc
    case lastActivityAtAsc
    case lastActivityAtDesc

    /// Firestore field key for ordering
    var field: String {
        switch self {
        case .createdAtAsc, .createdAtDesc:
            return "createdAt"
        case .lastActivityAtAsc, .lastActivityAtDesc:
            return "lastActivityAt"
        }
    }

    /// Firestore direction
    var descending: Bool {
        switch self {
        case .createdAtAsc, .lastActivityAtAsc:
            return false
        case .createdAtDesc, .lastActivityAtDesc:
            return true
        }
    }

    /// Меняет порядок (asc/desc) без Equatable
    nonisolated func toggled() -> BoardsOrder {
        switch self {
        case .createdAtDesc:       return .createdAtAsc
        case .createdAtAsc:        return .createdAtDesc
        case .lastActivityAtDesc:  return .lastActivityAtAsc
        case .lastActivityAtAsc:   return .lastActivityAtDesc
        }
    }

    /// Заголовок для кнопки сортировки
    nonisolated var title: String {
        switch self {
        case .createdAtDesc:      return "Новые ↑"
        case .createdAtAsc:       return "Старые ↑"
        case .lastActivityAtDesc: return "Активные ↑"
        case .lastActivityAtAsc:  return "Неактивные ↑"
        }
    }
}
