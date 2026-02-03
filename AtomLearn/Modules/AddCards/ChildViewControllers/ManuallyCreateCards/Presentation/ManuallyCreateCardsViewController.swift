import UIKit

final class ManuallyCreateCardsViewController: UIViewController {

    // MARK: - Dependencies
    private let viewModel: ManuallyCreateCardsViewModel

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let addFormButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let emptyStateLabel = UILabel()

    private var formViewsById: [UUID: ManuallyCreateCardFormView] = [:]

    // MARK: - Init
    init(viewModel: ManuallyCreateCardsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
        viewModel.onViewDidLoad()
        enableKeyboardDismissOnTap()
    }

    // MARK: - Actions
    @objc private func addFormTapped() {
        viewModel.addCard()
    }

    @objc private func saveTapped() {
        view.endEditing(true)
        viewModel.saveTapped()
    }

    // MARK: - Private helpers
    private func setupUI() {
        title = "Создать карточки"
        view.backgroundColor = .systemBackground

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 12
        
        emptyStateLabel.text = "Добавь первую карточку"
        emptyStateLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.isHidden = true

        addFormButton.translatesAutoresizingMaskIntoConstraints = false
        addFormButton.setTitle("+", for: .normal)
        addFormButton.titleLabel?.font = .systemFont(ofSize: 26, weight: .bold)
        addFormButton.backgroundColor = .systemBlue
        addFormButton.setTitleColor(.white, for: .normal)
        addFormButton.layer.cornerRadius = 28
        addFormButton.addTarget(self, action: #selector(addFormTapped), for: .touchUpInside)

        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("Добавить", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        saveButton.backgroundColor = .systemGreen
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 14
        saveButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 18, bottom: 14, right: 18)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        view.addSubview(addFormButton)
        view.addSubview(saveButton)
        contentStack.addArrangedSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -140),

            addFormButton.widthAnchor.constraint(equalToConstant: 56),
            addFormButton.heightAnchor.constraint(equalToConstant: 56),
            addFormButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addFormButton.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -12),

            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            saveButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            guard let self else { return }
            self.render(state)
        }

        viewModel.onValidationFailed = { [weak self] issue in
            guard let self else { return }
            self.handleValidation(issue)
        }

        // route выставит Coordinator при сборке (в Coordinator.start/makeScreen)
        viewModel.onRoute = { [weak self] route in
            guard let self else { return }
            switch route {
            case .saved:
                let alert = UIAlertController(
                    title: "Готово",
                    message: "Карточки сохранены.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Ок", style: .default))
                self.present(alert, animated: true)
            case .close:
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    private func render(_ state: ManuallyCreateCardsViewModel.State) {
        let canSave = !state.items.isEmpty && !state.isSaving
        saveButton.isEnabled = canSave
        addFormButton.isEnabled = !state.isSaving
        saveButton.alpha = canSave ? 1 : 0.5
        emptyStateLabel.isHidden = !state.items.isEmpty

        rebuildFormsIfNeeded(items: state.items)

        if let message = state.errorMessage, !message.isEmpty {
            // минимально: потрясти и показать
            view.shake()
            // можно потом заменить на inline label / alert по твоим правилам UX
        }
    }

    private func rebuildFormsIfNeeded(items: [ManuallyCreateCardsDraft]) {
        // Простой вариант: перестроим, но сохраним уже созданные view по id.
        // Для “среднего размера” экранов этого достаточно.
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        contentStack.addArrangedSubview(emptyStateLabel)
        
        let currentIds = Set(items.map { $0.id })
        formViewsById.keys
            .filter { !currentIds.contains($0) }
            .forEach { formViewsById.removeValue(forKey: $0) }

        for (index, item) in items.enumerated() {
            let formView: ManuallyCreateCardFormView
            if let existing = formViewsById[item.id] {
                formView = existing
            } else {
                formView = ManuallyCreateCardFormView(index: index)
                formViewsById[item.id] = formView

                formView.onQuestionChanged = { [weak self] text in
                    self?.viewModel.updateQuestion(id: item.id, text: text)
                }
                formView.onAnswerChanged = { [weak self] text in
                    self?.viewModel.updateAnswer(id: item.id, text: text)
                }
                formView.onRemoveTapped = { [weak self] in
                    self?.viewModel.removeCard(id: item.id)
                }
            }

            formView.render(index: index, question: item.question, answer: item.answer)
            formView.setRemoveVisible(true)
            contentStack.addArrangedSubview(formView)
        }
    }

    private func handleValidation(_ issue: ManuallyCreateCardsViewModel.ValidationIssue) {
        view.shake()

        switch issue {
        case .noCards:
            view.shake()
        case .emptyQuestion(let index):
            focus(index: index, field: .question)
        case .emptyAnswer(let index):
            focus(index: index, field: .answer)
        }
    }

    private enum FocusField {
        case question
        case answer
    }

    private func focus(index: Int, field: FocusField) {
        guard index >= 0, index < contentStack.arrangedSubviews.count else { return }
        guard let form = contentStack.arrangedSubviews[index] as? ManuallyCreateCardFormView else { return }

        let targetRect = form.convert(form.bounds, to: scrollView)
        scrollView.scrollRectToVisible(targetRect.insetBy(dx: 0, dy: -20), animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            switch field {
            case .question:
                form.focusQuestion()
                form.shake()
            case .answer:
                form.focusAnswer()
                form.shake()
            }
        }
    }
}
