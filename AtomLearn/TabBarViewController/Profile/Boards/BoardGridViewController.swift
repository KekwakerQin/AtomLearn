import UIKit
import FirebaseAuth
import FirebaseFirestore

final class BoardsGridViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let service: BoardsService
    private var boards: [Board] = []
    private var listener: ListenerRegistration?

    private var collection: UICollectionView!

    init(service: BoardsService) { self.service = service; super.init(nibName: nil, bundle: nil) }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
    deinit { listener?.remove() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupCollection()
        setupAddButton()
        startObserving()
    }

    private func setupCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)
        layout.scrollDirection = .vertical

        collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .systemBackground
        collection.alwaysBounceVertical = true    // bounce при малом контенте
        collection.keyboardDismissMode = .onDrag
        collection.dataSource = self
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

    private func setupAddButton() {
        // кнопка «плюс» в правом верхнем углу
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(addTapped))
    }

    @objc private func addTapped() {
        let vc = AddBoardViewController { [weak self] title, desc in
            guard let self else { return }
            let uid = Auth.auth().currentUser?.uid ?? "mock-user"
            Task {
                do { try await self.service.createBoard(ownerUID: uid, title: title, description: desc) }
                catch { self.showError(error) }
            }
        }
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }

    private func startObserving() {
        let uid = Auth.auth().currentUser?.uid ?? "mock-user"
        listener = service.observeBoards(ownerUID: uid) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let list):
                self.boards = list
                self.collection.reloadData()
            case .failure(let e):
                self.showError(e)
            }
        }
    }

    // MARK: DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { boards.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BoardGridCell.reuseID, for: indexPath) as! BoardGridCell
        cell.configure(boards[indexPath.item]); return cell
    }

    // MARK: Layout (2 столбца)
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let inset = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).sectionInset
        let spacing = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing
        let total = inset.left + inset.right + spacing
        let w = (collectionView.bounds.width - total) / 2.0
        return CGSize(width: floor(w), height: 110)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let board = boards[indexPath.item]
        let vc = CardsViewController(board: board)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showError(_ error: Error) {
        let a = UIAlertController(title: "Ошибка", message: error.localizedDescription, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default)); present(a, animated: true)
    }
}
