import UIKit
import FirebaseAuth

// Делегат сцены — точка входа UI
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    // Главное окно приложения
    var window: UIWindow?
    private var authCoordinator: AuthCoordinator?
    
    // Handle for Firebase Auth state listener to remove it when no longer needed
    private var authStateDidChangeHandle: AuthStateDidChangeListenerHandle?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Создаём окно и показываем стартовый экран
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.backgroundColor = .systemBackground
        let coordinator = AuthCoordinator(window: window)
        self.authCoordinator = coordinator

        if let fbUser = Auth.auth().currentUser {
            // Создаём модель текущего пользователя
            let user = AppUser(
                uid: fbUser.uid,
                name: fbUser.displayName ?? "",
                email: fbUser.email,
                displayName: fbUser.displayName
            )
            // Главный экран с таббаром
            coordinator.showMain(for: user, animated: false)
        } else {
            // Экран авторизации
            coordinator.showAuth(animated: false)
        }

        // Следим за сменой состояния авторизации
        authStateDidChangeHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }

            if let user {
                // Пользователь вошёл — переходим на главный экран
                let appUser = AppUser(
                    uid: user.uid,
                    name: user.displayName ?? "",
                    email: user.email,
                    displayName: user.displayName
                )
                coordinator.showMain(for: appUser, animated: true)
            } else {
                // Пользователь вышел — показываем авторизацию
                coordinator.showAuth(animated: true)
            }
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Сохраняем данные при уходе в фон
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        if let handle = authStateDidChangeHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            authStateDidChangeHandle = nil
        }
    }

    deinit {
        if let handle = authStateDidChangeHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }


}

