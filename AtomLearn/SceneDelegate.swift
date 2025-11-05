import UIKit
import FirebaseAuth

// Делегат сцены — точка входа UI
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    // Главное окно приложения
    var window: UIWindow?
    
    // Handle for Firebase Auth state listener to remove it when no longer needed
    private var authStateDidChangeHandle: AuthStateDidChangeListenerHandle?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Создаём окно и показываем стартовый экран
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        if let fbUser = Auth.auth().currentUser {
            // Создаём модель текущего пользователя
            let user = AppUser(
                uid: fbUser.uid,
                name: fbUser.displayName ?? "",
                email: fbUser.email,
                displayName: fbUser.displayName
            )
            // Главный экран с таббаром
            let main = makeMain(for: user)
            setRoot(main, animated: false)
        } else {
            // Экран авторизации
            let auth = makeAuth()
            setRoot(auth, animated: false)
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
                let main = self.makeMain(for: appUser)
                self.setRoot(main, animated: true)
            } else {
                // Пользователь вышел — показываем авторизацию
                let auth = self.makeAuth()
                self.setRoot(auth, animated: true)
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


    // Обёртка для установки корневого контроллера
    private func setRoot(_ vc: UIViewController, animated: Bool) {
        guard let window = self.window else { return }
        if animated {
            let transition = CATransition()
            transition.type = .fade
            transition.duration = 0.25
            window.layer.add(transition, forKey: kCATransition)
        }
        window.rootViewController = vc
        window.makeKeyAndVisible()
    }

    // Создать главный экран приложения
    private func makeMain(for user: AppUser) -> UIViewController {
        let main = MainTabBarController(user: user)
        return UINavigationController(rootViewController: main)
    }

    // Создать экран авторизации
    private func makeAuth() -> UIViewController {
        let authVC = AuthViewController()
        return UINavigationController(rootViewController: authVC)
    }
}

