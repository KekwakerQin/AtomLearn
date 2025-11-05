import UIKit

// Экран списка сообщений (чаты)
final class MessagesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Properties

    // Таблица с диалогами
    private let table = UITableView()
    // Тестовые данные диалогов
    private let threads = [
        ("Иван", "Привет! Как продвигается проект?"),
        ("Сеня", "Глянь PR #42, плиз"),
        ("Дима", "Подтверди схему авторизации"),
        ("HR", "Назначим созвон на завтра?")
    ]

    // MARK: - Lifecycle
    // Настройка экрана
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.frame = view.bounds
        table.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(table)
    }

    // MARK: - UITableViewDataSource
    // Количество строк = количество диалогов
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { threads.count }
    // Настройка ячейки для диалога
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var conf = cell.defaultContentConfiguration()
        // Имя собеседника
        conf.text = threads[indexPath.row].0
        // Последнее сообщение
        conf.secondaryText = threads[indexPath.row].1
        cell.contentConfiguration = conf
        // Стрелка перехода к деталям
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}
