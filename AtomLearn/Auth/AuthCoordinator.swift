import UIKit

final class AuthCoordinator: AuthCoordinating {
    private weak var window: UIWindow?

    init(window: UIWindow) {
        self.window = window
    }

    func showMain(for user: AppUser, animated: Bool = true) {
        let main = MainTabBarController(user: user)
        setRoot(main, animated: animated)
    }

    func showAuth(animated: Bool = true) {
        let authVC = makeAuth()
        setRoot(authVC, animated: animated)
    }

    func makeAuth() -> UIViewController {
        let authService = AuthServiceImpl()
        let presenter = GoogleSignInPresenter()
        let viewModel = AuthViewModel(
            authService: authService,
            signInPresenter: presenter,
            coordinator: self
        )
        let authVC = AuthViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: authVC)
        return nav
    }

    private func setRoot(_ vc: UIViewController, animated: Bool) {
        guard let window else { return }

        if animated {
            let transition = CATransition()
            transition.type = .fade
            transition.duration = 0.25
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.layer.add(transition, forKey: kCATransition)
        }

        window.rootViewController = vc
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
    }
}
