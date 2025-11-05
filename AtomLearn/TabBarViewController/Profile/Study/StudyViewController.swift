import UIKit

// Экран «Учёба» — раздел с прогрессом и модулями
final class StudyViewController: UIViewController {
    // MARK: - Properties

    // Скролл-контейнер для вертикальной прокрутки
    private let scroll = UIScrollView()
    // Вертикальный стек для размещения элементов
    private let stack  = UIStackView()

    // MARK: - Lifecycle
    // Настройка экрана и построение контента
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        buildContent()
    }

    // MARK: - Layout
    // Настройка верстки и ограничений
    private func setupLayout() {
        scroll.alwaysBounceVertical = true
        scroll.keyboardDismissMode = .onDrag

        stack.axis = .vertical
        stack.spacing = 16
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
    // Формирование контента экрана (заглушки)
    private func buildContent() {
        // Заголовок
        stack.addArrangedSubview(titleLabel("Учёба"))

        // Прогресс (заглушка)
        stack.addArrangedSubview(progressCard(title: "Сегодня", progress: 0.42, subtitle: "Карточек выучено: 21/50"))

        // Ближайшие модули / курсы (заглушка)
        stack.addArrangedSubview(sectionHeader("Модули"))
        let modules = [
            ("Алгебра • Глава 3", "15 карточек · повторить до 20:00"),
            ("Английский • Phrasal Verbs", "10 карточек · streak 5 дней"),
            ("История • Петр I", "25 карточек · новый модуль")
        ]
        modules.forEach { stack.addArrangedSubview(moduleRow(title: $0.0, subtitle: $0.1)) }

        // Кнопки действий
        let actions = UIStackView()
        actions.axis = .horizontal
        actions.spacing = 12
        actions.distribution = .fillEqually
        let reviewBtn = primaryButton("Повторить")
        let addBtn    = secondaryButton("Добавить модуль")
        actions.addArrangedSubview(reviewBtn)
        actions.addArrangedSubview(addBtn)
        stack.addArrangedSubview(actions)

        // Обработчики нажатий (заглушки)
        reviewBtn.addAction(UIAction { _ in
            // TODO: открыть экран повторения/сессии
            print("start review tapped")
        }, for: .touchUpInside)

        addBtn.addAction(UIAction { _ in
            // TODO: открыть создание модуля
            print("add module tapped")
        }, for: .touchUpInside)
    }

    // MARK: - UI Builders

    // Заголовок раздела
    private func titleLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.numberOfLines = 0
        return l
    }

    // Подзаголовок раздела
    private func sectionHeader(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        return l
    }

    // Карточка прогресса
    private func progressCard(title: String, progress: Float, subtitle: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 14

        let t = UILabel(); t.text = title; t.font = .systemFont(ofSize: 16, weight: .semibold)
        let s = UILabel(); s.text = subtitle; s.textColor = .secondaryLabel; s.numberOfLines = 2

        let bar = UIProgressView(progressViewStyle: .default)
        bar.progress = progress

        let vstack = UIStackView(arrangedSubviews: [t, bar, s])
        vstack.axis = .vertical; vstack.spacing = 8

        card.addSubview(vstack)
        vstack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            vstack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            vstack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            vstack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
        ])
        return card
    }

    // Элемент списка модулей
    private func moduleRow(title: String, subtitle: String) -> UIView {
        let row = UIView()
        row.layer.cornerRadius = 12
        row.layer.borderWidth = 1
        row.layer.borderColor = UIColor.separator.cgColor
        row.backgroundColor = .systemBackground

        let t = UILabel(); t.text = title; t.font = .systemFont(ofSize: 16, weight: .medium); t.numberOfLines = 2
        let s = UILabel(); s.text = subtitle; s.textColor = .secondaryLabel; s.numberOfLines = 2

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let v = UIStackView(arrangedSubviews: [t, s])
        v.axis = .vertical; v.spacing = 4

        let h = UIStackView(arrangedSubviews: [v, chevron])
        h.axis = .horizontal; h.alignment = .center; h.spacing = 12

        row.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            h.topAnchor.constraint(equalTo: row.topAnchor, constant: 12),
            h.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 12),
            h.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -12),
            h.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -12),
        ])

        // Тап по строке (заглушка)
        let tap = UITapGestureRecognizer(target: self, action: #selector(moduleTapped(_:)))
        row.addGestureRecognizer(tap)
        return row
    }

    // MARK: - Actions
    // Обработка нажатия на модуль (заглушка)
    @objc private func moduleTapped(_ gr: UITapGestureRecognizer) {
        // TODO: навигация к модулю
        print("module tapped")
    }

    // Кнопка основного действия
    private func primaryButton(_ title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .systemBlue
        b.layer.cornerRadius = 12
        b.heightAnchor.constraint(equalToConstant: 46).isActive = true
        return b
    }

    // Кнопка вторичного действия
    private func secondaryButton(_ title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(.label, for: .normal)
        b.backgroundColor = .secondarySystemBackground
        b.layer.cornerRadius = 12
        b.heightAnchor.constraint(equalToConstant: 46).isActive = true
        return b
    }
}
