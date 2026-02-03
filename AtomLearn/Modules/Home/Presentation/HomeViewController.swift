import UIKit

final class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    struct Item {
        let title: String
        let subtitle: String
        let type: String
        let accent: UIColor
    }

    private enum Section: Int, CaseIterable {
        case boards
        case news
        case articles

        var title: String {
            switch self {
            case .boards: return "Доски по интересам"
            case .news: return "Новости"
            case .articles: return "Статьи"
            }
        }
    }

    private let viewModel: HomeViewModel
    private let table = UITableView(frame: .zero, style: .insetGrouped)

    private let boards: [Item] = [
        Item(title: "Product Discovery", subtitle: "42 карточки · 1.2k подписчиков", type: "Доска", accent: .systemTeal),
        Item(title: "Swift Patterns", subtitle: "27 карточек · новая", type: "Доска", accent: .systemBlue)
    ]

    private let news: [Item] = [
        Item(title: "Apple обновила SwiftUI", subtitle: "Что изменилось в новых API", type: "Новость", accent: .systemOrange),
        Item(title: "AI в обучении", subtitle: "Лучшие практики 2026", type: "Новость", accent: .systemPurple)
    ]

    private let articles: [Item] = [
        Item(title: "Как строить интервальные повторения", subtitle: "7 минут чтения", type: "Статья", accent: .systemIndigo),
        Item(title: "Метрики обучения", subtitle: "5 минут чтения", type: "Статья", accent: .systemGreen)
    ]

    init(viewModel: HomeViewModel = HomeViewModel(service: HomeRepository())) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        print("DEINIT \(self)")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupTable()
    }

    private func setupTable() {
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.backgroundColor = .clear

        view.addSubview(table)
        table.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: view.topAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .boards: return boards.count
        case .news: return news.count
        case .articles: return articles.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item: Item

        switch Section(rawValue: indexPath.section) {
        case .boards: item = boards[indexPath.row]
        case .news: item = news[indexPath.row]
        case .articles: item = articles[indexPath.row]
        default: item = boards[0]
        }

        var conf = cell.defaultContentConfiguration()
        conf.text = item.title
        conf.secondaryText = item.subtitle
        conf.image = UIImage(systemName: icon(for: item.type))
        conf.imageProperties.tintColor = item.accent
        cell.contentConfiguration = conf
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    private func icon(for type: String) -> String {
        switch type {
        case "Доска": return "square.grid.2x2"
        case "Новость": return "newspaper.fill"
        default: return "doc.text"
        }
    }
}
