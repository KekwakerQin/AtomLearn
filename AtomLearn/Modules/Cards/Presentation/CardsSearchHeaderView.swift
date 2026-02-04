import UIKit

final class CardsSearchHeaderView: UICollectionReusableView {
    static let reuseID = "CardsSearchHeaderView"

    private let searchField = UISearchTextField()
    private let container = UIView()

    var onQueryChanged: ((String) -> Void)?
    var onEditingEnded: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        container.layer.cornerRadius = 14
        container.setContentCompressionResistancePriority(.required, for: .vertical)

        searchField.placeholder = "Поиск по карточкам и дневнику"
        searchField.autocorrectionType = .no
        searchField.returnKeyType = .done
        searchField.font = .systemFont(ofSize: 16, weight: .medium)
        searchField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        searchField.addTarget(self, action: #selector(editingEnded), for: .editingDidEnd)

        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(searchField)
        searchField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),

            searchField.topAnchor.constraint(equalTo: container.topAnchor, constant: 0),
            searchField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
            searchField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0),
            searchField.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 0),
            searchField.heightAnchor.constraint(greaterThanOrEqualToConstant: 12)
        ])
    }

    func configure(query: String) {
        if searchField.text != query {
            searchField.text = query
        }
    }

    func focus() {
        searchField.becomeFirstResponder()
    }

    override var isFocused: Bool { searchField.isFirstResponder }

    @objc private func textChanged() {
        onQueryChanged?(searchField.text ?? "")
    }

    @objc private func editingEnded() {
        onEditingEnded?()
    }

    static func preferredHeight() -> CGFloat { 48 }
}
