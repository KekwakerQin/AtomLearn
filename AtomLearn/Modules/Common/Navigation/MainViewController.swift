import UIKit
import FirebaseAuth
import SwiftUI

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    private let user: AppUser
    private let boardsService: BoardsService
    
    // MARK: - Child coordinators
    private var childCoordinators: [AnyObject] = []
    
    // Ссылки для вызовов
    //    private let homeVC = UINavigationController(rootViewController: HomeViewController())
    private let badgeVC = UINavigationController(rootViewController: BadgesViewController())
    private let searchVC = UINavigationController(rootViewController: SearchViewController())
    
    private let messagesVC = UINavigationController(rootViewController: MessagesViewController())
    private let profileVC: UINavigationController
    
    private func activeNavigationController() -> UINavigationController? {
        if let nav = selectedViewController as? UINavigationController {
            return nav
        }
        return nil
    }
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        tabBar.tintColor = .label
        
        // 1) Дом
        badgeVC.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "house"), tag: 0)
        
        // 2) Поиск
        searchVC.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "magnifyingglass"), tag: 1)
        
        // 3) ПЛЮС — Плейсхолдер (не будет открываться)
        let addPlaceholder = UIViewController()
        addPlaceholder.view.backgroundColor = .clear
        addPlaceholder.tabBarItem = UITabBarItem(title: "",
                                                 image: UIImage(systemName: "plus.circle"),
                                                 tag: 2)
        
        // 4) Сообщения
        messagesVC.tabBarItem = UITabBarItem(title: "",
                                             image: UIImage(systemName: "bubble.left.and.bubble.right"),
                                             tag: 3)
        
        // 5) Профиль
        profileVC.tabBarItem = UITabBarItem(title: "",
                                            image: UIImage(systemName: "person.circle"),
                                            tag: 4)
        
        viewControllers = [badgeVC, searchVC, addPlaceholder, messagesVC, profileVC]
        
        // стартовый таб
        selectedIndex = 0
    }
    
    // MARK: - UITabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        // перехватываем среднюю вкладку (tag == 2)
        if viewController.tabBarItem.tag == 2 {
            presentAddBoardSheet()
            return false // не переключаемся на неё
        }
        return true
    }
    
    private func presentAddBoardSheet() {
        let sheetNav = UINavigationController()
        sheetNav.presentationController?.delegate = self
        sheetNav.modalPresentationStyle = .pageSheet
        
        let coordinator = AddEntityCoordinator(
            navigationController: sheetNav,
            user: user,
            boardsService: boardsService
        )
        
        coordinator.onFinish = { [weak self, weak coordinator] in
            guard let coordinator else { return }
            self?.childCoordinators.removeAll { $0 === coordinator }
            sheetNav.dismiss(animated: true)
        }
        
        coordinator.onCreateBoard = { [weak self, weak sheetNav, weak coordinator] in
            guard let self, let sheetNav, let coordinator else { return }

            self.childCoordinators.removeAll { $0 === coordinator }

            sheetNav.dismiss(animated: true) {
                self.openCreateBoard()
            }
        }
        
        coordinator.onSelectBoard = { [weak self, weak sheetNav, weak coordinator] board in
            guard let self, let sheetNav, let coordinator else { return }

            self.childCoordinators.removeAll { $0 === coordinator }

            sheetNav.dismiss(animated: true) {
                self.openAddCards(board: board)
            }
        }
        
        childCoordinators.append(coordinator)
        coordinator.start()
        
        present(sheetNav, animated: true)
    }
}

extension MainTabBarController {
    private enum Tab: Int {
        case home = 0
        case search = 1
        case add = 2
        case messages = 3
        case profile = 4
    }
}

extension MainTabBarController {
    private func openCreateBoard() {
        guard let nav = activeNavigationController() else { return }
        
        let coordinator = CreateBoardCoordinator(
            navigationController: nav,
            user: user
        )
        coordinator.start()
    }
    
    private func openAddCards(board: Board) {
        guard let nav = activeNavigationController() else { return }
        
        let coordinator = AddCardsCoordinator(
            navigationController: nav,
            board: board
        )
        coordinator.start()
    }
}

extension MainTabBarController: UIAdaptivePresentationControllerDelegate {

    func presentationControllerDidDismiss(
        _ presentationController: UIPresentationController
    ) {
        // sheet закрыт свайпом → чистим AddEntityCoordinator
        childCoordinators.removeAll { $0 is AddEntityCoordinator }
    }
}
