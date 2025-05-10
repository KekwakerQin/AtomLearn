import UIKit

enum FriendListRouter {
    static func createModule(for userID: String) -> UIViewController {
        let viewController = FreindListViewController()
        
        viewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "rectangle.3.group.bubble.fill"),
            selectedImage: UIImage(systemName: "rectangle.3.group.bubble.fill")
        )
        
        return viewController
    }
}
