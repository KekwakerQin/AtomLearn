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
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        textField.borderStyle = .none
        textField.font = .systemFont(ofSize: 16)
        textField.clearButtonMode = .whileEditing
        textField.delegate = self
        textField.backgroundColor = .secondarySystemBackground
        textField.layer.cornerRadius = 12
        textField.layer.borderColor = UIColor.separator.cgColor
        textField.layer.borderWidth = 1
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        textField.leftViewMode = .always

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
