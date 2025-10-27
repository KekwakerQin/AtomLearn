import UIKit
import FirebaseFirestore

final class CardsViewController: UIViewController {
    private let board: Board
    private var cards: [Card] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let user: AppUser

    private let collection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    init(user: AppUser, board: Board) {
        self.user = user
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
        let cardsCol = db.collection("boards").document(board.id).collection("cards")

        listener = cardsCol
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    print("Listener error:", error)
                    return
                }

                guard let docs = snapshot?.documents else { return }

                let parsed = docs.compactMap { Card.initFromFirestore(id: $0.documentID, data: $0.data()) }

                self.cards = parsed.sorted { $0.createdAt < $1.createdAt }

                DispatchQueue.main.async {
                    self.collection.reloadData()
                }

                print("[CardsVC] synced cards = \(self.cards.count)")
            }
    }
    
    deinit {
        listener?.remove()
    }

    @objc private func addCard() {
        print("BOARD: \(board.id) | UID: \(user.uid)")
        let data = Card.basic(for: board.id, ownerId: user.uid)
        db.collection("boards").document(board.id)
            .collection("cards")
            .addDocument(data: data) { error in
                if let error = error {
                    print("Error adding card:", error)
                } else {
                    print("Card added successfully by \(self.user.uid)")
                }
            }
    }
}

extension CardsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cards.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let card = cards[indexPath.item]

        var conf = UIListContentConfiguration.cell()
        conf.text = card.front
        conf.secondaryText = card.back
        conf.textProperties.numberOfLines = 1
        conf.secondaryTextProperties.numberOfLines = 2
        conf.secondaryTextProperties.adjustsFontSizeToFitWidth = true

        cell.contentConfiguration = conf
        cell.layer.cornerRadius = 12
        cell.layer.borderColor = UIColor.systemGray4.cgColor
        cell.layer.borderWidth = 1
        cell.layer.masksToBounds = true
        return cell
    }
}
