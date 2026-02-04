import UIKit

final class CardPreviewViewController: UIViewController {
    private let card: Card

    private let backdrop = UIControl()
    private let container = UIView()
    private let titleLabel = UILabel()
    private let frontLabel = UILabel()
    private let backLabel = UILabel()
    private let tagsLabel = UILabel()
    private let flipButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    private var isFlipped = false

    init(card: Card) {
        self.card = card
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyContent(animated: false)
    }

    private func setupUI() {
        view.backgroundColor = .clear

        backdrop.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        backdrop.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)

        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 20
        container.layer.shadowColor = UIColor.black.withAlphaComponent(0.15).cgColor
        container.layer.shadowOpacity = 1
        container.layer.shadowOffset = CGSize(width: 0, height: 8)
        container.layer.shadowRadius = 16
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        titleLabel.text = "Карточка"
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let headerRow = UIStackView(arrangedSubviews: [titleLabel, UIView(), closeButton])
        headerRow.axis = .horizontal
        headerRow.alignment = .center

        frontLabel.font = .systemFont(ofSize: 20, weight: .bold)
        frontLabel.textColor = .label
        frontLabel.numberOfLines = 0

        backLabel.font = .systemFont(ofSize: 16, weight: .regular)
        backLabel.textColor = .secondaryLabel
        backLabel.numberOfLines = 0

        tagsLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        tagsLabel.textColor = .systemTeal
        tagsLabel.numberOfLines = 1

        flipButton.setTitle("Перевернуть", for: .normal)
        flipButton.setTitleColor(.white, for: .normal)
        flipButton.backgroundColor = .systemBlue
        flipButton.layer.cornerRadius = 12
        flipButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        flipButton.addTarget(self, action: #selector(flipTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [headerRow, frontLabel, backLabel, tagsLabel, flipButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = .init(top: 16, leading: 16, bottom: 16, trailing: 16)

        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    private func applyContent(animated: Bool) {
        frontLabel.text = card.front
        backLabel.text = card.back

        if card.tags.isEmpty {
            tagsLabel.isHidden = true
        } else {
            tagsLabel.isHidden = false
            tagsLabel.text = card.tags.map { "#\($0)" }.joined(separator: " ")
        }

        let update = {
            self.backLabel.isHidden = !self.isFlipped
            self.frontLabel.isHidden = self.isFlipped
            let title = self.isFlipped ? "Скрыть ответ" : "Перевернуть"
            self.flipButton.setTitle(title, for: .normal)
        }

        if animated {
            UIView.transition(with: container, duration: 0.25, options: .transitionCrossDissolve, animations: update)
        } else {
            update()
        }
    }

    @objc private func flipTapped() {
        isFlipped.toggle()
        applyContent(animated: true)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
