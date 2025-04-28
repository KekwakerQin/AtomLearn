import UIKit
import RxSwift
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private let disposeBag = DisposeBag()
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        print("We are on SceneDelegate")
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        SessionManager.shared.bootstrapSessionIfNeeded()
            .subscribe(
                onCompleted: {
                    AppLauncher.shared.launch(in: window)
                },
                onError: { error in
                    print("Ошибка при восстановлении сессии: \(error)")
                    AppLauncher.shared.launch(in: window)
                }
            )
            .disposed(by: disposeBag)
        
        window.makeKeyAndVisible()
    }
    
    func reloadRootViewController() {
        guard let window = window else { return }
        AppLauncher.shared.launch(in: window)
    }
}


