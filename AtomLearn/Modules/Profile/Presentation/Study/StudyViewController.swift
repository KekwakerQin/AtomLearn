import UIKit

// Экран «Учёба» — раздел с прогрессом и модулями
final class StudyViewController: UIViewController {
    // MARK: - Properties
    private let scroll = UIScrollView()
    private let stack  = UIStackView()
    private var activeSessions: [StudySessionState] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        buildContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rebuildContent()
    }

    // MARK: - Layout
    private func setupLayout() {
        scroll.alwaysBounceVertical = true
        scroll.keyboardDismissMode = .onDrag

        stack.axis = .vertical
        stack.spacing = 18
        stack.alignment = .fill

        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        scroll.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
        ])
    }

    // MARK: - Content
    private func buildContent() {
        stack.addArrangedSubview(heroCard())
        stack.addArrangedSubview(quickStatsRow())

        if let activeSection = activeSessionsSection() {
            stack.addArrangedSubview(sectionTitle("Незавершённые сессии"))
            stack.addArrangedSubview(activeSection)
        }

        stack.addArrangedSubview(sectionTitle("Сценарии"))
        stack.addArrangedSubview(modeCard(
            title: "Быстрый повтор",
            subtitle: "10–12 карточек за 5 минут",
            accent: UIColor.systemTeal,
            icon: "bolt.fill"
        ))
        stack.addArrangedSubview(modeCard(
            title: "Глубокий фокус",
            subtitle: "25 минут, интервальные повторы",
            accent: UIColor.systemOrange,
            icon: "timer"
        ))
        stack.addArrangedSubview(modeCard(
            title: "Экзамен",
            subtitle: "Смешанная сессия по всем темам",
            accent: UIColor.systemIndigo,
            icon: "graduationcap.fill"
        ))

        stack.addArrangedSubview(sectionTitle("План на неделю"))
        stack.addArrangedSubview(weekPlanRow())

        stack.addArrangedSubview(sectionTitle("Что дальше"))
        stack.addArrangedSubview(nextStepCard(
            title: "Продолжить: Анатомия • Модуль 3",
            subtitle: "Осталось 18 карточек"
        ))
    }

    private func activeSessionsSection() -> UIView? {
        let sessions = StudySessionStore.shared.fetchActiveSessions()
        guard !sessions.isEmpty else { return nil }
        activeSessions = sessions

        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 16

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = .init(top: 12, leading: 12, bottom: 12, trailing: 12)

        for (index, session) in sessions.enumerated() {
            let row = sessionRow(session, index: index)
            stack.addArrangedSubview(row)
        }

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

    private func sessionRow(_ session: StudySessionState, index: Int) -> UIControl {
        let control = UIButton(type: .system)
        control.layer.cornerRadius = 12
        control.backgroundColor = .systemBackground
        control.tag = index
        control.addTarget(self, action: #selector(activeSessionTapped(_:)), for: .touchUpInside)

        let title = UILabel()
        title.text = session.boardTitle ?? session.boardId
        title.font = .systemFont(ofSize: 15, weight: .semibold)
        title.textColor = .label

        let subtitle = UILabel()
        subtitle.text = "Раунд \(session.round) · \(session.currentIndex + 1)/\(max(session.cards.count, 1))"
        subtitle.font = .systemFont(ofSize: 12)
        subtitle.textColor = .secondaryLabel

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel

        let textStack = UIStackView(arrangedSubviews: [title, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 4

        let h = UIStackView(arrangedSubviews: [textStack, UIView(), chevron])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 8
        // Important: the button must receive taps; otherwise, the stack view becomes the hit-test target.
        h.isUserInteractionEnabled = false

        control.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            h.topAnchor.constraint(equalTo: control.topAnchor, constant: 10),
            h.leadingAnchor.constraint(equalTo: control.leadingAnchor, constant: 12),
            h.trailingAnchor.constraint(equalTo: control.trailingAnchor, constant: -12),
            h.bottomAnchor.constraint(equalTo: control.bottomAnchor, constant: -10)
        ])

        return control
    }

    @objc private func activeSessionTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index >= 0, index < activeSessions.count else { return }
        let session = activeSessions[index]
        let vc = StudySessionViewController(state: session, boardTitle: session.boardTitle ?? "Учёба")
        navigationController?.pushViewController(vc, animated: true)
    }

    private func rebuildContent() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buildContent()
    }

    // MARK: - UI Builders
    private func heroCard() -> UIView {
        let card = GradientCardView(colors: [
            UIColor(red: 0.17, green: 0.45, blue: 0.90, alpha: 1),
            UIColor(red: 0.11, green: 0.78, blue: 0.60, alpha: 1)
        ])
        card.layer.cornerRadius = 22
        card.clipsToBounds = true

        let title = UILabel()
        title.text = "Учёба"
        title.font = .systemRounded(ofSize: 28, weight: .bold)
        title.textColor = .white

        let subtitle = UILabel()
        subtitle.text = "Сегодня: 21 карточка · 2 модуля"
        subtitle.font = .systemFont(ofSize: 13, weight: .medium)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.85)

        let progress = UIProgressView(progressViewStyle: .default)
        progress.progress = 0.42
        progress.trackTintColor = UIColor.white.withAlphaComponent(0.25)
        progress.progressTintColor = .white

        let progressLabel = UILabel()
        progressLabel.text = "Прогресс дня 42%"
        progressLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        progressLabel.textColor = UIColor.white.withAlphaComponent(0.9)

        let startButton = UIButton(type: .system)
        startButton.setTitle("Начать сессию", for: .normal)
        startButton.setTitleColor(.systemBlue, for: .normal)
        startButton.backgroundColor = .white
        startButton.layer.cornerRadius = 14
        startButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        startButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        startButton.addAction(UIAction { _ in
            print("start study tapped")
        }, for: .touchUpInside)

        let v = UIStackView(arrangedSubviews: [title, subtitle, progress, progressLabel, startButton])
        v.axis = .vertical
        v.spacing = 10

        card.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            v.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            v.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            v.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    private func quickStatsRow() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.distribution = .fillEqually

        row.addArrangedSubview(statPill(title: "Серия", value: "7 дней", color: UIColor.systemTeal))
        row.addArrangedSubview(statPill(title: "Время", value: "28 мин", color: UIColor.systemOrange))
        row.addArrangedSubview(statPill(title: "Фокус", value: "82%", color: UIColor.systemBlue))

        return row
    }

    private func statPill(title: String, value: String, color: UIColor) -> UIView {
        let pill = UIView()
        pill.layer.cornerRadius = 16
        pill.backgroundColor = color.withAlphaComponent(0.12)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemRounded(ofSize: 16, weight: .bold)
        valueLabel.textColor = color

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 11, weight: .semibold)
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
        l.font = .systemRounded(ofSize: 18, weight: .bold)
        return l
    }

    private func modeCard(title: String, subtitle: String, accent: UIColor, icon: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 16

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = accent
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let h = UIStackView(arrangedSubviews: [iconView, textStack, UIView(), chevron])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 10

        card.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            h.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            h.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            h.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            h.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        return card
    }

    private func weekPlanRow() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually

        let days = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
        for (index, day) in days.enumerated() {
            let isToday = index == 2
            let pill = UILabel()
            pill.text = day
            pill.textAlignment = .center
            pill.font = .systemFont(ofSize: 12, weight: .semibold)
            pill.backgroundColor = isToday ? UIColor.systemBlue : UIColor.secondarySystemBackground
            pill.textColor = isToday ? .white : .label
            pill.layer.cornerRadius = 12
            pill.clipsToBounds = true
            pill.heightAnchor.constraint(equalToConstant: 28).isActive = true
            row.addArrangedSubview(pill)
        }

        return row
    }

    private func nextStepCard(title: String, subtitle: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 16

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 2

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel

        let v = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        v.axis = .vertical
        v.spacing = 4

        card.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            v.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            v.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            v.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        return card
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

// MARK: - UIFont helpers
private extension UIFont {
    static func systemRounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        if let roundedDescriptor = base.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: roundedDescriptor, size: size)
        } else {
            return base
        }
    }
}
