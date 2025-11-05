import Foundation

// Варианты сортировки досок
public enum BoardsOrder {
    // Старые сверху
    case createdAtAsc
    // Новые сверху
    case createdAtDesc

    var descending: Bool {
        switch self {
        case .createdAtAsc:
            return false
        case .createdAtDesc:
            return true
        }
    }
}
