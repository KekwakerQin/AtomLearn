// Экран поиска предметов
import UIKit

final class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {
    // MARK: - Dependencies
    private let viewModel: SearchViewModel

    // MARK: - UI
    private let table = UITableView() // Таблица с результатами
    private let all: [String] = ["Алгебра", "Английский", "География", "История", "Информатика", "Физика", "Химия", "Биология"] // Все предметы
    private var filtered: [String] = [] // Отфильтрованные результаты
    private let searchController = UISearchController(searchResultsController: nil) // Контроллер поиска

    // MARK: - Init
    /// Создаёт экран поиска.
    init(viewModel: SearchViewModel = SearchViewModel(service: SearchRepository())) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    // Настройка экрана и контроллера поиска
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        filtered = all

        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.frame = view.bounds
        table.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(table)

        navigationItem.searchController = searchController
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        definesPresentationContext = true

        viewModel.onViewDidLoad()
    }

    // MARK: - Search
    // Обновление результатов поиска
    func updateSearchResults(for searchController: UISearchController) {
        let q = (searchController.searchBar.text ?? "").lowercased()
        filtered = q.isEmpty ? all : all.filter { $0.lowercased().contains(q) }
        table.reloadData()
    }

    // MARK: - UITableViewDataSource
    // Количество строк = количество найденных предметов
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filtered.count }
    // Настройка ячейки таблицы
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var conf = cell.defaultContentConfiguration()
        conf.text = filtered[indexPath.row]
        cell.contentConfiguration = conf
        return cell
    }
}
