import Foundation

public enum BoardsOrder: Sendable {
    case createdAtAsc      // старые сверху
    case createdAtDesc     // новые сверху

    var descending: Bool {
        switch self {
        case .createdAtAsc:  return false
        case .createdAtDesc: return true
        }
    }

    /// Меняет порядок без Equatable/`==`
    nonisolated func toggled() -> BoardsOrder {
        switch self {
        case .createdAtDesc: return .createdAtAsc
        case .createdAtAsc:  return .createdAtDesc
        }
    }

    /// Заголовок для кнопки
    nonisolated var title: String {
        switch self {
        case .createdAtDesc: return "Новые ↑"
        case .createdAtAsc:  return "Старые ↑"
        }
    }
}
