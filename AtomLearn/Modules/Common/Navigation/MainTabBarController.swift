import UIKit
import FirebaseAuth

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    // MARK: Dependencies

    private enum AddFlowState {
        case idle
        case creatingBoard
        case addingCards(Board)
    }
    
    private var currentIndex = 0
    private weak var addEntitySheetNav: UINavigationController?
    private weak var addEntitySheetCoordinator: AnyObject?

    private var addFlowState: AddFlowState = .idle
    private var addFlowNavigationController: UINavigationController?
    private var addFlowCoordinator: AnyObject?

    private let user: AppUser
    private let boardsService: BoardsService

    // MARK: UI

    private var childCoordinators: [AnyObject] = []

    private let badgeVC = UINavigationController(rootViewController: BadgesViewController())
    private let searchVC = UINavigationController(rootViewController: SearchViewController())
    private let messagesVC = UINavigationController(rootViewController: MessagesViewController())
    private let profileVC: UINavigationController

    private let addNavController = UINavigationController()
    private let addPlaceholderVC = UIViewController()

    // MARK: Init

    init(user: AppUser, boardsService: BoardsService = BoardsRepository()) {
        self.user = user
        self.boardsService = boardsService
        self.profileVC = UINavigationController(rootViewController: ProfileViewController(user: user))
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        print("DEINIT \(self)")
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        tabBar.tintColor = .label

        badgeVC.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "house"), tag: 0)
        searchVC.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "magnifyingglass"), tag: 1)

        addPlaceholderVC.view.backgroundColor = .systemBackground
        addNavController.setViewControllers([addPlaceholderVC], animated: false)

        addNavController.view.backgroundColor = .clear
        addNavController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "plus.circle"),
            selectedImage: UIImage(systemName: "plus.circle")
        )
        addNavController.tabBarItem.tag = 2

        messagesVC.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "bubble.left.and.bubble.right"), tag: 3)
        profileVC.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "person.circle"), tag: 4)

        viewControllers = [
            badgeVC,
            searchVC,
            addNavController,
            messagesVC,
            profileVC
        ]

        selectedIndex = 0
    }

    // MARK: Actions

    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        
        guard let index = tabBarController.viewControllers?.firstIndex(of: viewController) else {
            return true
        }
        
        if viewController.tabBarItem.tag != 2 {
            currentIndex = index
            #if DEBUG
            print(index)
            #endif
        }
        
        guard viewController.tabBarItem.tag == 2 else {
            return true
        }

        if viewController.tabBarItem.tag == 2 {
            handleAddTabTap()
            return false
        }

        return false
    }

    /// Presents the sheet for adding a new entity.
    private func presentAddEntitySheet() {
        let sheetNav = UINavigationController()
        sheetNav.modalPresentationStyle = .pageSheet

        let coordinator = AddEntityCoordinator(
            navigationController: sheetNav,
            user: user,
            boardsService: boardsService
        )

        // важно: чтобы поймать свайп вниз
        sheetNav.presentationController?.delegate = self
        addEntitySheetNav = sheetNav
        addEntitySheetCoordinator = coordinator

        coordinator.onCreateBoard = { [weak self, weak coordinator, weak sheetNav] in
            guard let self else { return }
            if let coordinator {
                self.childCoordinators.removeAll { $0 === coordinator }
            }
            self.addEntitySheetNav = nil
            self.addEntitySheetCoordinator = nil
            sheetNav?.dismiss(animated: true) { self.startCreateBoardFlow() }
        }

        coordinator.onFinish = { [weak self, weak coordinator, weak sheetNav] in
            guard let self else { return }
            if let coordinator {
                self.childCoordinators.removeAll { $0 === coordinator }
            }
            self.addEntitySheetNav = nil
            self.addEntitySheetCoordinator = nil
            sheetNav?.dismiss(animated: true)
        }
    
        coordinator.onSelectBoard = { [weak self, weak sheetNav] board in
            guard let self else { return }

            // 1) Найти nav 4-го таба (после переключения)
            let pushFlow = {
                self.selectedIndex = 4

                guard
                    let tabBar = self as? UITabBarController, // если self = MainTabBarController, можно просто self
                    let nav = tabBar.viewControllers?[4] as? UINavigationController
                else { return }

                let cardsVC = CardsViewController(
                    user: self.user,
                    board: board,
                    viewModel: CardsViewModel(/* service */)
                )

                let addCardsVM = AddCardsViewModel(boardId: board.id, user: self.user)
                let addCardsVC = AddCardsViewController(viewModel: addCardsVM)

                // Важно: пушим в nav 4-го таба
                nav.popToRootViewController(animated: false) // опционально
                nav.pushViewController(cardsVC, animated: false)
                nav.pushViewController(addCardsVC, animated: true)
            }

            // 2) Закрыть sheet и пушить только после закрытия
            if let sheetNav {
                sheetNav.dismiss(animated: true) {
                    pushFlow()
                }
            } else {
                // если вдруг sheetNav уже nil
                pushFlow()
            }
        }
        
//        coordinator.onSelectBoard = { [weak self, weak coordinator, weak sheetNav] board in
//            guard let self else { return }
//
//            // 1) Cards
//            let cardsVM = CardsViewModel()
//            
//            let cardsVC = CardsViewController(user: self.user, board: board, viewModel: cardsVM)
//            sheetNav?.pushViewController(cardsVC, animated: true)
//
//            // 2) AddCards поверх Cards
//            let addCardsVM = AddCardsViewModel(boardId: board.id, user: self.user)
//
//            addCardsVM.onCancel = { [weak sheetNav] in
//                sheetNav?.popViewController(animated: true) // вернёмся на Cards ✅
//            }
//
//            let addCardsVC = AddCardsViewController(viewModel: addCardsVM)
//            sheetNav?.pushViewController(addCardsVC, animated: true)
//        }
        
        childCoordinators.append(coordinator)
        coordinator.start()
        present(sheetNav, animated: true)
    }
    
    /// Starts the flow for creating a new board.
    private func startCreateBoardFlow() {
        resetAddFlowIfNeeded()

        let nav = UINavigationController()
        let coordinator = CreateBoardCoordinator(
            navigationController: nav,
            ownerUID: user.uid
        )

        coordinator.onCancel = { [weak self] in
            self?.cancelAddFlow()
        }

        coordinator.onFinish = { [weak self] _ in
            self?.cancelAddFlow()
        }
        
        addFlowState = .creatingBoard
        addFlowNavigationController = nav
        addFlowCoordinator = coordinator

        coordinator.start()
        attachAddFlowTab(nav)
    }

    /// Starts the flow for adding cards to a given board.
    /// - Parameter board: The board to add cards to.
    private func startAddCardsFlow(board: Board) {
        resetAddFlowIfNeeded()

        let nav = UINavigationController()
        let coordinator = AddCardsCoordinator(
            navigationController: nav,
            board: board,
            user: user
        )

        coordinator.onCancel = { [weak self] in
            self?.cancelAddFlow()
        }

        addFlowState = .addingCards(board)
        addFlowNavigationController = nav
        addFlowCoordinator = coordinator

        coordinator.start()
        attachAddFlowTab(nav)
    }

    /// Cancels the current add flow and returns to the profile tab.
    private func cancelAddFlow() {
        resetAddFlow()
        selectedIndex = currentIndex
    }

    // MARK: Private helpers

    private func handleAddTabTap() {
        switch addFlowState {
        case .idle:
            presentAddEntitySheet()
        case .creatingBoard, .addingCards:
            selectedIndex = 2
        }
    }

    private func activeNavigationController() -> UINavigationController? {
        if let nav = selectedViewController as? UINavigationController {
            return nav
        }
        return nil
    }

    private func attachAddFlowTab(_ nav: UINavigationController) {
        addNavController.setViewControllers(
            nav.viewControllers,
            animated: false
        )
        selectedIndex = 2
    }

    private func resetAddFlowIfNeeded() {
        if addFlowNavigationController != nil {
            resetAddFlow()
        }
    }

    private func resetAddFlow() {
        addFlowNavigationController = nil
        addFlowCoordinator = nil
        addFlowState = .idle

        addNavController.setViewControllers([addPlaceholderVC], animated: false)
    }

}

extension MainTabBarController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // сюда попадает свайп вниз (или другое системное закрытие)
        guard presentationController.presentedViewController === addEntitySheetNav else { return }

        if let coordinator = addEntitySheetCoordinator {
            childCoordinators.removeAll { $0 === coordinator }
        }

        addEntitySheetNav = nil
        addEntitySheetCoordinator = nil
    }
}
