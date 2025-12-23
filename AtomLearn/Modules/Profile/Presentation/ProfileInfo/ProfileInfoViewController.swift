// Экран информации о пользователе
import UIKit
final class ProfileInfoViewController: UIViewController {
    // MARK: - Properties
    // Текущий пользователь
    private let user: AppUser
    init(user: AppUser) { self.user = user; super.init(nibName: nil, bundle: nil) }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    // Скролл-контейнер
    private let scroll = UIScrollView()
    // Стек для контента
    private let stack  = UIStackView()
    
    // MARK: - Lifecycle
    // Настройка экрана и заполнение данными
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

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
        stack.spacing = 12
        stack.alignment = .fill
        scroll.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
        ])

        // Пример наполняемого контента:
        let name = label("\(user.displayName ?? user.name)")
        let mail = label(user.email ?? "email не указан", color: .secondaryLabel)
        let bio  = label("Тут будет био/настройки/кнопки…")
        [name, mail, bio].forEach(stack.addArrangedSubview)
    }

    // MARK: - Helpers
    // Утилита для создания меток с заданным цветом
    private func label(_ text: String, color: UIColor = .label) -> UILabel {
        let l = UILabel()
        l.text = text
        l.textColor = color
        // Многострочный текст
        l.numberOfLines = 0
        return l
    }
}
