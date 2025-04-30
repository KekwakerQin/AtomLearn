import RxSwift
import Firebase

final class CardPreloadManager {
    
    static let shared = CardPreloadManager()
    
    private let boardService  = BoardService()
    private let cardService   = BoardDetailService()
    private let cache         = CardCacheManager()
    private let bag           = DisposeBag()
    
    private var backgroundQueue   = [String]()       // boardIDs «на потом»
    private var prioritizedBoard: String?            // boardID c приоритетом
    private var isWorking = false                    // сейчас что-то грузим?
    private var batchSize = 10                       // сколько «чуть-чуть»
    
    private var fullyLoadedBoardIDs: Set<String> = [] // флаг
    private var lastSnapshots = [String: DocumentSnapshot]()
    
    private var allBoards: [String: Board] = [:] // boardID: Board
    
    private var listeners: [String: ListenerRegistration] = [:]
    
    
    private init() {}
    
    // вызываем один раз при авторизации
    func startBackgroundPreload(for userID: String) {
        guard backgroundQueue.isEmpty else { return }
        boardService.fetchBoards(for: userID)
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .utility)) // Переносим на утилиту бекграунд
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] boards in
                self?.allBoards = Dictionary(uniqueKeysWithValues: boards.map { ($0.boardID, $0) })
                self?.backgroundQueue = boards.map(\.boardID)
                let title = boards.map {$0.title}
                print("Очередь предзагрузки: \(self?.backgroundQueue ?? [])") // добавлено
                print("Названия бордов: \(title)")
                self?.tick()                    // пускаем первую задачу
            })
            .disposed(by: bag)
    }
    
    func subscribeToBoard(_ boardID: String) {
        // Defender: если уже слушаем этот борд - не подписываемся второй раз
        guard listeners[boardID] == nil else { return }
        
        let listener = FirestorePaths.cardsCollection(forBoard: boardID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                do {
                    let fetched = try documents.map { try $0.data(as: Card.self) }

                    let cachedIDs = Set(self.cache.getCachedCards(for: boardID).map(\.id))
                    let newCards  = fetched.filter { !cachedIDs.contains($0.id) }
                    
                    guard !newCards.isEmpty else { return }
                    
                    print("Пришло \(newCards.count) новых карт для \(allBoards[boardID]!.title)")
                    self.cache.cacheCards(newCards)
                } catch {
                    print(error.localizedDescription)
                }
            }
        listeners[boardID] = listener
    }
    
    // очищенный кэш мы подгружаем данные снова
    func restartPreloading(for userID: String) {
        resetQueue()
        startBackgroundPreload(for: userID)
    }
    
    // отписки от слушателей
    func unsubscribeFromAllBoards() {
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // когда пользователь открыл борд
    func focus(on boardID: String) {
        prioritizedBoard = boardID
        tick()                                   // если ничего не качаем — начнём
    }
    
    func resetQueue() {
        unsubscribeFromAllBoards()
        backgroundQueue.removeAll()
        prioritizedBoard = nil
        isWorking = false
        fullyLoadedBoardIDs.removeAll()
        lastSnapshots.removeAll()        
    }
    
    // вызываем, когда пользователь ушёл с борда
    func defocus() {
        prioritizedBoard = nil
        tick()
    }
    
    // MARK: scheduler
    private func tick() {
        guard !isWorking else { return }
        
        if let boardID = prioritizedBoard {
            guard !fullyLoadedBoardIDs.contains(boardID) else {
                print("\(boardID) весь готов\n")
                return
            }
            
            isWorking = true
            loadRemainingCards(for: boardID) { [weak self] in
                self?.isWorking = false
                self?.tick()
            }
            
        } else if let boardID = backgroundQueue.first {
            backgroundQueue.removeFirst()
            
            guard !fullyLoadedBoardIDs.contains(boardID) else {
                print(("Загружен полностью: \(boardID)"))
                self.tick()
                return
            }
            
            isWorking = true
            loadBatch(for: boardID) { [weak self] in
                self?.backgroundQueue.append(boardID)
                self?.isWorking = false
                self?.tick()
            }
        }
    }
    
    // MARK: Loading helpers
    // грузим 10 карточек (или меньше, если осталось мало)
    private func loadBatch(for boardID: String, completion: @escaping () -> Void) {
        
        let title = allBoards[boardID]?.title ?? boardID
        print("\nПодгружаем с: \(title)")
        
        let qosClass: DispatchQoS.QoSClass =
        (boardID == prioritizedBoard) ? .userInitiated : .utility
        let priority = DispatchQoS(qosClass: qosClass, relativePriority: 0)
        
        let startAfterDoc = lastSnapshots[boardID]           // «хвост» предыдущей стр.
        
        cardService
            .fetchCards(for: boardID,
                        limit: batchSize,
                        startAfter: startAfterDoc)
        // превращаем кортеж ➜ только новые карточки
            .map { cards, newSnapshot -> [Card] in
                if let snap = newSnapshot {                  // запомнить для next page
                    self.lastSnapshots[boardID] = snap
                }
                let cachedIDs = Set(self.cache
                    .getCachedCards(for: boardID)
                    .map(\.id))
                let fresh = cards.filter { !cachedIDs.contains($0.id) }
                
                print("Из \(cards.count) карт новые: \(fresh.count)")
                print("Названия: \(fresh.map(\.term))")
                return fresh
            }
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: priority))
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] fresh in
                    guard let self = self else { return }
                    self.cache.cacheCards(fresh)
                    print("Подгружено \(fresh.count) карт для \(title)")
                    
                    if fresh.count < self.batchSize {        // последняя страница
                        self.fullyLoadedBoardIDs.insert(boardID)
                    }
                    completion()
                },
                onFailure: { error in
                    print("Batch-error: \(error.localizedDescription)")
                    completion()
                })
            .disposed(by: bag)
    }
    
    // грузим все карточки, которых ещё нет в кэше
    private func loadRemainingCards(for boardID: String,
                                    completion: @escaping () -> Void) {
        
        let already = Set(cache.getCachedCards(for: boardID).map(\.id))
        
        cardService
            .fetchCards(for: boardID,
                        limit: nil,               // вся коллекция
                        startAfter: nil)          // с самого начала
            .map { tuple -> [Card] in
                let (cards, _) = tuple           // берём массив, snapshot не нужен
                return cards.filter { !already.contains($0.id) }
            }
            .subscribe(
                onSuccess: { [weak self] fresh in
                    guard let self = self else { return }
                    
                    self.cache.cacheCards(fresh)
                    print("Оставшихся карт: \(fresh.count)")
                    
                    // если ничего нового – всё загружено
                    if fresh.isEmpty {
                        self.fullyLoadedBoardIDs.insert(boardID)
                        print("Борд \(self.allBoards[boardID]?.title ?? boardID) полностью загружен (остаток)")
                    }
                    completion()
                },
                onFailure: { error in
                    print("Preload-remaining error: \(error.localizedDescription)")
                    completion()
                })
            .disposed(by: bag)
    }
}
