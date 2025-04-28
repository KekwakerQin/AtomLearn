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
    
    private var listeners: [String: ListenerRegistration] = [:]
    
    private init() {}

    // вызываем один раз при авторизации
    func startBackgroundPreload(for userID: String) {
        guard backgroundQueue.isEmpty else { return }
        boardService.fetchBoards(for: userID)
            .subscribe(onSuccess: { [weak self] boards in
                self?.backgroundQueue = boards.map(\.boardID)
                print("Очередь предзагрузки: \(self?.backgroundQueue ?? [])") // добавлено

                self?.tick()                    // пускаем первую задачу
            })
            .disposed(by: bag)
    }
    
    func subscribeToBoard(_ boardID: String) {
        // Defender: если уже слушаем этот борд - не подписываемся второй раз
        guard listeners[boardID] == nil else { return }
        
        let listener = FirestorePaths.cardsCollection(forBoard: boardID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                do {
                    let cards = try documents.map { try $0.data(as: Card.self) }
                    print("Пришла новая карта в boardID: \(boardID), получена: \(cards.count)")
                    self?.cache.cacheCards(cards)
                } catch {
                    print("Ошибка чтения карт")
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
        backgroundQueue = []
        prioritizedBoard = nil
        isWorking = false
        fullyLoadedBoardIDs.removeAll() // flags cleared
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
                print("\(boardID) весь готов")
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
        print("Подгружаем с: \(boardID)")
        let cachedIDs = Set(cache.getCachedCards(for: boardID).map(\.id))
        
        cardService.fetchCards(for: boardID, limit: batchSize)
            .map { fetched in
                // фильтруем только новые
                fetched.filter { !cachedIDs.contains($0.id) }
            }
            .subscribe(onSuccess: { [weak self] newCards in
                guard let self = self else { return }
                print("Подгружено \(newCards.count) новых карточек для boardID: \(boardID)")
                self.cache.cacheCards(newCards)
                
                if newCards.isEmpty {
                    print("Борд \(boardID) полностью загружен (batch-фильтр)")
                    self.fullyLoadedBoardIDs.insert(boardID)
                }
                
                completion()
            }, onFailure: { error in
                print("Ошибка при batch-загрузке: \(error.localizedDescription)")
                completion()
            })
            .disposed(by: bag)
    }

    // грузим все карточки, которых ещё нет в кэше
    private func loadRemainingCards(for boardID: String, completion: @escaping () -> Void) {
        let already = Set(cache.getCachedCards(for: boardID).map(\.id))
        cardService.fetchCards(for: boardID, limit: nil)
            .map { $0.filter { !already.contains($0.id) } }
            .subscribe(onSuccess: { [weak self] uncached in
                self?.cache.cacheCards(uncached)
                if uncached.isEmpty {
                    print("Борд \(boardID) полностью загружен (оставшиеся)")
                    self?.fullyLoadedBoardIDs.insert(boardID)
                }
                completion()
            }, onFailure: { error in
                print("Preload full error: \(error.localizedDescription)")
                completion()
            })
            .disposed(by: bag)
    }
}
