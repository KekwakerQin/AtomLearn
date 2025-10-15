import UIKit

final class CardsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let table = UITableView()
    private var items: [String] = (1...20).map { "Карточка \($0)" }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Карточки"
        view.backgroundColor = .systemBackground

        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.frame = view.bounds
        table.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(table)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var conf = cell.defaultContentConfiguration()
        conf.text = items[indexPath.row]
        conf.secondaryText = "Описание карточки"
        cell.contentConfiguration = conf
        return cell
    }
}
