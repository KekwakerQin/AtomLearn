import UIKit

final class CardsTitleHeaderView: UICollectionReusableView {
    static let reuseID = "CardsTitleHeaderView"

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .systemBackground

        titleLabel.text = "Карточки"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
    }

    static func preferredHeight() -> CGFloat { 44 }
}
