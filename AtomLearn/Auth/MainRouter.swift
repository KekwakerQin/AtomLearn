import UIKit

struct Router {
    let isRegistered: Bool = AuthService.isUserLoggedIn()
    func printIsReg() {
        print("register: \(isRegistered)")
    }
    lazy var showView: UIViewController = isRegistered ? UserViewController() : AuthViewController()
}
