import UIKit

// Экран информации о пользователе
final class ProfileInfoViewController: UIViewController {
    
    // MARK: - Dependencies
    private let user: AppUser
    private let viewModel: ProfileInfoViewModel
    
    // MARK: - UI
    private let scroll = UIScrollView()
    private let stack  = UIStackView()
    
    private let logoutButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Выйти"
        config.baseBackgroundColor = .systemRed
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        let b = UIButton(configuration: config)
        return b
    }()
    
    // MARK: - Init
    init(user: AppUser, viewModel: ProfileInfoViewModel) {
        self.user = user
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupLayout()
        fillContent()
        bind()
    }
    
    // MARK: - Setup
    private func setupLayout() {
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        scroll.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
        ])
        
        logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
    }
    
    private func fillContent() {
        let name = label("\(user.displayName ?? user.name)")
        let mail = label(user.email ?? "email не указан", color: .secondaryLabel)
        let bio  = label("Тут будет био/настройки/кнопки…")
        
        [name, mail, bio].forEach(stack.addArrangedSubview)
        
        // Отступ перед кнопкой
        stack.addArrangedSubview(spacer(height: 12))
        stack.addArrangedSubview(logoutButton)
    }
    
    private func bind() {
        viewModel.onError = { [weak self] error in
            self?.showError(error)
        }
    }
    
    // MARK: - Actions
    @objc
    private func didTapLogout() {
        let alert = UIAlertController(
            title: "Выйти из аккаунта?",
            message: "Вы сможете войти снова в любой момент.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Выйти", style: .destructive) { [weak self] _ in
            Task { [weak self] in
                guard let self else { return }
                await self.viewModel.signOutTapped()
            }
        })
        present(alert, animated: true)
    }
    
    // MARK: - Helpers
    private func label(_ text: String, color: UIColor = .label) -> UILabel {
        let l = UILabel()
        l.text = text
        l.textColor = color
        l.numberOfLines = 0
        return l
    }
    
    private func spacer(height: CGFloat) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.heightAnchor.constraint(equalToConstant: height)
        ])
        return v
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: (error as? LocalizedError)?.errorDescription ?? error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}
