import UIKit
import RxSwift

final class AuthViewController: UIViewController {
    
    private let authService: AuthServiceProtocol = FirebaseAuthService()
    private let userService: UserServiceProtocol = FirestoreUserService()
    private let disposeBag = DisposeBag()
    
    private var loadingAlert: UIAlertController?
        
    private lazy var appleAuthButton: UIButton = setupAuthButton(title: "Sign in with Apple")
    private lazy var googleAuthButton: UIButton = setupAuthButton(title: "Sign in with Google")
    private lazy var logoPicture: UIImageView = setupLogoPicture()
    
    // MARK: - Initialization
    
    private func setupAuthButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor(named: "BackgroundColor"), for: .normal)
        button.setTitleColor(UIColor(named: "TextColor"), for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        button.backgroundColor = UIColor(named: "TextColor")
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func setupLogoPicture() -> UIImageView {
        let imageView = UIImageView(image: UIImage(named: "Logo"))
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
        imageView.addGestureRecognizer(tapGesture)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupHierarchy()
        setupConstraints()
        setupActions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.5) {
            self.logoPicture.alpha = 1.0
            self.logoPicture.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        logoPicture.layer.cornerRadius = logoPicture.bounds.width / 2
        logoPicture.clipsToBounds = true
    }
    
    // MARK: - Setup
    
    private func setupView() {
        view = UIView.setupView(view: view)
    }
    
    private func setupHierarchy() {
        view.addSubview(logoPicture)
        view.addSubview(googleAuthButton)
        view.addSubview(appleAuthButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            logoPicture.topAnchor.constraint(equalTo: view.topAnchor, constant: view.bounds.height * 0.2),
            logoPicture.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoPicture.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            logoPicture.heightAnchor.constraint(equalTo: logoPicture.widthAnchor),
            
            googleAuthButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            googleAuthButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: UIScreen.main.bounds.height * 0.2),
            googleAuthButton.heightAnchor.constraint(equalToConstant: 44),
            googleAuthButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            googleAuthButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            googleAuthButton.widthAnchor.constraint(lessThanOrEqualToConstant: 320),
            
            appleAuthButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appleAuthButton.topAnchor.constraint(equalTo: googleAuthButton.bottomAnchor, constant: UIScreen.main.bounds.height * 0.025),
            appleAuthButton.heightAnchor.constraint(equalToConstant: 44),
            appleAuthButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            appleAuthButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            appleAuthButton.widthAnchor.constraint(lessThanOrEqualToConstant: 320),
        ])
    }
    
    private func setupActions() {
        googleAuthButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
//        appleAuthButton.addTarget(self, action: #selector(handleAppleSignIn), for: .touchUpInside)
    }
    
    // MARK: - Actions
        
    private func retryGoogleLogin() {
        showLoaderAlert()

        authService.signInWithGoogle(from: self)
            .subscribe(
                onSuccess: { [weak self] user in
                    self?.loadingAlert?.dismiss(animated: true) {
                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let sceneDelegate = scene.delegate as? SceneDelegate {
                            sceneDelegate.reloadRootViewController()
                        }
                    }
                },
                onFailure: { [weak self] error in
                    self?.loadingAlert?.dismiss(animated: true) {
                        self?.showError(error, retryAction: {
                            self?.retryGoogleLogin()
                        })
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    @objc private func handleGoogleSignIn() {
//        showLoaderAlert()

        authService.signInWithGoogle(from: self)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] appUser in
                    self?.loadingAlert?.dismiss(animated: true)

                    // Переход к следующему экрану
                    if let window = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .first?.windows
                        .first(where: { $0.isKeyWindow }) {
                        AppLauncher.shared.launch(in: window)
                    }
                },
                onFailure: { [weak self] error in
                    self?.loadingAlert?.dismiss(animated: true) {
                        self?.showError(error, retryAction: {
                            self?.handleGoogleSignIn()
                        })
                    }
                }
            )
            .disposed(by: disposeBag)
    }
//    @objc private func handleAppleSignIn() {
//        authService.signInWithApple(from: self)
//            .do(onSubscribe: { print("Начали вход по Apple") })
//            .flatMap { user in
//                print("Получен user: \(user.uid)")
//                return self.userService.createUserIfNeeded(from: user)
//            }
//            .observe(on: MainScheduler.instance)
//            .subscribe(onSuccess: { appUser in
//                print("Успешный вход, appUser: \(appUser.uid)")
//                SessionManager.shared.currentUser = appUser
//                AppLauncher.shared.launch(in: UIApplication.shared.windows.first!)
//            }, onFailure: { error in
//                print("Ошибка входа по Apple: \(error.localizedDescription)")
//            })
//            .disposed(by: disposeBag)
//    }
    
    @objc private func handleImageTap() {
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()
    }
    
    // MARK: - Helpers
    
    private func showLoaderAlert() {
        let alert = UIAlertController(title: "Signing in...", message: "\n\n", preferredStyle: .alert)

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        alert.view.addSubview(spinner)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 60)
        ])

        self.loadingAlert = alert
        self.present(alert, animated: true)
    }
    
    private func showError(_ error: Error, retryAction: @escaping () -> Void) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        let alert = UIAlertController(title: "Failed", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in
            retryAction()
        }))
        self.present(alert, animated: true)
    }
}
