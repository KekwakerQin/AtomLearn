import FirebaseFirestore

/// ViewModel для управления списком досок.
final class BoardsViewModel {
    // MARK: - Dependencies
    private let service: BoardsService
    private let ownerUID: String
    private var listener: ListenerRegistration?

    // MARK: - Public API
    /// Текущий список досок.
    private(set) var boards: [Board] = []
    /// Текущий порядок сортировки.
    private(set) var order: BoardsOrder = .createdAtDesc
    /// Коллбэк обновления данных.
    var onUpdate: (([Board]) -> Void)?
    /// Коллбэк ошибок.
    var onError: ((Error) -> Void)?
    /// Коллбэк смены сортировки.
    var onOrderChanged: ((BoardsOrder) -> Void)?

    // MARK: - Init
    /// Инициализация с зависимостями.
    init(service: BoardsService, ownerUID: String) {
        self.service = service
        self.ownerUID = ownerUID
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Lifecycle
    /// Обрабатывает событие загрузки экрана.
    func onViewDidLoad() {
        start()
    }

    // MARK: - Actions
    /// Переключает порядок сортировки и перезапускает слушатель.
    func toggleSort() {
        order = (order == .createdAtDesc) ? .createdAtAsc : .createdAtDesc
        start()
        onOrderChanged?(order)
    }

    // MARK: - Public API
    /// Запускает наблюдение за досками.
    func start() {
        listener?.remove()
        listener = service.observeBoards(ownerUID: ownerUID, order: order) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let boards):
                self.boards = boards
                self.onUpdate?(boards)
            case .failure(let error):
                self.onError?(error)
            }
        }
    }
}
