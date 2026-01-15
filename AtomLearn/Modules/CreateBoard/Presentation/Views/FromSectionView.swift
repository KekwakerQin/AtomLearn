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
        layer.cornerRadius = 14
        backgroundColor = UIColor.secondarySystemBackground

        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        contentStack.axis = .vertical
        contentStack.spacing = 10

        let stack = UIStackView(arrangedSubviews: [titleLabel, contentStack])
        stack.axis = .vertical
        stack.spacing = 10

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
