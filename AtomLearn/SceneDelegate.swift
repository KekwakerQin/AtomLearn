import UIKit

// Делегат сцены — точка входа UI
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    // Главное окно приложения
    var window: UIWindow?
    private var appCoordinator: AppCoordinator?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Создаём окно и показываем стартовый экран
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.backgroundColor = .systemBackground
        let coordinator = AppCoordinator(window: window)
        self.appCoordinator = coordinator
        coordinator.start()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Сохраняем данные при уходе в фон
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        appCoordinator?.stop()
    }


}
