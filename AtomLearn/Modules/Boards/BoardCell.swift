import UIKit

// Ячейка доски в сетке
final class BoardGridCell: UICollectionViewCell {
    static let reuseID = "BoardGridCell"

    private let card = UIView()
    private let title = UILabel()
    private let subtitle = UILabel()
    private let metaStack = UIStackView()
    private let badgeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        card.layer.cornerRadius = 18
        card.backgroundColor = .secondarySystemBackground
        card.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowOffset = CGSize(width: 0, height: 6)
        card.layer.shadowRadius = 12

        title.font = .systemFont(ofSize: 17, weight: .bold)
        title.numberOfLines = 2

        subtitle.font = .systemFont(ofSize: 12)
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 2

        badgeLabel.font = .systemFont(ofSize: 11, weight: .bold)
        badgeLabel.textColor = .systemBlue
        badgeLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        badgeLabel.layer.cornerRadius = 10
        badgeLabel.clipsToBounds = true
        badgeLabel.textAlignment = .center

        metaStack.axis = .horizontal
        metaStack.spacing = 8
        metaStack.distribution = .fillProportionally

        let topRow = UIStackView(arrangedSubviews: [title, badgeLabel])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 8

        let stack = UIStackView(arrangedSubviews: [topRow, subtitle, metaStack])
        stack.axis = .vertical
        stack.spacing = 8
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = .init(top: 12, leading: 12, bottom: 12, trailing: 12)

        contentView.addSubview(card)
        card.addSubview(stack)

        card.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func configure(_ board: Board) {
        title.text = board.title
        subtitle.text = board.description.isEmpty
            ? DateFormatter.localizedString(from: board.createdAt, dateStyle: .medium, timeStyle: .short)
            : board.description

        let members = 1 + board.memberUIDs.count + board.editorUIDs.count
        badgeLabel.text = " \(members) "

        metaStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        metaStack.addArrangedSubview(metaPill(text: "Участники: \(members)"))
        if let last = board.lastActivityAt {
            metaStack.addArrangedSubview(metaPill(text: "Активность: \(format(last))"))
        } else {
            metaStack.addArrangedSubview(metaPill(text: "Новая"))
        }
    }

    private func metaPill(text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1

        let pill = UIView()
        pill.backgroundColor = UIColor.systemBackground
        pill.layer.cornerRadius = 10
        pill.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: pill.topAnchor, constant: 4),
            label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -8),
            label.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -4)
        ])
        return pill
    }

    private func format(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: date)
    }
}
