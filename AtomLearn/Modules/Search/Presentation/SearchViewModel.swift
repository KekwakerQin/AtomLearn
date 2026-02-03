import Foundation

/// ViewModel для экрана поиска.
final class SearchViewModel {
    struct Item: Hashable {
        let id = UUID()
        let title: String
        let subtitle: String
        let kind: Kind

        enum Kind: String {
            case board
            case card
            case article
            case tag
        }
    }

    struct Section: Hashable {
        let id = UUID()
        let title: String
        let items: [Item]
    }

    struct State: Equatable {
        var query: String = ""
        var sections: [Section] = []
    }

    // MARK: - Dependencies
    private let service: SearchService

    private let recent: [Item] = [
        Item(title: "Анатомия", subtitle: "Доска", kind: .board),
        Item(title: "Phrasal verbs", subtitle: "Карточки", kind: .card)
    ]

    private let trending: [Item] = [
        Item(title: "Product management", subtitle: "Тренд недели", kind: .tag),
        Item(title: "Нейросети", subtitle: "Тренд недели", kind: .tag),
        Item(title: "Английский", subtitle: "Тренд недели", kind: .tag)
    ]

    private let all: [Item] = [
        Item(title: "Алгебра", subtitle: "Доска", kind: .board),
        Item(title: "История", subtitle: "Доска", kind: .board),
        Item(title: "Интервальные повторы", subtitle: "Статья", kind: .article),
        Item(title: "Уравнения", subtitle: "Карточки", kind: .card),
        Item(title: "Английский", subtitle: "Доска", kind: .board)
    ]

    private(set) var state = State() {
        didSet { onStateChange?(state) }
    }

    var onStateChange: ((State) -> Void)?

    // MARK: - Init
    init(service: SearchService) {
        self.service = service
    }

    func onViewDidLoad() {
        _ = service
        apply(query: "")
    }

    func updateQuery(_ query: String) {
        apply(query: query)
    }

    private func apply(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        state.query = trimmed

        if trimmed.isEmpty {
            state.sections = [
                Section(title: "Недавние", items: recent),
                Section(title: "Популярное", items: trending)
            ]
        } else {
            let results = all.filter {
                $0.title.lowercased().contains(trimmed.lowercased()) ||
                $0.subtitle.lowercased().contains(trimmed.lowercased())
            }
            state.sections = [Section(title: "Результаты", items: results)]
        }
    }
}
