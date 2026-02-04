import UIKit

// Экран информации о пользователе (публичный вид профиля)
final class ProfileInfoViewController: UIViewController {

    // MARK: - Dependencies
    private let user: AppUser
    private let viewModel: ProfileInfoViewModel

    // MARK: - UI
    private let scroll = UIScrollView()
    private let stack  = UIStackView()

    private let avatarView = AvatarView()
    private let nameLabel = UILabel()
    private let handleLabel = UILabel()
    private let taglineLabel = UILabel()
    private let bioLabel = UILabel()

    private var draft: ProfileDraft?

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
        buildContent()
        bind()
        render(from: nil)
        viewModel.onViewDidLoad(userId: user.uid)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.onViewDidLoad(userId: user.uid)
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
        stack.spacing = 16
        stack.alignment = .fill
        scroll.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
        ])
    }

    private func buildContent() {
        stack.addArrangedSubview(profileHeader())
        stack.addArrangedSubview(statsRow())

        stack.addArrangedSubview(sectionTitle("О себе"))
        stack.addArrangedSubview(infoCard(label: bioLabel))

        stack.addArrangedSubview(sectionTitle("Достижения"))
        stack.addArrangedSubview(achievementsRow())

        stack.addArrangedSubview(sectionTitle("Активность"))
        stack.addArrangedSubview(activityRow(title: "Стабильность", subtitle: "7 дней подряд без пропусков", accent: UIColor.systemTeal))
        stack.addArrangedSubview(activityRow(title: "Фокус", subtitle: "23 карточки за утреннюю сессию", accent: UIColor.systemOrange))
        stack.addArrangedSubview(activityRow(title: "Новые темы", subtitle: "Анатомия • 3 модуля", accent: UIColor.systemGreen))
    }

    private func bind() {
        viewModel.onProfileUpdated = { [weak self] draft in
            self?.render(from: draft)
        }
        viewModel.onError = { [weak self] error in
            self?.showError(error)
        }
    }

    private func render(from draft: ProfileDraft?) {
        self.draft = draft

        let displayName = draft?.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        ? (draft?.displayName ?? user.name)
        : (user.displayName ?? user.name)

        let handle = draft?.username.isEmpty == false
        ? "@\(draft?.username ?? "user")"
        : "@\(makeHandle(from: displayName, email: user.email))"

        nameLabel.text = displayName
        handleLabel.text = handle
        taglineLabel.text = "Продуктовое мышление • Спринты по 20 минут"

        bioLabel.text = draft?.bio.isEmpty == false
        ? draft?.bio
        : "Добавь описание профиля"
        bioLabel.textColor = (draft?.bio.isEmpty == false) ? .label : .secondaryLabel

        let image = ProfileAvatarStore.shared.loadImage(path: draft?.avatarPath)
        avatarView.configure(name: displayName, image: image)
    }

    // MARK: - UI Builders
    private func profileHeader() -> UIView {
        let card = GradientCardView(colors: [
            UIColor(red: 0.12, green: 0.62, blue: 0.72, alpha: 1),
            UIColor(red: 0.98, green: 0.77, blue: 0.40, alpha: 1)
        ])
        card.layer.cornerRadius = 22
        card.clipsToBounds = true

        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.layer.cornerRadius = 32
        avatarView.clipsToBounds = true

        nameLabel.textColor = .white
        nameLabel.font = UIFont.systemRounded(ofSize: 26, weight: .bold)

        handleLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        handleLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        taglineLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        taglineLabel.font = .systemFont(ofSize: 13, weight: .medium)
        taglineLabel.numberOfLines = 2

        let vStack = UIStackView(arrangedSubviews: [nameLabel, handleLabel, taglineLabel])
        vStack.axis = .vertical
        vStack.spacing = 6

        let hStack = UIStackView(arrangedSubviews: [avatarView, vStack])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 12

        card.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 64),
            avatarView.heightAnchor.constraint(equalToConstant: 64),
            hStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    private func statsRow() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.distribution = .fillEqually

        row.addArrangedSubview(statPill(title: "Карточек", value: "128", color: UIColor.systemTeal, tag: 0))
        row.addArrangedSubview(statPill(title: "Сессий", value: "34", color: UIColor.systemOrange, tag: 1))
        row.addArrangedSubview(statPill(title: "Streak", value: "7", color: UIColor.systemGreen, tag: 2))

        return row
    }

    private func statPill(title: String, value: String, color: UIColor, tag: Int) -> UIControl {
        let pill = UIControl()
        pill.layer.cornerRadius = 16
        pill.backgroundColor = color.withAlphaComponent(0.15)
        pill.tag = tag
        pill.addTarget(self, action: #selector(statTapped(_:)), for: .touchUpInside)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemRounded(ofSize: 18, weight: .bold)
        valueLabel.textColor = color

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        let v = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        v.axis = .vertical
        v.spacing = 2
        v.alignment = .center

        pill.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: pill.topAnchor, constant: 10),
            v.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 8),
            v.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -8),
            v.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -10)
        ])

        return pill
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemRounded(ofSize: 18, weight: .bold)
        return l
    }

    private func infoCard(label: UILabel) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 16

        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14, weight: .regular)

        card.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        return card
    }

    private func achievementsRow() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually

        row.addArrangedSubview(achievementChip(text: "Быстрый старт", icon: "bolt.fill", tag: 0))
        row.addArrangedSubview(achievementChip(text: "Марафон", icon: "flame.fill", tag: 1))
        row.addArrangedSubview(achievementChip(text: "Рефлексия", icon: "sparkles", tag: 2))

        return row
    }

    private func achievementChip(text: String, icon: String, tag: Int) -> UIControl {
        let chip = UIControl()
        chip.backgroundColor = .secondarySystemBackground
        chip.layer.cornerRadius = 14
        chip.tag = tag
        chip.addTarget(self, action: #selector(achievementTapped(_:)), for: .touchUpInside)

        let imageView = UIImageView(image: UIImage(systemName: icon))
        imageView.tintColor = .systemIndigo
        imageView.setContentHuggingPriority(.required, for: .horizontal)

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2

        let h = UIStackView(arrangedSubviews: [imageView, label])
        h.axis = .horizontal
        h.spacing = 6
        h.alignment = .center

        chip.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            h.topAnchor.constraint(equalTo: chip.topAnchor, constant: 8),
            h.leadingAnchor.constraint(equalTo: chip.leadingAnchor, constant: 10),
            h.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -10),
            h.bottomAnchor.constraint(equalTo: chip.bottomAnchor, constant: -8)
        ])

        return chip
    }

    private func activityRow(title: String, subtitle: String, accent: UIColor) -> UIControl {
        let row = UIControl()
        row.backgroundColor = .secondarySystemBackground
        row.layer.cornerRadius = 14
        row.addTarget(self, action: #selector(activityTapped(_:)), for: .touchUpInside)

        let dot = UIView()
        dot.backgroundColor = accent
        dot.layer.cornerRadius = 6
        dot.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        let v = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        v.axis = .vertical
        v.spacing = 4

        let h = UIStackView(arrangedSubviews: [dot, v])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 10

        row.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 12),
            dot.heightAnchor.constraint(equalToConstant: 12),
            h.topAnchor.constraint(equalTo: row.topAnchor, constant: 12),
            h.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 12),
            h.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -12),
            h.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -12)
        ])

        return row
    }

    // MARK: - Actions
    @objc private func statTapped(_ sender: UIControl) {
        let messages = [
            "Количество карточек, которые ты создал(а) и добавил(а) в избранное.",
            "Число завершённых учебных сессий.",
            "Серия дней без пропусков."
        ]
        let index = min(sender.tag, messages.count - 1)
        showInfo(title: "Статистика", message: messages[index])
    }

    @objc private func achievementTapped(_ sender: UIControl) {
        let messages = [
            "Быстрый старт: 10 карточек в первые 24 часа.",
            "Марафон: 7 дней подряд с учебой.",
            "Рефлексия: добавлено 5 заметок к карточкам."
        ]
        let index = min(sender.tag, messages.count - 1)
        showInfo(title: "Достижение", message: messages[index])
    }

    @objc private func activityTapped(_ sender: UIControl) {
        showInfo(title: "Активность", message: "Детали активности будут отображаться здесь.")
    }

    private func showInfo(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Helpers
    private func makeHandle(from name: String, email: String?) -> String {
        if let email, let prefix = email.split(separator: "@").first {
            return String(prefix)
        }

        let cleaned = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        return cleaned.isEmpty ? "user" : cleaned
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

private final class GradientCardView: UIView {
    private let gradientLayer = CAGradientLayer()

    init(colors: [UIColor]) {
        super.init(frame: .zero)
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

private extension UIFont {
    static func systemRounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = base.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return base
    }
}
