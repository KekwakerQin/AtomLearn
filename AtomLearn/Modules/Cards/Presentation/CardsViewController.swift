import UIKit
import FirebaseFirestore

// Экран карточек выбранного борда
final class CardsViewController: UIViewController {
    // MARK: - Dependencies
    private let viewModel: CardsViewModel

    // MARK: - UI
    // Текущий борд
    private let board: Board
    // Список карточек
    private var cards: [Card] = []
    // База Firestore
    private let db = Firestore.firestore()
    // Подписка на обновления
    private var listener: ListenerRegistration?
    // Пользователь
    private let user: AppUser

    // Коллекция карточек
    private let collection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    /// Инициализация с пользователем и бордом.
    init(user: AppUser, board: Board, viewModel: CardsViewModel = CardsViewModel(service: CardsRepository())) {
        self.user = user
        self.board = board
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Lifecycle
    // Настройка интерфейса и запуск наблюдения
    override func viewDidLoad() {
        super.viewDidLoad()
        title = board.title
        view.backgroundColor = .systemBackground

        setupCollection()
        observeCards()
        viewModel.onViewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCard))
    }

    // MARK: - UI
    // Настройка коллекции карточек
    private func setupCollection() {
        // Конфигурация layout для карточек
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

    // MARK: - Data
    // Подписка на изменения карточек в Firestore
    private func observeCards() {
        let cardsCol = db.collection("boards").document(board.id).collection("cards")

        listener = cardsCol
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    print("[LOG:ERROR] Ошибка слушателя: \(error.localizedDescription)")
                    return
                }

                guard let docs = snapshot?.documents else { return }

                let parsed = docs.compactMap { Card.initFromFirestore(id: $0.documentID, data: $0.data()) }

                self.cards = parsed.sorted { $0.createdAt < $1.createdAt }

                DispatchQueue.main.async {
                    self.collection.reloadData()
                }

                print("[LOG:INFO] CardsVC синхронизировал карточки: \(self.cards.count)")
            }
    }
    
    // Отписка от слушателя при деинициализации
    deinit {
        listener?.remove()
    }

    // MARK: - Actions
    // Добавление новой карточки в текущий борд
    @objc private func addCard() {
        print("BOARD: \(board.id) | UID: \(user.uid)")
        let data = Card.basic(for: board.id, ownerId: user.uid)
        db.collection("boards").document(board.id)
            .collection("cards")
            .addDocument(data: data) { error in
                if let error = error {
                    print("[LOG:ERROR] Ошибка при добавлении карточки: \(error.localizedDescription)")
                } else {
                    print("[LOG:INFO] Карточка успешно добавлена пользователем \(self.user.uid)")
                }
            }
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate
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
