import UIKit

final class AddEntityViewController: UIViewController, UISearchBarDelegate {

    // MARK: - Dependencies
    private let viewModel: AddEntityViewModel

    // MARK: - UI
    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: - Sections
    private enum Section {
        static let actions = 0
        static let boardsOffset = 1
    }

    private static let cellID = "AddEntityCell"

    // MARK: - Init
    init(viewModel: AddEntityViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
        viewModel.onViewDidLoad()
    }

    // MARK: - UI
    private func setupUI() {
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Отмена",
            style: .plain,
            target: self,
            action: #selector(close)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Создать карточки",
            style: .done,
            target: self,
            action: #selector(createCards)
        )

        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellID)

        view.addSubview(searchBar)
        view.addSubview(tableView)

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Binding
    private func bind() {
        viewModel.onStateChange = { [weak self] _ in
            self?.tableView.reloadData()
        }
    }

    // MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar,
                   textDidChange searchText: String) {
        viewModel.updateSearch(text: searchText)
    }
    
    // MARK: - Actions
    @objc private func close() {
        dismiss(animated: true)
    }

    @objc private func createCards() {
        // дальше координатор
    }
}

extension AddEntityViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        Section.boardsOffset + viewModel.state.sortedKeys.count
    }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        if section == Section.actions {
            return 3
        }

        let key = viewModel.state.sortedKeys[section - Section.boardsOffset]
        return viewModel.state.groupedBoards[key]?.count ?? 0
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.cellID,
            for: indexPath
        )

        if indexPath.section == Section.actions {
            let titles = [
                "➕ Добавить доску",
                "📰 Добавить новость",
                "📣 Добавить канал"
            ]
            cell.textLabel?.text = titles[indexPath.row]
            cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            cell.accessoryType = .disclosureIndicator
        } else {
            let key = viewModel.state.sortedKeys[indexPath.section - Section.boardsOffset]
            let board = viewModel.state.groupedBoards[key]![indexPath.row]
            cell.textLabel?.text = board.title
            cell.textLabel?.font = .systemFont(ofSize: 15)
            cell.accessoryType = .none
        }

        return cell
    }

    func tableView(_ tableView: UITableView,
                   titleForHeaderInSection section: Int) -> String? {
        guard section != Section.actions else { return nil }
        return viewModel.state.sortedKeys[section - Section.boardsOffset]
    }
}
