import UIKit

// Экран с досками пользователя (сетка)
final class BoardsViewController: UIViewController, UICollectionViewDelegateFlowLayout {
    // MARK: - Dependencies
    private let service: BoardsService // Сервис работы с бордами
    private let user: AppUser // Текущий пользователь
    private let viewModel: BoardsViewModel
    private var boards: [Board] = [] // Текущий список досок
    private var boardsById: [String: Board] = [:] // Быстрый доступ по id

    private var order: BoardsOrder = .createdAtDesc // Порядок сортировки

    private var collection: UICollectionView! // Коллекция с сеткой
    private var dataSource: UICollectionViewDiffableDataSource<Int, String>! // Diffable-источник данных

    // MARK: - Init
    /// Инициализация экрана досок.
    init(user: AppUser, service: BoardsService, viewModel: BoardsViewModel? = nil) {
        self.user = user
        self.service = service
        self.viewModel = viewModel ?? BoardsViewModel(service: service, ownerUID: user.uid)
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        print("DEINIT \(self)")
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }


    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Мои доски"
        view.backgroundColor = .systemBackground
        setupCollection()
        setupDataSource()
        setupTopBar()
        bindViewModel()
        viewModel.onViewDidLoad()
    }

    // MARK: - UI
    // Настройка коллекции и layout
    private func setupCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)
        layout.scrollDirection = .vertical

        collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .systemBackground
        collection.alwaysBounceVertical = true
        collection.keyboardDismissMode = .onDrag
        collection.delegate = self
        collection.register(BoardGridCell.self, forCellWithReuseIdentifier: BoardGridCell.reuseID)

        view.addSubview(collection)
        collection.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collection.topAnchor.constraint(equalTo: view.topAnchor),
            collection.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collection.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collection.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // Конфигурируем diffable data source
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, String>(collectionView: collection) { [weak self]
            (collectionView, indexPath, boardId) -> UICollectionViewCell? in
            guard let self else { return nil }
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: BoardGridCell.reuseID,
                for: indexPath
            ) as! BoardGridCell
            if let board = self.boardsById[boardId] {
                cell.configure(board)
            }
            return cell
        }
        applySnapshot(animated: false)
    }

    // Верхняя панель: Добавить + Переключатель сортировки
    private func setupTopBar() {
        let add = UIBarButtonItem(barButtonSystemItem: .add,
                                  target: self,
                                  action: #selector(addTapped))
        let sort = UIBarButtonItem(title: sortButtonTitle(),
                                   style: .plain,
                                   target: self,
                                   action: #selector(toggleSort))
        navigationItem.rightBarButtonItems = [add, sort]
    }

    private func sortButtonTitle() -> String { order.title }
    
    // MARK: - Actions
    @objc private func addTapped() {
        let vc = AddBoardViewController { [weak self] title, desc in
            guard let self else { return }
            Task {
                do {
                    try await self.service.createBoard(ownerUID: self.user.uid,
                                                       title: title,
                                                       description: desc)
                } catch {
                    self.showError(error)
                }
            }
        }
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }

    // Переключаем порядок сортировки и прокручиваем к началу
    @objc private func toggleSort() {
        order = order.toggled()
        if let items = navigationItem.rightBarButtonItems, items.count > 1 {
            items[1].title = order.title
        }
            
        // Скролл к началу
        let top = CGPoint(x: 0, y: -collection.adjustedContentInset.top)
        collection.setContentOffset(top, animated: false)
        resortAndApply(animated: true)
    }
        
    private func bindViewModel() {
        viewModel.onUpdate = { [weak self] list in
            guard let self else { return }
            DispatchQueue.main.async {
                self.boards = list
                self.resortAndApply(animated: true)
                self.collection.collectionViewLayout.invalidateLayout()
                self.collection.layoutIfNeeded()
            }
        }
        viewModel.onError = { [weak self] error in
            self?.showError(error)
        }
    }

    // Применяем новую сортировку и обновляем снапшот
    private func resortAndApply(animated: Bool) {
        let isDesc: Bool = {
            switch order {
            case .createdAtDesc: return true
            case .createdAtAsc:  return false
            }
        }()

        // Сортировка по дате
        boards.sort {
            let d0 = $0.createdAtClient
            let d1 = $1.createdAtClient
            return isDesc ? (d0 > d1) : (d0 < d1)
        }
        applySnapshot(animated: animated)
    }
    
    // Пересобираем снапшот для diffable data source
    private func applySnapshot(animated: Bool = true) {
        boardsById = Dictionary(uniqueKeysWithValues: boards.map { ($0.id, $0) })
        var snap = NSDiffableDataSourceSnapshot<Int, String>()
        snap.appendSections([0])
        snap.appendItems(boards.map { $0.id }, toSection: 0)
        dataSource.apply(snap, animatingDifferences: animated)
    }

    // MARK: - Layout (2 колонки)
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let total = layout.sectionInset.left + layout.sectionInset.right + layout.minimumInteritemSpacing
        let width = (collectionView.bounds.width - total) / 2.0
        return CGSize(width: floor(width), height: 110)
    }

    // Переход к карточкам выбранной доски
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let boardId = dataSource.itemIdentifier(for: indexPath),
              let board = boardsById[boardId] else { return }
        let vc = CardsViewController(user: user, board: board)
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Errors
    // Показ алерта с ошибкой
    private func showError(_ error: Error) {
        let a = UIAlertController(title: "Ошибка",
                                  message: error.localizedDescription,
                                  preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}
