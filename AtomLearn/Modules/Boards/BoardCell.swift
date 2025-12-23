// BoardGridCell.swift
import UIKit

// Ячейка доски в сетке
final class BoardGridCell: UICollectionViewCell {
    // MARK: - Properties

    // Идентификатор для переиспользования
    static let reuseID = "BoardGridCell"

    // Заголовок доски
    private let title = UILabel()
    // Подзаголовок или описание
    private let subtitle = UILabel()
    // Контейнер-карточка
    private let card = UIView()

    // MARK: - Init
    // Настройка внешнего вида и иерархии
    override init(frame: CGRect) {
        super.init(frame: frame)

        card.layer.cornerRadius = 14
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.separator.cgColor
        card.backgroundColor = .secondarySystemBackground

        title.font = .systemFont(ofSize: 16, weight: .semibold)
        title.numberOfLines = 2
        subtitle.font = .systemFont(ofSize: 12)
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 2

        contentView.addSubview(card)
        let stack = UIStackView(arrangedSubviews: [title, subtitle])
        stack.axis = .vertical; stack.spacing = 6
        card.addSubview(stack)

        card.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configuration
    // Настройка содержимого ячейки данными борда
    func configure(_ board: Board) {
        title.text = board.title
        subtitle.text = board.description.isEmpty
            ? DateFormatter.localizedString(from: board.createdAt, dateStyle: .medium, timeStyle: .short)
            : board.description
    }
}
