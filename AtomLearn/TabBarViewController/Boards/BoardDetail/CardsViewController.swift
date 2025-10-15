import UIKit
import FirebaseFirestore

final class BoardDetailViewController: UIViewController {
    private let board: Board
    private var cards: [Card] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private let collection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    init(board: Board) {
        self.board = board
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = board.title
        view.backgroundColor = .systemBackground

        setupCollection()
        observeCards()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCard))
    }

    private func setupCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.width - 40, height: 80)
        layout.minimumLineSpacing = 16

        collection.collectionViewLayout = layout
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collection.dataSource = self
        collection.delegate = self
        collection.frame = view.bounds
        collection.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collection)
    }

    private func observeCards() {
        listener = db.collection("boards").document(board.id)
            .collection("cards")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let docs = snap?.documents {
                    self.cards = docs.map { Card(id: $0.documentID, title: $0["title"] as? String ?? "", description: $0["description"] as? String ?? "") }
                    self.collection.reloadData()
                }
            }
    }

    @objc private func addCard() {
        let sheet = AddEntityViewController(service: FirebaseBoardsService()) { [weak self] in
            self?.collection.reloadData()
        }
        sheet.modalPresentationStyle = .pageSheet
        if let sp = sheet.presentationController as? UISheetPresentationController {
            sp.detents = [.medium(), .large()]
            sp.prefersGrabberVisible = true
        }
        present(sheet, animated: true)
    }

    deinit {
        listener?.remove()
    }
}

extension BoardDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { cards.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let card = cards[indexPath.item]

        var conf = UIListContentConfiguration.cell()
        conf.text = card.title
        conf.secondaryText = card.description
        cell.contentConfiguration = conf
        cell.layer.cornerRadius = 12
        cell.layer.borderColor = UIColor.systemGray4.cgColor
        cell.layer.borderWidth = 1
        return cell
    }
}
