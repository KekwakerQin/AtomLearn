import Foundation

final class AddEntityViewModel {

    // MARK: - State
    struct State {
        var searchText: String = ""
        var groupedBoards: [String: [Board]] = [:]
        var sortedKeys: [String] = []
    }

    // MARK: - Dependencies
    private let user: AppUser
    private let boardsService: BoardsService
    private var allBoards: [Board] = []

    // MARK: - Output
    var onStateChange: ((State) -> Void)?
    var onError: ((Error) -> Void)?

    private(set) var state = State()
    
    // MARK: - Navigation
    var onCreateBoard: (() -> Void)?
    var onSelectBoard: ((Board) -> Void)?

    // MARK: - Init
    init(user: AppUser,
         boardsService: BoardsService) {
        self.user = user
        self.boardsService = boardsService
    }

    // MARK: - Public API
    func onViewDidLoad() {
        loadBoards()
    }

    func updateSearch(text: String) {
        state.searchText = text
        applySearchAndGrouping()
    }
    
    // MARK: - Private helpers
    private func loadBoards() {
        Task {
            do {
                let boards = try await boardsService.fetchBoardsOnce(
                    ownerUID: user.uid
                )

                self.allBoards = boards
                applySearchAndGrouping()

            } catch {
                onError?(error)
            }
        }
    }
    
    // MARK: - Private helpers
    private func groupBoardsAlphabetically(_ boards: [Board]) {
        var letterGroups: [String: [Board]] = [:]
        var nonLetterBoards: [Board] = []

        for board in boards {
            guard let firstChar = board.title
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .first else {
                nonLetterBoards.append(board)
                continue
            }

            let letter = String(firstChar).uppercased()

            if letter.range(of: #"^\p{L}$"#, options: .regularExpression) != nil {
                letterGroups[letter, default: []].append(board)
            } else {
                nonLetterBoards.append(board)
            }
        }

        // сортируем элементы внутри каждой буквы
        for key in letterGroups.keys {
            letterGroups[key]?.sort {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        }

        // сортируем секции
        let sortedLetters = letterGroups.keys.sorted {
            $0.localizedCompare($1) == .orderedAscending
        }

        state.groupedBoards = letterGroups
        state.sortedKeys = sortedLetters

        if !nonLetterBoards.isEmpty {
            state.groupedBoards["#"] = nonLetterBoards.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
            state.sortedKeys.append("#")
        }
    }
    
    private func applySearchAndGrouping() {
        let filtered: [Board]

        if state.searchText.isEmpty {
            filtered = allBoards
        } else {
            filtered = allBoards.filter {
                $0.title.localizedCaseInsensitiveContains(state.searchText)
            }
        }

        groupBoardsAlphabetically(filtered)
        onStateChange?(state)
    }
    
    // MARK: - Navigation
    var onClose: (() -> Void)?

    /// Пользователь нажал "Отмена"
    func didTapClose() {
        onClose?()
    }

    // MARK: - Пользовательские события
    
    /// Пользователь нажал "Добавить доску"
    func didTapCreateBoard() {
        onCreateBoard?()
    }

    /// Пользователь выбрал существующую доску
    func didSelectBoard(_ board: Board) {
        onSelectBoard?(board)
    }
}
