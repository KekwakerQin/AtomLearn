import UIKit

enum GameRouter {
    static func createModule(for userID: String) -> UIViewController {
        let viewController = GameViewController()
        
        viewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "gamecontroller.fill"),
            selectedImage: UIImage(systemName: "gamecontroller.fill")
        )
        
        return viewController
    }
}
