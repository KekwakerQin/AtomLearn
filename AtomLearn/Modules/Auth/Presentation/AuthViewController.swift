import UIKit

// Экран авторизации через Google
final class AuthViewController: UIViewController {
    private let viewModel: AuthViewModel
    private let labelAnimator = AuthLabelAnimator()

    // Элементы интерфейса
    private let spinner = UIActivityIndicatorView(style: .large)
    private let label = UILabel.make(text: "")
    private let stack = UIStackView()
    private let container = UIView()
    
    let button = UIButton(type: .system) // No in stack

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.presentingViewController = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        bindViewModel()
        view.backgroundColor = .black
    }
    
    // Запуск анимации текста при появлении
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        label.alpha = 0

        viewModel.onViewDidAppear()
    }

    // MARK: - UI SETUP
    
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
    
    //MARK: - TARGETS
    
    // Обработчик нажатия на кнопку входа
    @objc private func tap() {
        viewModel.onSignInTap()
    }
    
    // Состояние загрузки — блокировка кнопки и спиннер
    private func setLoading(_ loading: Bool) {
        button.isEnabled = !loading
        loading ? spinner.startAnimating() : spinner.stopAnimating()
        button.alpha = loading ? 0.3 : 1.0
    }

    // Отображение ошибок авторизации
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка входа", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        labelAnimator.stopAnimating()
    }
}
