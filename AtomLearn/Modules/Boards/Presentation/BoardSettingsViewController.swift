import UIKit

final class BoardSettingsViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    private var board: Board
    private let service: BoardsService

    var onUpdated: ((Board) -> Void)?

    // MARK: - UI
    private let scroll = UIScrollView()
    private let stack = UIStackView()

    private let titleField = UITextField()
    private let descriptionView = UITextView()
    private let descriptionPlaceholder = UILabel()
    private let saveButton = UIButton(type: .system)

    init(board: Board, service: BoardsService) {
        self.board = board
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Настройки доски"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        buildContent()
        bindInitial()
        enableKeyboardDismissOnTap()
    }

    private func setupLayout() {
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        scroll.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    private func buildContent() {
        stack.addArrangedSubview(headerCard())
        stack.addArrangedSubview(sectionTitle("Основные данные"))
        stack.addArrangedSubview(formCard())
        stack.addArrangedSubview(sectionTitle("Участники"))
        stack.addArrangedSubview(membersCard())

        configureSaveButton()
        stack.addArrangedSubview(saveButton)
    }

    private func bindInitial() {
        titleField.text = board.title
        descriptionView.text = board.description
        descriptionPlaceholder.isHidden = !board.description.isEmpty
    }

    // MARK: - UI Cards
    private func headerCard() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.12)
        card.layer.cornerRadius = 18

        let title = UILabel()
        title.text = "Обнови данные доски"
        title.font = .systemFont(ofSize: 18, weight: .bold)

        let subtitle = UILabel()
        subtitle.text = "Название, описание и доступ — всё в одном месте."
        subtitle.font = .systemFont(ofSize: 13, weight: .medium)
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 2

        let v = UIStackView(arrangedSubviews: [title, subtitle])
        v.axis = .vertical
        v.spacing = 4

        card.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            v.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            v.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            v.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        return card
    }

    private func formCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 18

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = .init(top: 14, leading: 14, bottom: 14, trailing: 14)

        configureTextField(titleField, placeholder: "Название доски")
        configureTextView(descriptionView)
        descriptionPlaceholder.text = "Описание темы"
        descriptionPlaceholder.textColor = .placeholderText
        descriptionPlaceholder.font = .systemFont(ofSize: 15)
        descriptionPlaceholder.isHidden = true

        let descContainer = UIView()
        descContainer.addSubview(descriptionView)
        descContainer.addSubview(descriptionPlaceholder)
        descriptionView.translatesAutoresizingMaskIntoConstraints = false
        descriptionPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            descriptionView.topAnchor.constraint(equalTo: descContainer.topAnchor),
            descriptionView.leadingAnchor.constraint(equalTo: descContainer.leadingAnchor),
            descriptionView.trailingAnchor.constraint(equalTo: descContainer.trailingAnchor),
            descriptionView.bottomAnchor.constraint(equalTo: descContainer.bottomAnchor),
            descriptionPlaceholder.topAnchor.constraint(equalTo: descContainer.topAnchor, constant: 10),
            descriptionPlaceholder.leadingAnchor.constraint(equalTo: descContainer.leadingAnchor, constant: 12),
            descriptionPlaceholder.trailingAnchor.constraint(equalTo: descContainer.trailingAnchor, constant: -12)
        ])

        stack.addArrangedSubview(fieldRow(title: "Название", field: titleField))
        stack.addArrangedSubview(fieldRow(title: "Описание", field: descContainer))

        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        return card
    }

    private func membersCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 18

        let info = UILabel()
        info.text = "Редактирование участников появится здесь. Сейчас можно менять название и описание."
        info.font = .systemFont(ofSize: 13)
        info.textColor = .secondaryLabel
        info.numberOfLines = 0

        card.addSubview(info)
        info.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            info.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            info.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            info.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            info.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        return card
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }

    // MARK: - Controls
    private func configureSaveButton() {
        saveButton.setTitle("Сохранить", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .systemGreen
        saveButton.layer.cornerRadius = 14
        saveButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    private func configureTextField(_ field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.autocorrectionType = .yes
        field.autocapitalizationType = .sentences
        field.delegate = self
    }

    private func configureTextView(_ tv: UITextView) {
        tv.font = .systemFont(ofSize: 15)
        tv.backgroundColor = .systemBackground
        tv.layer.cornerRadius = 12
        tv.layer.borderColor = UIColor.separator.cgColor
        tv.layer.borderWidth = 1
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        tv.heightAnchor.constraint(greaterThanOrEqualToConstant: 90).isActive = true
        tv.delegate = self
    }

    private func fieldRow(title: String, field: UIView) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        let v = UIStackView(arrangedSubviews: [titleLabel, field])
        v.axis = .vertical
        v.spacing = 6
        return v
    }

    // MARK: - Actions
    @objc private func saveTapped() {
        view.endEditing(true)

        let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let description = descriptionView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            showInfo("Название не может быть пустым")
            return
        }

        saveButton.isEnabled = false
        saveButton.alpha = 0.6

        Task { [weak self] in
            guard let self else { return }
            do {
                let input = UpdateBoardInput(title: title, description: description)
                try await service.updateBoard(boardId: board.id, input: input)

                let updated = Board(
                    id: board.id,
                    title: title,
                    description: description,
                    ownerUID: board.ownerUID,
                    memberUIDs: board.memberUIDs,
                    editorUIDs: board.editorUIDs,
                    viewerUIDs: board.viewerUIDs,
                    createdAt: board.createdAt,
                    lastActivityAt: Date()
                )

                await MainActor.run {
                    self.board = updated
                    self.saveButton.isEnabled = true
                    self.saveButton.alpha = 1
                    self.onUpdated?(updated)
                    self.showInfo("Изменения сохранены")
                }
            } catch {
                await MainActor.run {
                    self.saveButton.isEnabled = true
                    self.saveButton.alpha = 1
                    self.showInfo("Не удалось сохранить. Попробуй ещё раз.")
                }
            }
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        descriptionPlaceholder.isHidden = !textView.text.isEmpty
    }

    private func showInfo(_ message: String) {
        let alert = UIAlertController(title: "Доска", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}
