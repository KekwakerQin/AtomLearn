import UIKit

enum ProfileRouter {
    static func createModule(for userID: String) -> UIViewController {
        let viewController = ProfileViewController()
        
        viewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "person.crop.circle.fill"),
            selectedImage: UIImage(systemName: "person.crop.circle.fill")
        )
        
        return viewController
    }
}
