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
    init(user: AppUser, board: Board, viewModel: CardsViewModel) {
        self.user = user
        self.board = board
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        print("DEINIT \(self)")
        listener?.remove()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Lifecycle
    // Настройка интерфейса и запуск наблюдения
    override func viewDidLoad() {
        print("CardsVC VM (from vc):", ObjectIdentifier(viewModel))
        
        super.viewDidLoad()
        title = board.title
        view.backgroundColor = .systemBackground

        setupCollection()
        observeCards()
        viewModel.onViewDidLoad()

        if board.ownerUID == user.uid || board.editorUIDs.contains(user.uid) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCard))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    // MARK: - UI
    // Настройка коллекции карточек
    private func setupCollection() {
        // Конфигурация layout для карточек
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.width - 40, height: 80)
        layout.minimumLineSpacing = 16
        layout.headerReferenceSize = CGSize(width: view.frame.width, height: 190)

        collection.collectionViewLayout = layout
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collection.register(BoardInfoHeaderView.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: BoardInfoHeaderView.reuseID)
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
    // MARK: - Actions
    // Добавление новой карточки в текущий борд
    @objc private func addCard() {
        let addVC = AddCardsFactory.make(boardId: board.id, user: user)

        navigationController?.pushViewController(addVC, animated: true)
        //        print("PLUS TAP")
        //        viewModel.didTapAddCard()
    }
// СТАРОЕ - Если не сработает - вернуть
//    @objc private func addCard() {
//        print("BOARD: \(board.id) | UID: \(user.uid)")
//        let data = Card.basic(for: board.id, ownerId: user.uid)
//        db.collection("boards").document(board.id)
//            .collection("cards")
//            .addDocument(data: data) { error in
//                if let error = error {
//                    print("[LOG:ERROR] Ошибка при добавлении карточки: \(error.localizedDescription)")
//                } else {
//                    print("[LOG:INFO] Карточка успешно добавлена пользователем \(self.user.uid)")
//                }
//            }
//    }
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
        conf.secondaryText = card.tags.isEmpty ? "Тап, чтобы открыть" : card.tags.map { "#\($0)" }.joined(separator: " ")
        conf.textProperties.numberOfLines = 1
        conf.secondaryTextProperties.numberOfLines = 1
        conf.secondaryTextProperties.adjustsFontSizeToFitWidth = true

        cell.contentConfiguration = conf
        cell.layer.cornerRadius = 12
        cell.layer.borderColor = UIColor.systemGray4.cgColor
        cell.layer.borderWidth = 1
        cell.layer.masksToBounds = true
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: BoardInfoHeaderView.reuseID,
            for: indexPath
        ) as! BoardInfoHeaderView
        header.configure(board: board)
        header.onStudyTapped = { [weak self] in
            self?.presentStudyOptions()
        }
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let card = cards[indexPath.item]
        let vc = CardDetailViewController(card: card)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func presentStudyOptions() {
        guard !cards.isEmpty else {
            let alert = UIAlertController(title: "Нет карточек", message: "Добавь карточки, чтобы начать сессию.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ок", style: .default))
            present(alert, animated: true)
            return
        }

        let sheet = UIAlertController(title: "Учиться по доске", message: "Как собрать порядок?", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "По актуальности", style: .default) { [weak self] _ in
            self?.startStudy(order: .recent)
        })
        sheet.addAction(UIAlertAction(title: "Все вперемешку", style: .default) { [weak self] _ in
            self?.startStudy(order: .shuffle)
        })
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(sheet, animated: true)
    }

    private func startStudy(order: StudySessionState.Order) {
        let store = StudySessionStore.shared
        if let existing = store.loadActiveSession(boardId: board.id) {
            let alert = UIAlertController(
                title: "Есть незавершённая сессия",
                message: "Продолжить или начать заново?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Продолжить", style: .default) { [weak self] _ in
                self?.openStudy(state: existing)
            })
            alert.addAction(UIAlertAction(title: "Заново", style: .destructive) { [weak self] _ in
                self?.openStudy(state: self?.makeNewState(order: order))
            })
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            present(alert, animated: true)
        } else {
            openStudy(state: makeNewState(order: order))
        }
    }

    private func makeNewState(order: StudySessionState.Order) -> StudySessionState {
        let orderedCards: [Card]
        switch order {
        case .recent:
            orderedCards = cards.sorted { $0.updatedAt > $1.updatedAt }
        case .shuffle:
            orderedCards = cards.shuffled()
        }

        let snapshots = orderedCards.map {
            StudyCardSnapshot(id: $0.id, front: $0.front, back: $0.back)
        }

        let state = StudySessionState.new(boardId: board.id, boardTitle: board.title, order: order, cards: snapshots)
        StudySessionStore.shared.save(state: state)
        return state
    }

    private func openStudy(state: StudySessionState?) {
        guard let state else { return }
        let vc = StudySessionViewController(state: state, boardTitle: board.title)
        navigationController?.pushViewController(vc, animated: true)
    }
}
