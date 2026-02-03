import UIKit

final class AddEntityViewController: UIViewController, UISearchBarDelegate {

    // MARK: - Dependencies
    private let viewModel: AddEntityViewModel

    // MARK: - UI
    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)


    // MARK: - Sections
    private enum Section {
        static let actions = 0
        static let boardsOffset = 1
    }


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
        enableKeyboardDismissOnTap()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareForAppearanceAnimation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateAppearance()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let header = tableView.tableHeaderView else { return }
        let targetSize = CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let size = header.systemLayoutSizeFitting(targetSize)
        if header.frame.height != size.height {
            header.frame.size.height = size.height
            tableView.tableHeaderView = header
        }
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
        tableView.register(AddEntityActionCell.self, forCellReuseIdentifier: AddEntityActionCell.reuseID)
        tableView.register(AddEntityBoardCell.self, forCellReuseIdentifier: AddEntityBoardCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64

        view.addSubview(searchBar)
        view.addSubview(tableView)
        tableView.tableHeaderView = makeHeader()

        searchBar.placeholder = "Найти доску"
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

    private func makeHeader() -> UIView {
        let container = UIView()

        let title = UILabel()
        title.text = "Что добавим?"
        let baseTitleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        if let roundedDescriptor = baseTitleFont.fontDescriptor.withDesign(UIFontDescriptor.SystemDesign.rounded) {
            // size: 0 keeps the size from the descriptor
            title.font = UIFont(descriptor: roundedDescriptor, size: 0)
        } else {
            title.font = baseTitleFont
        }

        let subtitle = UILabel()
        subtitle.text = "Выбери действие или доску"
        subtitle.font = .systemFont(ofSize: 13, weight: .medium)
        subtitle.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [title, subtitle])
        stack.axis = .vertical
        stack.spacing = 6
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = .init(top: 8, leading: 16, bottom: 8, trailing: 16)

        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        container.layoutIfNeeded()
        let size = container.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        )
        container.frame = CGRect(origin: .zero, size: size)
        return container
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

        if indexPath.section == Section.actions {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: AddEntityActionCell.reuseID,
                for: indexPath
            ) as! AddEntityActionCell

            switch indexPath.row {
            case 0:
                cell.configure(title: "Новая доска", subtitle: "Создай доску под тему или проект", icon: "plus", color: .systemBlue)
            case 1:
                cell.configure(title: "Новость", subtitle: "Добавь статью или новость", icon: "newspaper.fill", color: .systemOrange)
            default:
                cell.configure(title: "Канал", subtitle: "Добавь источник с обновлениями", icon: "dot.radiowaves.left.and.right", color: .systemPurple)
            }
            cell.accessoryType = .disclosureIndicator
            return cell
        } else {
            let key = viewModel.state.sortedKeys[indexPath.section - Section.boardsOffset]
            let board = viewModel.state.groupedBoards[key]![indexPath.row]
            let cell = tableView.dequeueReusableCell(
                withIdentifier: AddEntityBoardCell.reuseID,
                for: indexPath
            ) as! AddEntityBoardCell
            cell.configure(board: board)
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }

    func tableView(_ tableView: UITableView,
                   titleForHeaderInSection section: Int) -> String? {
        guard section != Section.actions else { return nil }
        return viewModel.state.sortedKeys[section - Section.boardsOffset]
    }
}
