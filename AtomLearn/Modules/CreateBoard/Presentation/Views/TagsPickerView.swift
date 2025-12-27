import UIKit

final class TagsPickerView: UIView {

    // MARK: UI
    private let inputField = UITextField()
    private let addButton = UIButton(type: .system)

    private let selectedLabel = UILabel()
    private let suggestedLabel = UILabel()

    private let selectedStack = UIStackView()
    private let suggestedStack = UIStackView()

    // MARK: Callbacks
    var onAddTag: ((String) -> Void)?
    var onRemoveTagAt: ((Int) -> Void)?

    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: Public API
    func render(selected: [String], suggested: [String]) {
        selectedStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        suggestedStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        selectedLabel.text = "Выбрано: \(selected.count)/5"

        for (index, tag) in selected.enumerated() {
            let b = chip(title: tag, style: .selected)
            b.addAction(UIAction { [weak self] _ in self?.onRemoveTagAt?(index) }, for: .touchUpInside)
            selectedStack.addArrangedSubview(b)
        }

        for tag in suggested {
            let b = chip(title: tag, style: .suggested)
            b.addAction(UIAction { [weak self] _ in self?.onAddTag?(tag) }, for: .touchUpInside)
            suggestedStack.addArrangedSubview(b)
        }
    }

    // MARK: Actions
    @objc private func addTapped() {
        onAddTag?(inputField.text ?? "")
        inputField.text = ""
    }

    // MARK: Private helpers
    private func configureUI() {
        inputField.borderStyle = .roundedRect
        inputField.placeholder = "Добавить тег"
        inputField.autocapitalizationType = .words

        addButton.setTitle("Добавить", for: .normal)
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [inputField, addButton])
        row.axis = .horizontal
        row.spacing = 10
        addButton.setContentHuggingPriority(.required, for: .horizontal)

        selectedLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        selectedLabel.textColor = .secondaryLabel

        suggestedLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        suggestedLabel.textColor = .secondaryLabel
        suggestedLabel.text = "Подсказки"

        selectedStack.axis = .horizontal
        selectedStack.spacing = 8
        selectedStack.alignment = .leading
        selectedStack.distribution = .fillProportionally

        suggestedStack.axis = .horizontal
        suggestedStack.spacing = 8
        suggestedStack.alignment = .leading
        suggestedStack.distribution = .fillProportionally

        let selectedScroll = horizontalScroll(with: selectedStack)
        let suggestedScroll = horizontalScroll(with: suggestedStack)

        let stack = UIStackView(arrangedSubviews: [
            row,
            selectedLabel,
            selectedScroll,
            suggestedLabel,
            suggestedScroll
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

    private func horizontalScroll(with content: UIStackView) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false

        scroll.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            content.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        ])

        scroll.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return scroll
    }

    private enum ChipStyle { case selected, suggested }

    private func chip(title: String, style: ChipStyle) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.cornerStyle = .capsule
        config.contentInsets = .init(top: 6, leading: 10, bottom: 6, trailing: 10)

        let b = UIButton(configuration: config)
        b.configuration?.baseForegroundColor = (style == .selected) ? .systemBackground : .label
        b.configuration?.baseBackgroundColor = (style == .selected) ? .systemBlue : .tertiarySystemFill
        return b
    }
}
