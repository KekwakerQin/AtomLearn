import UIKit
import FirebaseAuth

final class ProfileViewController: UIViewController {
    
    private let clearCache = CacheCleaner()
    
    private let clearCacheButton: UIButton = UIButton.standart(title: "Clear cache")
    private let exitButton: UIButton = UIButton.standart(title: "Logout")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupLayout()
        setupActions()
    }
    
    private func setupView() {
        view.addSubview(clearCacheButton)
        view.addSubview(exitButton)
    }
    
    private func setupActions() {
        clearCacheButton.addTarget(self, action: #selector(clearCacheFunc), for: .touchUpInside)
        exitButton.addTarget(self, action: #selector(handleSingOut), for: .touchUpInside)
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            clearCacheButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            clearCacheButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            clearCacheButton.heightAnchor.constraint(equalToConstant: 44),

                // Адаптивная ширина
            clearCacheButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),

                // Минимум и максимум (если надо)
            clearCacheButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            clearCacheButton.widthAnchor.constraint(lessThanOrEqualToConstant: 320),
            
            exitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exitButton.topAnchor.constraint(equalTo: clearCacheButton.bottomAnchor, constant: 20),
            exitButton.heightAnchor.constraint(equalToConstant: 44),

                // Адаптивная ширина
            exitButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),

                // Минимум и максимум (если надо)
            exitButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            exitButton.widthAnchor.constraint(lessThanOrEqualToConstant: 320)
            ])
    }
    
    @objc private func handleSingOut() {
        do {
                try Auth.auth().signOut()

                if let window = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first?.windows
                    .first(where: { $0.isKeyWindow }) {
                    AppLauncher.shared.launch(in: window)
                }
            } catch {
                print("Ошибка выхода: \(error)")
            }
    }
    
    @objc private func clearCacheFunc() {
        clearCache.removeAllCache()
    }
}
