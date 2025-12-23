import UIKit
final class ProfileCustomizationViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Кастомизация профиля"
        view.backgroundColor = .systemBackground
    }
    
    deinit {
        print("DEINIT \(self)")
    }
}
