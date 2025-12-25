import UIKit

final class CreateBoardViewController: UIViewController {

    // MARK: - Dependencies
    private let viewModel: CreateBoardViewModel

    // MARK: - UI
    private let titleTextField = UITextField()
    private let loader = UIActivityIndicatorView(style: .large)

    // MARK: - Init
    init(viewModel: CreateBoardViewModel) {
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
        view.backgroundColor = .systemBackground

        configureNavigation()
        configureUI()
        bind()

        viewModel.onViewDidLoad()
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        viewModel.cancel()
    }

    @objc private func createTapped() {
        viewModel.createBoard(
            title: titleTextField.text ?? ""
        )
    }

    // MARK: - Private helpers
    private func configureNavigation() {
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Отмена",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Создать",
            style: .done,
            target: self,
            action: #selector(createTapped)
        )
    }

    private func configureUI() {
        titleTextField.placeholder = "Название доски"
        titleTextField.borderStyle = .roundedRect
        titleTextField.font = .systemFont(ofSize: 17)
        titleTextField.returnKeyType = .done

        view.addSubview(titleTextField)
        titleTextField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 24
            ),
            titleTextField.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 16
            ),
            titleTextField.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -16
            )
        ])

        loader.hidesWhenStopped = true
        view.addSubview(loader)
        loader.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func bind() {
        viewModel.onError = { [weak self] message in
            let alert = UIAlertController(
                title: "Ошибка",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(.init(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }

        viewModel.onLoadingChanged = { [weak self] isLoading in
            self?.setLoading(isLoading)
        }

        viewModel.onFinish = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    private func setLoading(_ isLoading: Bool) {
        if isLoading {
            loader.startAnimating()
        } else {
            loader.stopAnimating()
        }

        navigationItem.leftBarButtonItem?.isEnabled = !isLoading
        navigationItem.rightBarButtonItem?.isEnabled = !isLoading
        titleTextField.isEnabled = !isLoading
    }
}
