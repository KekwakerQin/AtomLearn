import UIKit

final class ProfileCustomizationViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Dependencies
    private let user: AppUser
    private let authService: AuthService
    private let viewModel: ProfileCustomizationViewModel

    // MARK: - UI
    private let scroll = UIScrollView()
    private let stack  = UIStackView()

    private let nameField = UITextField()
    private let usernameField = UITextField()
    private let locationField = UITextField()
    private let websiteField = UITextField()

    private let bioTextView = UITextView()
    private let bioPlaceholder = UILabel()

    private let saveButton = UIButton(type: .system)
    private let logoutButton = UIButton(type: .system)
    private var wasSaving = false
    private let avatarView = AvatarView()
    private let changeAvatarButton = UIButton(type: .system)

    // MARK: - Init
    init(user: AppUser, authService: AuthService = AuthServiceImpl()) {
        self.user = user
        self.authService = authService

        let displayName = (user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        ? (user.displayName ?? user.name)
        : user.name
        let username = ProfileCustomizationViewController.makeHandle(from: displayName, email: user.email)

        let initial = ProfileDraft(
            displayName: displayName,
            username: username,
            bio: "",
            location: "",
            website: "",
            avatarPath: nil
        )

        self.viewModel = ProfileCustomizationViewModel(userId: user.uid, initialDraft: initial)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Кастомизация"
        view.backgroundColor = .systemBackground
        setupLayout()
        buildContent()
        bind()
        enableKeyboardDismissOnTap()
        viewModel.onViewDidLoad()
    }

    // MARK: - Layout
    private func setupLayout() {
        scroll.alwaysBounceVertical = true
        scroll.keyboardDismissMode = .interactive
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

    // MARK: - Content
    private func buildContent() {
        stack.addArrangedSubview(headerCard())
        stack.addArrangedSubview(sectionTitle("Данные профиля"))
        stack.addArrangedSubview(formCard())

        stack.addArrangedSubview(sectionTitle("Настройки"))
        stack.addArrangedSubview(settingsCard())

        configureSaveButton()
        stack.addArrangedSubview(saveButton)

        configureLogoutButton()
        stack.addArrangedSubview(logoutButton)
    }

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            guard let self else { return }
            self.apply(state)
        }
    }

    private func apply(_ state: ProfileCustomizationViewModel.State) {
        if nameField.text != state.draft.displayName { nameField.text = state.draft.displayName }
        if usernameField.text != state.draft.username { usernameField.text = state.draft.username }
        if bioTextView.text != state.draft.bio { bioTextView.text = state.draft.bio }
        if locationField.text != state.draft.location { locationField.text = state.draft.location }
        if websiteField.text != state.draft.website { websiteField.text = state.draft.website }

        bioPlaceholder.isHidden = !state.draft.bio.isEmpty

        let avatarImage = ProfileAvatarStore.shared.loadImage(path: state.draft.avatarPath)
        avatarView.configure(name: state.draft.displayName, image: avatarImage)

        saveButton.isEnabled = state.isDirty && !state.isSaving
        saveButton.alpha = (state.isDirty && !state.isSaving) ? 1 : 0.5

        if wasSaving && !state.isSaving && !state.isDirty {
            let alert = UIAlertController(
                title: "Сохранено",
                message: "Данные профиля обновлены.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Ок", style: .default))
            present(alert, animated: true)
        }
        wasSaving = state.isSaving

        if let error = state.errorMessage, !error.isEmpty {
            showError(NSError(domain: "Profile", code: 1, userInfo: [NSLocalizedDescriptionKey: error]))
        }
    }

    // MARK: - Cards
    private func headerCard() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.12)
        card.layer.cornerRadius = 18

        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.layer.cornerRadius = 30
        avatarView.clipsToBounds = true

        changeAvatarButton.setTitle("Изменить фото", for: .normal)
        changeAvatarButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        changeAvatarButton.addTarget(self, action: #selector(changeAvatarTapped), for: .touchUpInside)

        let title = UILabel()
        title.text = "Твой профиль"
        title.font = UIFont.systemRounded(ofSize: 20, weight: .bold)

        let subtitle = UILabel()
        subtitle.text = "Обнови имя, описание и публичные настройки"
        subtitle.font = .systemFont(ofSize: 13, weight: .medium)
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 2

        let v = UIStackView(arrangedSubviews: [title, subtitle])
        v.axis = .vertical
        v.spacing = 4

        let avatarStack = UIStackView(arrangedSubviews: [avatarView, changeAvatarButton])
        avatarStack.axis = .vertical
        avatarStack.alignment = .center
        avatarStack.spacing = 6

        let h = UIStackView(arrangedSubviews: [avatarStack, v])
        h.axis = .horizontal
        h.spacing = 12
        h.alignment = .center

        card.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 60),
            avatarView.heightAnchor.constraint(equalToConstant: 60),
            h.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            h.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            h.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            h.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        return card
    }

    private func formCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 18

        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 12
        cardStack.isLayoutMarginsRelativeArrangement = true
        cardStack.directionalLayoutMargins = .init(top: 14, leading: 14, bottom: 14, trailing: 14)

        configureTextField(nameField, placeholder: "Имя отображаемое")
        configureTextField(usernameField, placeholder: "username")
        configureTextField(locationField, placeholder: "Город")
        configureTextField(websiteField, placeholder: "Ссылка")
        websiteField.keyboardType = .URL
        websiteField.autocapitalizationType = .none

        configureTextView(bioTextView)
        bioPlaceholder.text = "Коротко о себе"
        bioPlaceholder.textColor = .placeholderText
        bioPlaceholder.font = .systemFont(ofSize: 15)
        bioPlaceholder.isHidden = true

        let bioContainer = UIView()
        bioContainer.addSubview(bioTextView)
        bioContainer.addSubview(bioPlaceholder)
        bioTextView.translatesAutoresizingMaskIntoConstraints = false
        bioPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bioTextView.topAnchor.constraint(equalTo: bioContainer.topAnchor),
            bioTextView.leadingAnchor.constraint(equalTo: bioContainer.leadingAnchor),
            bioTextView.trailingAnchor.constraint(equalTo: bioContainer.trailingAnchor),
            bioTextView.bottomAnchor.constraint(equalTo: bioContainer.bottomAnchor),
            bioPlaceholder.topAnchor.constraint(equalTo: bioContainer.topAnchor, constant: 10),
            bioPlaceholder.leadingAnchor.constraint(equalTo: bioContainer.leadingAnchor, constant: 12),
            bioPlaceholder.trailingAnchor.constraint(equalTo: bioContainer.trailingAnchor, constant: -12)
        ])

        cardStack.addArrangedSubview(fieldRow(title: "Имя", field: nameField))
        cardStack.addArrangedSubview(fieldRow(title: "Username", field: usernameField, prefix: "@"))
        cardStack.addArrangedSubview(fieldRow(title: "Bio", field: bioContainer))
        cardStack.addArrangedSubview(fieldRow(title: "Город", field: locationField))
        cardStack.addArrangedSubview(fieldRow(title: "Ссылка", field: websiteField))

        card.addSubview(cardStack)
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: card.topAnchor),
            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        return card
    }

    private func settingsCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 18

        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 8
        v.isLayoutMarginsRelativeArrangement = true
        v.directionalLayoutMargins = .init(top: 12, leading: 12, bottom: 12, trailing: 12)

        let settingsRow = menuRow(title: "Настройки", subtitle: "Уведомления, язык, тема", icon: "gearshape.fill")
        let privacyRow = menuRow(title: "Приватность", subtitle: "Кто видит профиль и карточки", icon: "lock.shield.fill")

        settingsRow.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        privacyRow.addTarget(self, action: #selector(openPrivacy), for: .touchUpInside)

        v.addArrangedSubview(settingsRow)
        v.addArrangedSubview(privacyRow)

        card.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: card.topAnchor),
            v.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            v.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        return card
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

    private func configureLogoutButton() {
        var config = UIButton.Configuration.filled()
        config.title = "Выйти из профиля"
        config.baseBackgroundColor = .systemRed
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        logoutButton.configuration = config
        logoutButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
    }

    private func configureTextField(_ field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.autocorrectionType = .no
        field.autocapitalizationType = .words
        field.delegate = self
        field.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
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

    private func fieldRow(title: String, field: UIView, prefix: String? = nil) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        let fieldContainer = UIStackView()
        fieldContainer.axis = .horizontal
        fieldContainer.alignment = .center
        fieldContainer.spacing = 6

        if let prefix {
            let prefixLabel = UILabel()
            prefixLabel.text = prefix
            prefixLabel.font = .systemFont(ofSize: 15, weight: .semibold)
            prefixLabel.textColor = .secondaryLabel
            fieldContainer.addArrangedSubview(prefixLabel)
        }

        fieldContainer.addArrangedSubview(field)

        let v = UIStackView(arrangedSubviews: [titleLabel, fieldContainer])
        v.axis = .vertical
        v.spacing = 6
        return v
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemRounded(ofSize: 18, weight: .bold)
        return l
    }

    private func menuRow(title: String, subtitle: String, icon: String) -> UIControl {
        let control = UIControl()
        control.backgroundColor = .systemBackground
        control.layer.cornerRadius = 14

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .systemTeal
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [iconView, textStack, UIView(), chevron])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10

        control.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: control.topAnchor, constant: 10),
            row.leadingAnchor.constraint(equalTo: control.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: control.trailingAnchor, constant: -12),
            row.bottomAnchor.constraint(equalTo: control.bottomAnchor, constant: -10)
        ])

        return control
    }

    // MARK: - Actions
    @objc private func textFieldChanged(_ sender: UITextField) {
        var draft = viewModel.state.draft
        if sender === nameField {
            draft.displayName = sender.text ?? ""
        } else if sender === usernameField {
            draft.username = sender.text ?? ""
        } else if sender === locationField {
            draft.location = sender.text ?? ""
        } else if sender === websiteField {
            draft.website = sender.text ?? ""
        }
        viewModel.updateDraft(draft)
    }

    func textViewDidChange(_ textView: UITextView) {
        bioPlaceholder.isHidden = !textView.text.isEmpty
        var draft = viewModel.state.draft
        draft.bio = textView.text ?? ""
        viewModel.updateDraft(draft)
    }

    @objc private func saveTapped() {
        view.endEditing(true)
        viewModel.saveTapped()
    }

    @objc private func changeAvatarTapped() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func logoutTapped() {
        let alert = UIAlertController(
            title: "Выйти из аккаунта?",
            message: "Вы сможете войти снова в любой момент.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Выйти", style: .destructive) { [weak self] _ in
            guard let self else { return }
            Task { [weak self] in
                do {
                    try await self?.authService.signOut()
                } catch {
                    self?.showError(error)
                }
            }
        })
        present(alert, animated: true)
    }

    @objc private func openSettings() {
        let vc = SettingsStubViewController(titleText: "Настройки")
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func openPrivacy() {
        let vc = SettingsStubViewController(titleText: "Приватность")
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Helpers
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: (error as? LocalizedError)?.errorDescription ?? error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }

    private static func makeHandle(from name: String, email: String?) -> String {
        if let email, let prefix = email.split(separator: "@").first {
            return String(prefix)
        }

        let cleaned = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        return cleaned.isEmpty ? "user" : cleaned
    }

    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        defer { picker.dismiss(animated: true) }
        guard let image = info[.originalImage] as? UIImage else { return }

        if let path = ProfileAvatarStore.shared.save(image: image, for: user.uid) {
            var draft = viewModel.state.draft
            draft.avatarPath = path
            viewModel.updateDraft(draft)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UIFont helper for rounded system design
private extension UIFont {
    static func systemRounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = base.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return base
    }
}
