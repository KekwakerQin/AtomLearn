import UIKit

enum MainRouter {
    static func createTabBar(for userID: String) -> UIViewController {
        let boardNav = UINavigationController(rootViewController: BoardListRouter.createModule(for: userID))
        let friendListNav = UINavigationController(rootViewController: FriendListRouter.createModule(for: userID))
        let profileNav = UINavigationController(rootViewController: ProfileRouter.createModule(for: userID))
        let gameNav = UINavigationController(rootViewController: GameRouter.createModule(for: userID))
        
        let tabBar = UITabBarController()
        tabBar.setViewControllers([gameNav, boardNav, friendListNav, profileNav], animated: true)
        
        return tabBar
    }
}


