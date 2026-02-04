import UIKit
import FirebaseFirestore
import QuickLook

// Экран карточек выбранного борда
final class CardsViewController: UIViewController {
    // MARK: - Dependencies
    private let viewModel: CardsViewModel

    // MARK: - UI
    // Текущий борд
    private var board: Board
    // Список карточек
    private var cards: [Card] = []
    private var filteredCards: [Card] = []
    private var documents: [BoardDocument] = []
    private var filteredDocuments: [BoardDocument] = []
    private var searchQuery: String = ""
    // База Firestore
    private let db = Firestore.firestore()
    // Подписка на обновления
    private var listener: ListenerRegistration?
    // Пользователь
    private let user: AppUser

    private enum Section: Int, CaseIterable {
        case info
        case cardsTitle
        case cardsSearch
        case cards
    }

    // Коллекция карточек
    private let collection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    private weak var infoHeader: BoardInfoHeaderView?
    private weak var searchHeader: CardsSearchHeaderView?
    private var isSearchEditing: Bool = false
    private var searchWorkItem: DispatchWorkItem?

    // QuickLook
    private var previewDocuments: [BoardDocument] = []
    private var previewIndex: Int = 0
    
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
        refreshDocuments()

        if board.ownerUID == user.uid || board.editorUIDs.contains(user.uid) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCard))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshDocuments()
    }

    // MARK: - UI
    // Настройка коллекции карточек
    private func setupCollection() {
        let layout = StickySectionHeaderFlowLayout()
        layout.itemSize = CGSize(width: view.frame.width - 32, height: 80)
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        layout.stickySection = Section.cardsSearch.rawValue

        collection.collectionViewLayout = layout
        collection.backgroundColor = .systemBackground
        collection.alwaysBounceVertical = true
        collection.delaysContentTouches = false
        collection.canCancelContentTouches = true
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collection.register(BoardInfoHeaderView.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: BoardInfoHeaderView.reuseID)
        collection.register(CardsTitleHeaderView.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: CardsTitleHeaderView.reuseID)
        collection.register(CardsSearchHeaderView.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: CardsSearchHeaderView.reuseID)
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
                self.applySearch()

                print("[LOG:INFO] CardsVC синхронизировал карточки: \(self.cards.count)")
            }
    }
    // MARK: - Actions
    // Добавление новой карточки в текущий борд
    @objc private func addCard() {
        let addVC = AddCardsFactory.make(boardId: board.id, boardTitle: board.title, user: user)

        navigationController?.pushViewController(addVC, animated: true)

    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension CardsViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .info:
            return 0
        case .cardsTitle:
            return 0
        case .cardsSearch:
            return 0
        case .cards:
            return filteredCards.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let card = filteredCards[indexPath.item]

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
        guard kind == UICollectionView.elementKindSectionHeader,
              let section = Section(rawValue: indexPath.section) else {
            return UICollectionReusableView()
        }

        switch section {
        case .info:
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: BoardInfoHeaderView.reuseID,
                for: indexPath
            ) as! BoardInfoHeaderView
            infoHeader = header
            header.configure(board: board, documents: visibleDocuments())
            header.onStudyTapped = { [weak self] in
                self?.presentStudyOptions()
            }
            header.onSettingsTapped = { [weak self] in
                self?.openBoardSettings()
            }
            header.onDocumentTapped = { [weak self] doc in
                self?.openDocument(doc)
            }
            header.onDocumentRename = { [weak self] doc in
                self?.renameDocument(doc)
            }
            return header
        case .cardsTitle:
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: CardsTitleHeaderView.reuseID,
                for: indexPath
            ) as! CardsTitleHeaderView
            return header
        case .cardsSearch:
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: CardsSearchHeaderView.reuseID,
                for: indexPath
            ) as! CardsSearchHeaderView
            searchHeader = header
            header.configure(query: searchQuery)
            header.onQueryChanged = { [weak self] query in
                self?.updateSearch(query)
            }
            header.onEditingEnded = { [weak self] in
                self?.isSearchEditing = false
            }
            return header
        case .cards:
            return UICollectionReusableView()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section), section == .cards else { return }
        let card = filteredCards[indexPath.item]
        collectionView.deselectItem(at: indexPath, animated: true)
        let preview = CardPreviewViewController(card: card)
        present(preview, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 32
        return CGSize(width: width, height: 80)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let section = Section(rawValue: section) else { return .zero }
        switch section {
        case .info:
            let height = BoardInfoHeaderView.preferredHeight(docCount: visibleDocuments().count)
            return CGSize(width: collectionView.bounds.width, height: height)
        case .cardsTitle:
            return CGSize(width: collectionView.bounds.width, height: CardsTitleHeaderView.preferredHeight())
        case .cardsSearch:
            return CGSize(width: collectionView.bounds.width, height: CardsSearchHeaderView.preferredHeight())
        case .cards:
            return .zero
        }
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

    private func openBoardSettings() {
        let canEdit = board.ownerUID == user.uid || board.editorUIDs.contains(user.uid)
        guard canEdit else {
            let alert = UIAlertController(
                title: "Нет доступа",
                message: "Редактировать данные может только владелец или редактор.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Ок", style: .default))
            present(alert, animated: true)
            return
        }

        let vc = BoardSettingsViewController(board: board, service: BoardsRepository())
        vc.onUpdated = { [weak self] updated in
            guard let self else { return }
            self.board = updated
            self.title = updated.title
            self.collection.reloadData()
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func refreshDocuments() {
        documents = BoardDocumentStore.shared.load(boardId: board.id)
        applySearch()
    }

    private func updateSearch(_ query: String) {
        searchQuery = query
        isSearchEditing = true
        searchWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.applySearch()
            self?.refocusSearchIfNeeded()
        }
        searchWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }

    private func applySearch() {
        let shouldRefocus = searchHeader?.isFocused ?? false
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            filteredCards = cards
            filteredDocuments = documents
        } else {
            let q = trimmed.lowercased()
            filteredCards = cards.filter {
                $0.front.lowercased().contains(q)
                || $0.back.lowercased().contains(q)
                || $0.tags.contains { $0.lowercased().contains(q) }
            }
            filteredDocuments = documents.filter {
                $0.title.lowercased().contains(q)
                || $0.fileName.lowercased().contains(q)
            }
        }

        DispatchQueue.main.async {
            self.infoHeader?.configure(board: self.board, documents: self.visibleDocuments())
            self.collection.collectionViewLayout.invalidateLayout()
            self.collection.reloadSections(IndexSet(integer: Section.cards.rawValue))
            if shouldRefocus { self.isSearchEditing = true }
            self.refocusSearchIfNeeded()
        }
    }

    private func visibleDocuments() -> [BoardDocument] {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? documents : filteredDocuments
    }

    private func openDocument(_ document: BoardDocument) {
        let docs = visibleDocuments()
        guard let index = docs.firstIndex(where: { $0.id == document.id }) else { return }
        previewDocuments = docs
        previewIndex = index
        let preview = QLPreviewController()
        preview.dataSource = self
        preview.currentPreviewItemIndex = previewIndex
        present(preview, animated: true)
    }

    private func renameDocument(_ document: BoardDocument) {
        let alert = UIAlertController(
            title: "Переименовать",
            message: "Новое название документа",
            preferredStyle: .alert
        )
        alert.addTextField { field in
            field.placeholder = "Название"
            field.text = document.title
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { [weak self] _ in
            guard let self else { return }
            let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !text.isEmpty else { return }
            if let updated = BoardDocumentStore.shared.rename(boardId: self.board.id, documentId: document.id, newTitle: text) {
                if let idx = self.documents.firstIndex(where: { $0.id == updated.id }) {
                    self.documents[idx] = updated
                }
                self.applySearch()
            }
        })
        present(alert, animated: true)
    }

    private func refocusSearchIfNeeded() {
        guard isSearchEditing else { return }
        if searchHeader?.isFocused == false {
            searchHeader?.focus()
        }
    }
}

// MARK: - QLPreviewControllerDataSource
extension CardsViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        previewDocuments.count
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        previewDocuments[index].url as NSURL
    }
}
