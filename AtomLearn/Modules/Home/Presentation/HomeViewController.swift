import UIKit

final class HomeViewController: UIViewController {
    // MARK: - Dependencies
    private let viewModel: HomeViewModel

    // MARK: - UI

    // Превью изображения (результат загрузки)
    private let imageView = UIImageView()
    // Статус/лог загрузки
    private let status = UILabel()

    // MARK: - Init
    /// Создаёт домашний экран.
    init(viewModel: HomeViewModel = HomeViewModel(service: HomeRepository())) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        print("DEINIT \(self)")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.load()
    }

    // MARK: - UI
    // Настройка интерфейса
    private func setupUI() {
        view.backgroundColor = .systemBackground
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true

        status.text = "Загрузка…"
        status.numberOfLines = 0
        status.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [status, imageView])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 16

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            imageView.heightAnchor.constraint(equalToConstant: 160)
        ])
    }

    // MARK: - Bindings
    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let self else { return }
            status.text = state.statusText
            if let data = state.imageData {
                imageView.image = UIImage(data: data)
            } else {
                imageView.image = nil
            }
        }

        viewModel.onError = { [weak self] error in
            guard let self else { return }
            status.text = "Ошибка: \(error.localizedDescription)"
            imageView.image = nil
        }
    }
}
