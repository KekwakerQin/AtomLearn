import UIKit

// Верхняя панель с заголовком и кнопками
final class TopBarView: UIView {
    // MARK: - Properties

    // Заголовок экрана
    let titleLabel = UILabel()
    // Кнопка добавления
    let addButton = UIButton(type: .system)
    // Кнопка сортировки
    let sortButton = UIButton(type: .system)

    // MARK: - Init
    // Инициализация и настройка UI
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "Мои доски"
        titleLabel.font = .boldSystemFont(ofSize: 20)

        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        sortButton.setTitle("Новые ↑", for: .normal)

        let stack = UIStackView(arrangedSubviews: [titleLabel, sortButton, addButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.distribution = .equalSpacing

        // Добавляем стек с элементами вью
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}
