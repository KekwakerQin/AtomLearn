import UIKit

// Экран авторизации через Google
class AuthViewController: UIViewController {
    // Сервис авторизации
    private let auth: AuthService = AuthServiceImpl()

    // Элементы интерфейса
    private let spinner = UIActivityIndicatorView(style: .large)
    private let label = UILabel.make(text: "")
    private let stack = UIStackView()
    private let container = UIView()
    
    let button = UIButton(type: .system) // No in stack
    
    // Добавляем элементы в стек
    func addToStack() {
        [label].forEach {
            stack.addArrangedSubview($0)
        }
    }
    
    // Отключаем автогенерацию Auto Layout (TAMIC)
    func removeTAMIC() {
        [container, button, stack, label, spinner].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    // Настройка экрана при загрузке
    override func viewDidLoad() {
        super.viewDidLoad()
        addViews()
        setupUI()
        setupConstraints()
        view.backgroundColor = .black
    }
    
    // Запуск анимации текста при появлении
    override func viewDidAppear(_ animate: Bool) {
        super.viewDidAppear(true)
        label.alpha = 0
        
        animateLabel()
    }
    
    // MARK: - UI SETUP
    
    // Анимация цикличного появления текста
    private func animateLabel(index: Int = 0) {
        guard index < StorageOfLabels.russian.count else { return }
        
        label.alpha = 0
        label.text = StorageOfLabels.russian[index]
        
        UIView.animate(withDuration: 0.65) {
            self.label.alpha = 1
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                UIView.animate(withDuration: 0.3) {
                    self.label.alpha = 0
                } completion: { _ in
                    let next = (index + 1) % StorageOfLabels.russian.count
                    self.animateLabel(index: next)
                }
            }
        }
    }
    
    // Настройка внешнего вида кнопки, стека и меток
    private func setupUI() {
        // BUTTONS
        button.setTitle("Нажми", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(tap), for: .touchUpInside)
        
        // STACK
        stack.axis = .vertical
        stack.alignment = .center
        
        // LABELS
        label.textColor = .white
    }
    
    // Добавляем сабвью и формируем иерархию
    private func addViews() {
        // View
        view.addSubview(stack)
        view.addSubview(button)
        view.addSubview(container)
        view.addSubview(spinner)
        // Stack
        addToStack()
    }
    
    // Настраиваем Auto Layout
    private func setupConstraints() {
        removeTAMIC()
        
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 60),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: button.topAnchor),
            
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            
            ])
    }
    
    //MARK: - TARGETS
    
    // Обработчик нажатия на кнопку входа
    @objc private func tap() {
        // Асинхронно выполняем вход
        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                let user = try await auth.signInWithGoogle(from: self)
                await MainActor.run {
                    self.setLoading(false)
                    self.routeToMain(user: user)
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.showError(error)
                }
            }
        }
    }
    
    // Состояние загрузки — блокировка кнопки и спиннер
    private func setLoading(_ loading: Bool) {
        button.isEnabled = !loading
        loading ? spinner.startAnimating() : spinner.stopAnimating()
        button.alpha = loading ? 0.3 : 1.0
    }

    // Отображение ошибок авторизации
    private func showError(_ error: Error) {
        let message: String
        if let e = error as? AuthError {
            switch e {
            case .configurationMissing: message = "Нет конфигурации Firebase."
            case .userCancelled:        message = "Вход отменён."
            case .providerError(let u): message = "Ошибка Google: \(u.localizedDescription)"
            case .firebaseError(let u): message = "Ошибка Firebase: \(u.localizedDescription)"
            case .unknown:              message = "Неизвестная ошибка."
            }
        } else {
            message = error.localizedDescription
        }
        let alert = UIAlertController(title: "Ошибка входа", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
    
    // Переход на главный экран после успешного входа
    private func routeToMain(user: AppUser) {
        let tab = MainTabBarController(user: user)

        if let nav = navigationController {
            // Полностью заменяем стек на таб-бар
            nav.setViewControllers([tab], animated: true)
        } else {
            // если AuthVC не в навигации — меняем root
            let nav = UINavigationController(rootViewController: tab)
            view.window?.rootViewController = nav
            view.window?.makeKeyAndVisible()
        }
    }
}
