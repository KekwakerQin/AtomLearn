import FirebaseAuth
import UIKit

final class AppCoordinator {
    private weak var window: UIWindow?
    private let authCoordinator: AuthCoordinator
    private var authStateDidChangeHandle: AuthStateDidChangeListenerHandle?
    private var currentRoute: Route?

    private enum Route: Equatable {
        case auth
        case main(userId: String)
    }

    init(window: UIWindow) {
        self.window = window
        self.authCoordinator = AuthCoordinator(window: window)
    }

    func start() {
        showInitialScreen()
        startAuthStateListener()
    }

    func stop() {
        stopAuthStateListener()
    }

    private func showInitialScreen() {
        if let user = Auth.auth().currentUser {
            showMain(for: user, animated: false)
        } else {
            showAuth(animated: false)
        }
    }

    private func startAuthStateListener() {
        guard authStateDidChangeHandle == nil else { return }
        authStateDidChangeHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            if let user {
                self.showMain(for: user, animated: true)
            } else {
                self.showAuth(animated: true)
            }
        }
    }

    private func stopAuthStateListener() {
        guard let handle = authStateDidChangeHandle else { return }
        Auth.auth().removeStateDidChangeListener(handle)
        authStateDidChangeHandle = nil
    }

    private func showMain(for user: User, animated: Bool) {
        let route = Route.main(userId: user.uid)
        guard currentRoute != route else { return }
        currentRoute = route
        authCoordinator.showMain(for: makeAppUser(from: user), animated: animated)
    }

    private func showAuth(animated: Bool) {
        guard currentRoute != .auth else { return }
        currentRoute = .auth
        authCoordinator.showAuth(animated: animated)
    }

    private func makeAppUser(from user: User) -> AppUser {
        AppUser(
            uid: user.uid,
            name: user.displayName ?? "",
            email: user.email,
            displayName: user.displayName
        )
    }

    deinit {
        stopAuthStateListener()
    }
}
