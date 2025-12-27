import UIKit

final class CollaboratorsInputView: UIView {

    // MARK: UI
    private let uidField = UITextField()
    private let roleControl = UISegmentedControl(items: ["Viewer", "Editor"])
    private let addButton = UIButton(type: .system)

    private let listLabel = UILabel()
    private let listStack = UIStackView()

    // MARK: Callbacks
    var onAdd: ((String, BoardCollaboratorRole) -> Void)?
    var onRemoveAt: ((Int) -> Void)?

    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: Public API
    func render(items: [BoardCollaboratorDraft]) {
        listStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        listLabel.text = "Участники: \(items.count)"

        for (idx, item) in items.enumerated() {
            let row = makeRow(uid: item.uid, role: item.role, index: idx)
            listStack.addArrangedSubview(row)
        }
    }

    // MARK: Actions
    @objc private func addTapped() {
        let role: BoardCollaboratorRole = (roleControl.selectedSegmentIndex == 1) ? .editor : .viewer
        onAdd?(uidField.text ?? "", role)
        uidField.text = ""
    }

    // MARK: Private helpers
    private func configureUI() {
        uidField.borderStyle = .roundedRect
        uidField.placeholder = "UID участника"
        uidField.autocapitalizationType = .none

        roleControl.selectedSegmentIndex = 0

        addButton.setTitle("Добавить", for: .normal)
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        let topRow = UIStackView(arrangedSubviews: [uidField, addButton])
        topRow.axis = .horizontal
        topRow.spacing = 10
        addButton.setContentHuggingPriority(.required, for: .horizontal)

        listLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        listLabel.textColor = .secondaryLabel

        listStack.axis = .vertical
        listStack.spacing = 8

        let stack = UIStackView(arrangedSubviews: [
            topRow,
            roleControl,
            listLabel,
            listStack
        ])
        stack.axis = .vertical
        stack.spacing = 10

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func makeRow(uid: String, role: BoardCollaboratorRole, index: Int) -> UIView {
        let label = UILabel()
        label.text = "\(uid) • \(role.rawValue)"
        label.font = .systemFont(ofSize: 15, weight: .regular)

        let remove = UIButton(type: .system)
        remove.setTitle("Удалить", for: .normal)
        remove.addAction(UIAction { [weak self] _ in self?.onRemoveAt?(index) }, for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [label, remove])
        row.axis = .horizontal
        row.spacing = 10
        remove.setContentHuggingPriority(.required, for: .horizontal)
        return row
    }
}
