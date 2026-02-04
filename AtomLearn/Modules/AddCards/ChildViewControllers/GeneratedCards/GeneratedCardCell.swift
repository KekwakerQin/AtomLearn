import UIKit

final class GeneratedCardCell: UITableViewCell {
    private let cardView = UIView()
    private let frontLabel = UILabel()
    private let backLabel = UILabel()
    private let tagsLabel = UILabel()
    private let statusPill = UILabel()
    private let selectButton = UIButton(type: .system)

    var onToggleSelection: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.withAlphaComponent(0.06).cgColor
        cardView.layer.shadowOpacity = 1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 6)
        cardView.layer.shadowRadius = 10

        frontLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        frontLabel.numberOfLines = 0

        backLabel.font = .systemFont(ofSize: 14)
        backLabel.textColor = .secondaryLabel
        backLabel.numberOfLines = 0

        tagsLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        tagsLabel.textColor = .systemTeal
        tagsLabel.numberOfLines = 1

        statusPill.font = .systemFont(ofSize: 11, weight: .bold)
        statusPill.textAlignment = .center
        statusPill.layer.cornerRadius = 10
        statusPill.clipsToBounds = true
        statusPill.setContentHuggingPriority(.required, for: .horizontal)

        selectButton.addTarget(self, action: #selector(selectionTapped), for: .touchUpInside)
        selectButton.setContentHuggingPriority(.required, for: .horizontal)

        let headerStack = UIStackView(arrangedSubviews: [selectButton, frontLabel, statusPill])
        headerStack.axis = .horizontal
        headerStack.alignment = .top
        headerStack.spacing = 8

        let contentStack = UIStackView(arrangedSubviews: [headerStack, backLabel, tagsLabel])
        contentStack.axis = .vertical
        contentStack.spacing = 8

        contentView.addSubview(cardView)
        cardView.addSubview(contentStack)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func configure(with item: GeneratedCardItem) {
        frontLabel.text = item.draft.front
        backLabel.text = item.draft.back

        if item.draft.tags.isEmpty {
            tagsLabel.isHidden = true
        } else {
            tagsLabel.isHidden = false
            tagsLabel.text = item.draft.tags.map { "#\($0)" }.joined(separator: " ")
        }

        backLabel.isHidden = !item.isExpanded

        switch item.status {
        case .pending:
            statusPill.isHidden = true
        case .added:
            statusPill.isHidden = false
            statusPill.text = "Добавлено"
            statusPill.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.18)
            statusPill.textColor = .systemGreen
        case .skipped:
            statusPill.isHidden = false
            statusPill.text = "Пропущено"
            statusPill.backgroundColor = UIColor.systemGray.withAlphaComponent(0.18)
            statusPill.textColor = .systemGray
        }

        let isSelectable = item.status == .pending
        selectButton.isEnabled = isSelectable
        selectButton.alpha = isSelectable ? 1 : 0.4
        let imageName = item.isSelected ? "checkmark.circle.fill" : "circle"
        selectButton.setImage(UIImage(systemName: imageName), for: .normal)
        selectButton.tintColor = item.isSelected ? .systemBlue : .tertiaryLabel
    }

    @objc private func selectionTapped() { onToggleSelection?() }
}
