import UIKit

final class FormTextFieldView: UIView, UITextFieldDelegate {

    // MARK: UI
    private let titleLabel = UILabel()
    let textField = UITextField()
    private let helperLabel = UILabel()

    // MARK: Init
    init(
        title: String,
        placeholder: String,
        helper: String
    ) {
        super.init(frame: .zero)
        titleLabel.text = title
        textField.placeholder = placeholder
        helperLabel.text = helper
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: Private helpers
    private func configureUI() {
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 17)
        textField.clearButtonMode = .whileEditing
        textField.delegate = self

        helperLabel.font = .systemFont(ofSize: 13, weight: .regular)
        helperLabel.textColor = .secondaryLabel
        helperLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, textField, helperLabel])
        stack.axis = .vertical
        stack.spacing = 6

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
