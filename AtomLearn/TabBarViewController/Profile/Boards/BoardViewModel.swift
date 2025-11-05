import FirebaseFirestore

// ViewModel для управления списком досок
final class BoardsViewModel {
    // MARK: - Properties
    private let service: BoardsService // Сервис для работы с Firestore
    private let ownerUID: String // UID владельца досок
    private var listener: ListenerRegistration? // Слушатель обновлений
    private(set) var boards: [Board] = [] // Текущий список досок
    private(set) var order: BoardsOrder = .createdAtDesc // Порядок сортировки

    // Коллбэки для обновления UI и ошибок
    var onUpdate: (([Board]) -> Void)?
    var onError: ((Error) -> Void)?
    var onOrderChanged: ((BoardsOrder) -> Void)?

    // MARK: - Init
    // Инициализация с зависимостями
    init(service: BoardsService, ownerUID: String) {
        self.service = service
        self.ownerUID = ownerUID
    }

    // Удаляем слушателя при деинициализации
    deinit {
        listener?.remove()
    }

    // MARK: - Data
    // Запускаем наблюдение за досками
    func start() {
        listener?.remove()
        listener = service.observeBoards(ownerUID: ownerUID, order: order) { [weak self] result in
            guard let self else { return }
            // Обрабатываем результат из Firestore
            switch result {
            case .success(let boards):
                self.boards = boards
                self.onUpdate?(boards)
            case .failure(let error):
                self.onError?(error)
            }
        }
    }

    // MARK: - Actions
    // Переключение порядка сортировки и перезапуск слушателя
    func toggleSort() {
        order = (order == .createdAtDesc) ? .createdAtAsc : .createdAtDesc
        start()
        onOrderChanged?(order)
    }
}
