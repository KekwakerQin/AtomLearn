enum BoardAccess {
    case owner
    case editor
    case viewer
    case none

    var canCreateBoard: Bool {
        switch self {
        case .owner, .editor: return true
        case .viewer, .none: return false
        }
    }
}
