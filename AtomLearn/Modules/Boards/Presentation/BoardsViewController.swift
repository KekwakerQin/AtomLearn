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
    private var createBoardCoordinator: CreateBoardCoordinator?

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
        
        navigationItem.rightBarButtonItem?.isEnabled = boards.contains {
            $0.ownerUID == user.uid || $0.editorUIDs.contains(user.uid)
        }
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
        return CGSize(width: floor(width), height: 160)
    }

    // MARK: - Navigation
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        guard let id = dataSource.itemIdentifier(for: indexPath),
              let board = boardsById[id] else { return }

        let vc = CardsViewController(user: user, board: board, viewModel: CardsViewModel())
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Context Menu (long press)
    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {

        guard let id = dataSource.itemIdentifier(for: indexPath),
              let board = boardsById[id] else { return nil }

        return UIContextMenuConfiguration(
            identifier: id as NSString,
            previewProvider: nil,
            actionProvider: { [weak self] _ in
                guard let self else { return nil }
                return self.makeBoardContextMenu(board: board)
            }
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplayContextMenu configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionAnimating?
    ) {
        // Лёгкая тактильная отдача при успешном long press
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    private func makeBoardContextMenu(board: Board) -> UIMenu {
        let edit = UIAction(title: "Изменить", image: UIImage(systemName: "pencil")) { _ in
            print("ContextMenu: Edit board", board.id)
        }

        let pin = UIAction(title: "Закрепить / открепить", image: UIImage(systemName: "pin")) { _ in
            print("ContextMenu: Pin/Unpin board", board.id)
        }

        let share = UIAction(title: "Поделиться", image: UIImage(systemName: "square.and.arrow.up")) { _ in
            print("ContextMenu: Share board", board.id)
        }

        let archive = UIAction(title: "Архивировать", image: UIImage(systemName: "archivebox")) { _ in
            print("ContextMenu: Archive board", board.id)
        }

        let settings = UIAction(title: "Настроить", image: UIImage(systemName: "gearshape")) { _ in
            print("ContextMenu: Settings board", board.id)
        }

        // Группы
        let main = UIMenu(title: "", options: .displayInline, children: [edit, pin, share])
        let secondary = UIMenu(title: "", options: .displayInline, children: [archive, settings])

        var children: [UIMenuElement] = [main, secondary]

        // ✅ Удаление только owner'у
        if board.ownerUID == user.uid {
            let delete = UIAction(
                title: "Удалить",
                image: UIImage(systemName: "trash"),
                attributes: [.destructive]
            ) { [weak self] _ in
                self?.presentDeleteConfirmation(for: board)
            }

            let danger = UIMenu(title: "", options: .displayInline, children: [delete])
            children.append(danger)
        }

        return UIMenu(children: children)
    }
    
    // MARK: - Delete
    private func presentDeleteConfirmation(for board: Board) {
        guard board.ownerUID == user.uid else {
            presentNoPermissionAlert()
            return
        }

        let alert = UIAlertController(
            title: "Удалить доску?",
            message: "Доска будет удалена. Это действие нельзя отменить.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.deleteBoard(board)
        })

        present(alert, animated: true)
    }

    private func deleteBoard(_ board: Board) {
        guard board.ownerUID == user.uid else {
            presentNoPermissionAlert()
            return
        }

        service.deleteBoard(boardId: board.id) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                // listener observeBoards сам уберёт доску из списка
                print("Board deleted:", board.id)

            case .failure(let error):
                self.showError(error)
            }
        }
    }

    private func presentNoPermissionAlert() {
        let alert = UIAlertController(
            title: "Нет прав",
            message: "Удалять доску может только владелец.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc private func addTapped() {
        let nav = UINavigationController()
        nav.modalPresentationStyle = UIModalPresentationStyle.pageSheet

        let coordinator = CreateBoardCoordinator(
            navigationController: nav,
            ownerUID: user.uid
        )
        createBoardCoordinator = coordinator

        coordinator.onFinish = { [weak self] _ in
            self?.dismiss(animated: true)
            self?.createBoardCoordinator = nil
            // observeBoards() и так подтянет изменения через listener
        }

        coordinator.onCancel = { [weak self] in
            self?.dismiss(animated: true)
            self?.createBoardCoordinator = nil
        }

        present(nav, animated: true)
        coordinator.start()
    }
    
    // MARK: - Errors
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        print(error.localizedDescription)
        present(alert, animated: true)
    }
}
