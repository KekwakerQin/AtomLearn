import UIKit

protocol BoardListViewProtocol: AnyObject {
    func showBoards(_ boards: [Board])
    func showError(_ error: Error)
}

final class BoardListViewController: UIViewController {
    
    let user = SessionManager.shared.currentUser
    
    private let tableView = UITableView()
    private let addBoardButton: UIButton = UIButton.standart(title: "Add some Board")
    private let deleteBoardButton: UIButton = UIButton.standart(title: "Delete all Boards")
    
    private var presenter: BoardListPresenterProtocol
    
    private var boards: [Board] = []
    
    init(presenter: BoardListPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BoardCell")
        
        setupView()
        setupHierarchy()
        setupLayout()
        setupAction()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presenter.viewWillDisappear()
    }
    
    // MARK: - Setup 

    private func setupView() {
        view = UIView.setupView(view: view)
        addBoardButton.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupHierarchy() {
        view.addSubview(tableView)
        view.addSubview(addBoardButton)
        view.addSubview(deleteBoardButton)
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            addBoardButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addBoardButton.heightAnchor.constraint(equalToConstant: 44),
            addBoardButton.bottomAnchor.constraint(equalTo: deleteBoardButton.topAnchor, constant: -20),
                // Адаптивная ширина
            addBoardButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),

                // Минимум и максимум (если надо)
            addBoardButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            addBoardButton.widthAnchor.constraint(lessThanOrEqualToConstant: 320),
            
            deleteBoardButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deleteBoardButton.heightAnchor.constraint(equalToConstant: 44),
            deleteBoardButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

                // Адаптивная ширина
            deleteBoardButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),

                // Минимум и максимум (если надо)
            deleteBoardButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            deleteBoardButton.widthAnchor.constraint(lessThanOrEqualToConstant: 320),

        ])
    }
    
    private func setupAction() {
        addBoardButton.addTarget(self, action: #selector(addBoardInDatabase), for: .touchUpInside)
        deleteBoardButton.addTarget(self, action: #selector(didDeleteBoardInDatabase), for: .touchUpInside)
    }
    
    // MARK: - Actions

    @objc private func addBoardInDatabase() {
        print("Tapped")
        presenter.didTapCreateButton()
    }
    
    @objc private func didDeleteBoardInDatabase() {
        print("Tapped")
        presenter.didTapDeleteButton()
    }
}

// MARK: - BoardListViewController: Protocol

extension BoardListViewController: BoardListViewProtocol {
    func showBoards(_ boards: [Board]) {
        print("Получено досок: \(boards.count)")
        self.boards = boards
        tableView.reloadData()
    }

    func showError(_ error: Error) {
        let alert = UIAlertController(title: "Error",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - BoardListViewController: UITableView, DataSource

extension BoardListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("Количество строк в секции: \(boards.count)")
        return boards.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BoardCell")
                 ?? UITableViewCell(style: .subtitle, reuseIdentifier: "BoardCell")
        let board = boards[indexPath.row]
        cell.textLabel?.text = board.title
        cell.detailTextLabel?.text = board.description
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter.didSelectBoard(boards[indexPath.row])
    }
}

