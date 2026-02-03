import UIKit

final class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {
    // MARK: - Dependencies
    private let viewModel: SearchViewModel

    // MARK: - UI
    private let table = UITableView(frame: .zero, style: .insetGrouped)
    private let searchController = UISearchController(searchResultsController: nil)

    private var sections: [SearchViewModel.Section] = []

    // MARK: - Init
    init(viewModel: SearchViewModel = SearchViewModel(service: SearchRepository())) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        print("DEINIT \(self)")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        enableKeyboardDismissOnTap()

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

        navigationItem.searchController = searchController
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Темы, доски, карточки"
        definesPresentationContext = true

        bind()
        viewModel.onViewDidLoad()
    }

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            self?.sections = state.sections
            self?.table.reloadData()
        }
    }

    // MARK: - Search
    func updateSearchResults(for searchController: UISearchController) {
        let q = searchController.searchBar.text ?? ""
        viewModel.updateQuery(q)
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]

        var conf = cell.defaultContentConfiguration()
        conf.text = item.title
        conf.secondaryText = item.subtitle
        conf.image = UIImage(systemName: icon(for: item.kind))
        conf.imageProperties.tintColor = color(for: item.kind)
        cell.contentConfiguration = conf
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    private func icon(for kind: SearchViewModel.Item.Kind) -> String {
        switch kind {
        case .board: return "square.grid.2x2"
        case .card: return "rectangle.portrait.on.rectangle.portrait"
        case .article: return "doc.text"
        case .tag: return "number"
        }
    }

    private func color(for kind: SearchViewModel.Item.Kind) -> UIColor {
        switch kind {
        case .board: return .systemBlue
        case .card: return .systemTeal
        case .article: return .systemOrange
        case .tag: return .systemPurple
        }
    }
}
