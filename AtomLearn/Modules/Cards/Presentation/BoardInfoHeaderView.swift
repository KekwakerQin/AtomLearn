import UIKit

final class BoardInfoHeaderView: UICollectionReusableView {
    static let reuseID = "BoardInfoHeaderView"

    private let titleLabel = UILabel()
    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let metaStack = UIStackView()
    private let studyButton = UIButton(type: .system)

    var onStudyTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .clear

        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowOffset = CGSize(width: 0, height: 6)
        card.layer.shadowRadius = 12
        card.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "Информация о борде"
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        // Use a rounded system font when available; fall back to the standard system font.
        let baseNameFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        if #available(iOS 13.0, *) {
            if let roundedDescriptor = baseNameFont.fontDescriptor.withDesign(.rounded) {
                nameLabel.font = UIFont(descriptor: roundedDescriptor, size: 22)
            } else {
                nameLabel.font = baseNameFont
            }
        } else {
            nameLabel.font = baseNameFont
        }
        nameLabel.numberOfLines = 2

        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 3

        metaStack.axis = .horizontal
        metaStack.spacing = 12
        metaStack.distribution = .fillEqually

        studyButton.setTitle("Учиться по этой доске", for: .normal)
        studyButton.setTitleColor(.white, for: .normal)
        studyButton.backgroundColor = .systemBlue
        studyButton.layer.cornerRadius = 12
        studyButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        studyButton.addTarget(self, action: #selector(studyTapped), for: .touchUpInside)

        let content = UIStackView(arrangedSubviews: [titleLabel, nameLabel, descriptionLabel, metaStack, studyButton])
        content.axis = .vertical
        content.spacing = 10
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = .init(top: 14, leading: 14, bottom: 14, trailing: 14)

        card.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false

        addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
    }

    func configure(board: Board) {
        nameLabel.text = board.title
        descriptionLabel.text = board.description.isEmpty ? "Описание пока не добавлено" : board.description

        metaStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        metaStack.addArrangedSubview(metaPill(title: "Создан", value: formatted(board.createdAt)))
        metaStack.addArrangedSubview(metaPill(title: "Участники", value: "\(1 + board.memberUIDs.count + board.editorUIDs.count)"))
    }

    private func metaPill(title: String, value: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.12)
        container.layer.cornerRadius = 12

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14, weight: .bold)
        valueLabel.textColor = .systemTeal

        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .center

        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])

        return container
    }

    @objc private func studyTapped() {
        onStudyTapped?()
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}
