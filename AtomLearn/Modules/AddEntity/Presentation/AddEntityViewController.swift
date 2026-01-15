import UIKit

final class AddEntityViewController: UIViewController, UISearchBarDelegate {

    // MARK: - Dependencies
    private let viewModel: AddEntityViewModel

    // MARK: - UI
    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    private final class WeakTarget: NSObject {
        weak var owner: AddEntityViewController?
        init(owner: AddEntityViewController) { self.owner = owner }
        @objc func handleTap() { owner?.dismissKeyboard() }
    }

    private lazy var weakTapTarget = WeakTarget(owner: self)


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
    
    deinit {
        print("DEINIT \(self)")
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareForAppearanceAnimation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateAppearance()
    }

    // MARK: - UI

    private func prepareForAppearanceAnimation() {
        let offset: CGFloat = 20

        searchBar.alpha = 0
        searchBar.transform = CGAffineTransform(translationX: 0, y: -offset)

        tableView.alpha = 0
        tableView.transform = CGAffineTransform(translationX: 0, y: -offset / 2)
    }

    private func animateAppearance() {

        // 1) SearchBar — появляется быстрее
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                self.searchBar.alpha = 1
                self.searchBar.transform = .identity
            }
        )

        // 2) TableView — плавнее и чуть позже
        UIView.animate(
            withDuration: 0.45,
            delay: 0.08,
            options: [.curveEaseOut],
            animations: {
                self.tableView.alpha = 1
                self.tableView.transform = .identity
            }
        )
    }
    private func setupUI() {
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Отмена",
            style: .plain,
            target: self,
            action: #selector(close)
        )

        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellID)

        view.addSubview(searchBar)
        view.addSubview(tableView)

        let tap = UITapGestureRecognizer(target: weakTapTarget,
                                         action: #selector(WeakTarget.handleTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

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
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - Actions
    @objc private func close() {
        viewModel.didTapClose()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension AddEntityViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 + viewModel.state.sortedKeys.count
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
                   didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == Section.actions {
            switch indexPath.row {
            case 0:
                // ➕ Добавить доску
                viewModel.didTapCreateBoard()
            case 1:
                // 📰 Добавить новость (пока заглушка)
                break
            case 2:
                // 📣 Добавить канал (пока заглушка)
                break
            default:
                break
            }
            return
        }

        let key = viewModel.state.sortedKeys[indexPath.section - Section.boardsOffset]
        guard
            let boards = viewModel.state.groupedBoards[key],
            indexPath.row < boards.count
        else { return }

        let board = boards[indexPath.row]
        viewModel.didSelectBoard(board)
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
