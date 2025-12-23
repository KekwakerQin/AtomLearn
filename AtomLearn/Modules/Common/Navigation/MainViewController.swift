import UIKit
import FirebaseAuth
import SwiftUI

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    private let user: AppUser
    private let boardsService: BoardsService

    // Ссылки для вызовов
//    private let homeVC = UINavigationController(rootViewController: HomeViewController())
    private let badgeVC = UINavigationController(rootViewController: BadgesViewController())
    private let searchVC = UINavigationController(rootViewController: SearchViewController())

    private let messagesVC = UINavigationController(
        rootViewController: UIHostingController(rootView: AnatomyStudyScreen())
    )
    private let profileVC: UINavigationController

    init(user: AppUser, boardsService: BoardsService = BoardsRepository()) {
        self.user = user
        self.boardsService = boardsService
        self.profileVC = UINavigationController(rootViewController: ProfileViewController(user: user))
        super.init(nibName: nil, bundle: nil)
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
        let vc = AddEntityViewController(service: BoardsRepository()) {
            print(" Создано, обнови UI если нужно")
        }

        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.presentationController as? UISheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }
}
