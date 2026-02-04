import UIKit

final class BoardsSearchHeaderView: UICollectionReusableView {
    static let reuseID = "BoardsSearchHeaderView"

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
        searchField.placeholder = "Поиск"
        searchField.autocorrectionType = .no
        searchField.returnKeyType = .done
        searchField.font = .systemFont(ofSize: 16, weight: .medium)
        searchField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        searchField.addTarget(self, action: #selector(editingEnded), for: .editingDidEnd)

        container.layer.cornerRadius = 14
        container.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(searchField)
        searchField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),

            searchField.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            searchField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            searchField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            searchField.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
            searchField.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
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

    static func preferredHeight() -> CGFloat { 80 }
}
