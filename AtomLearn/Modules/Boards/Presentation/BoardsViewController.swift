import UIKit
import FirebaseFirestore

// Экран с досками пользователя (сетка)
final class BoardsViewController: UIViewController, UICollectionViewDelegateFlowLayout {

    // MARK: - Dependencies
    private let service: BoardsService
    private let user: AppUser

    // MARK: - State
    private var boards: [Board] = []
    private var boardsById: [String: Board] = [:]
    private var listener: ListenerRegistration?

    // MARK: - UI
    private var collection: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, String>!

    // MARK: - Init
    init(user: AppUser, service: BoardsService) {
        self.user = user
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Мои доски"
        view.backgroundColor = .systemBackground

        setupCollection()
        setupDataSource()
        setupTopBar()
        observeBoards()
    }

    deinit {
        listener?.remove()
        print("DEINIT \(self)")
    }

    // MARK: - Firestore
    private func observeBoards() {
        listener = service.observeBoards(
            ownerUID: user.uid,
            order: .createdAtDesc // потом легко поменяем на lastActivityAt
        ) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let boards):
                self.boards = boards
                self.applySnapshot(animated: true)

            case .failure(let error):
                self.showError(error)
            }
        }
    }

    // MARK: - UI setup
    private func setupCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)

        collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .systemBackground
        collection.alwaysBounceVertical = true
        collection.delegate = self
        collection.register(BoardGridCell.self,
                            forCellWithReuseIdentifier: BoardGridCell.reuseID)

        view.addSubview(collection)
        collection.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collection.topAnchor.constraint(equalTo: view.topAnchor),
            collection.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collection.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collection.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, String>(
            collectionView: collection
        ) { [weak self] collectionView, indexPath, boardId in
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

    private func setupTopBar() {
        let add = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )
        navigationItem.rightBarButtonItem = add
    }

    // MARK: - Snapshot
    private func applySnapshot(animated: Bool) {
        boardsById = Dictionary(uniqueKeysWithValues: boards.map { ($0.id, $0) })

        var snap = NSDiffableDataSourceSnapshot<Int, String>()
        snap.appendSections([0])
        snap.appendItems(boards.map { $0.id })

        dataSource.apply(snap, animatingDifferences: animated)
    }

    // MARK: - Layout (2 колонки)
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let total = layout.sectionInset.left
                  + layout.sectionInset.right
                  + layout.minimumInteritemSpacing

        let width = (collectionView.bounds.width - total) / 2.0
        return CGSize(width: floor(width), height: 110)
    }

    // MARK: - Navigation
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        guard let id = dataSource.itemIdentifier(for: indexPath),
              let board = boardsById[id] else { return }

        let vc = CardsViewController(user: user, board: board)
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Actions
    @objc private func addTapped() {
        let vc = AddBoardViewController { [weak self] title, desc in
            guard let self else { return }

            let input = CreateBoardInput(
                title: title,
                description: desc,
                subject: "general",
                lang: "ru",
                tags: [],
                visibility: .private,
                learningIntent: .study,
                repetitionModel: .fsrs,
                examDate: nil
            )

            Task {
                do {
                    try await self.service.createBoard(
                        ownerUID: self.user.uid,
                        input: input
                    )
                } catch {
                    self.showError(error)
                }
            }
        }

        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }

    // MARK: - Errors
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
