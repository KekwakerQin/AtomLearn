import UIKit

final class FormSectionView: UIView {

    // MARK: UI
    private let titleLabel = UILabel()
    private let contentStack = UIStackView()

    // MARK: Init
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: Public API
    func addArranged(_ view: UIView) {
        contentStack.addArrangedSubview(view)
    }

    // MARK: Private helpers
    private func configureUI() {
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor.separator.withAlphaComponent(0.3).cgColor
        layer.shadowColor = UIColor.black.withAlphaComponent(0.04).cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 10
        backgroundColor = UIColor.systemBackground

        titleLabel.font = .systemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = .secondaryLabel

        contentStack.axis = .vertical
        contentStack.spacing = 12

        let stack = UIStackView(arrangedSubviews: [titleLabel, contentStack])
        stack.axis = .vertical
        stack.spacing = 8

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }
}
