import UIKit
import FirebaseAuth
import SwiftUI

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    // MARK: Dependencies

    private enum AddFlowState {
        case idle
        case creatingBoard
        case addingCards(Board)
    }

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

        addNavController.view.backgroundColor = .clear
        addNavController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "plus.circle"),
            selectedImage: UIImage(systemName: "plus.circle")
        )
        addNavController.tabBarItem.tag = 2

        let addPlaceholderVC = UIViewController()
        addPlaceholderVC.view.backgroundColor = .systemBackground
        addNavController.setViewControllers([addPlaceholderVC], animated: false)

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
        guard viewController.tabBarItem.tag == 2 else {
            return true
        }
        handleAddTabTap()
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

        coordinator.onFinish = { [weak self] in
            self?.childCoordinators.removeAll { $0 === coordinator }
            sheetNav.dismiss(animated: true)
        }

        coordinator.onCreateBoard = { [weak self] in
            sheetNav.dismiss(animated: true) {
                self?.startCreateBoardFlow()
            }
        }

        coordinator.onSelectBoard = { [weak self] board in
            sheetNav.dismiss(animated: true) {
                self?.startAddCardsFlow(board: board)
            }
        }

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
            user: user
        )

        coordinator.onCancel = { [weak self] in
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
            board: board
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
        selectedIndex = 4
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

        addNavController.setViewControllers([], animated: false)
    }

}
