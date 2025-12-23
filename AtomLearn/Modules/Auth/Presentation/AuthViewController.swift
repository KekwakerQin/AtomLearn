import UIKit

/// ViewController, отвечающий только за UI, биндинг и отображение экрана авторизации.
final class AuthViewController: UIViewController {
    // MARK: - Dependencies
    private let viewModel: AuthViewModel
    private let labelAnimator = AuthLabelAnimator()

    // MARK: - UI
    private let spinner = UIActivityIndicatorView(style: .large)
    private let label = UILabel.make(text: "")
    private let stack = UIStackView()
    private let container = UIView()
    
    private let button = UIButton(type: .system) // No in stack

    // MARK: - Init
    /// Создаёт экран авторизации с зависимым view model.
    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.presentingViewController = self
    }

    @available(*, unavailable)
    /// Инициализатор из storyboard недоступен.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    /// Настройка экрана при загрузке.
    override func viewDidLoad() {
        super.viewDidLoad()
        addViews()
        setupUI()
        setupConstraints()
        bindViewModel()
        view.backgroundColor = .black
    }
    
    /// Запуск анимации текста при появлении.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        label.alpha = 0

        viewModel.onViewDidAppear()
    }

    /// Остановка анимации при уходе с экрана.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        labelAnimator.stopAnimating()
    }

    // MARK: - Actions
    /// Обработчик нажатия на кнопку входа.
    @objc private func handleSignInTap() {
        viewModel.onSignInTap()
    }

    // MARK: - Private helpers
    /// Настройка внешнего вида кнопки, стека и меток.
    private func setupUI() {
        // BUTTONS
        button.setTitle("Нажми", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(handleSignInTap), for: .touchUpInside)
        
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

    private func bindViewModel() {
        viewModel.onLoadingChange = { [weak self] isLoading in
            self?.setLoading(isLoading)
        }
        viewModel.onError = { [weak self] message in
            self?.showError(message)
        }
        viewModel.onLabelAnimationStart = { [weak self] in
            guard let self else { return }
            self.labelAnimator.startAnimating(label: self.label)
        }
    }

    /// Добавляем элементы в стек.
    private func addToStack() {
        [label].forEach {
            stack.addArrangedSubview($0)
        }
    }

    /// Отключаем автогенерацию Auto Layout (TAMIC).
    private func removeTAMIC() {
        [container, button, stack, label, spinner].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    /// Состояние загрузки — блокировка кнопки и спиннер.
    private func setLoading(_ loading: Bool) {
        button.isEnabled = !loading
        loading ? spinner.startAnimating() : spinner.stopAnimating()
        button.alpha = loading ? 0.3 : 1.0
    }

    /// Отображение ошибок авторизации.
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка входа", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}
