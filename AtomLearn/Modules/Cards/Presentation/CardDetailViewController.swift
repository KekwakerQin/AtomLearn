import UIKit

final class CardDetailViewController: UIViewController {
    private let card: Card
    private var isFrontVisible = true

    private let cardContainer = UIView()
    private let frontLabel = UILabel()
    private let backLabel = UILabel()
    private let hintLabel = UILabel()

    init(card: Card) {
        self.card = card
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Карточка"
        setupUI()
    }

    private func setupUI() {
        cardContainer.backgroundColor = .systemBackground
        cardContainer.layer.cornerRadius = 20
        cardContainer.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        cardContainer.layer.shadowOpacity = 1
        cardContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        cardContainer.layer.shadowRadius = 16
        cardContainer.translatesAutoresizingMaskIntoConstraints = false

        frontLabel.text = card.front
        frontLabel.font = .systemFont(ofSize: 20, weight: .bold)
        frontLabel.textAlignment = .center
        frontLabel.numberOfLines = 0

        backLabel.text = card.back
        backLabel.font = .systemFont(ofSize: 18, weight: .regular)
        backLabel.textAlignment = .center
        backLabel.numberOfLines = 0
        backLabel.isHidden = true

        hintLabel.text = "Нажми на карточку, чтобы перевернуть"
        hintLabel.font = .systemFont(ofSize: 12, weight: .medium)
        hintLabel.textColor = .secondaryLabel
        hintLabel.textAlignment = .center

        let contentStack = UIStackView(arrangedSubviews: [frontLabel, backLabel])
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        cardContainer.addSubview(contentStack)
        view.addSubview(cardContainer)
        view.addSubview(hintLabel)

        NSLayoutConstraint.activate([
            cardContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            cardContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cardContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            contentStack.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: -24),

            hintLabel.topAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: 16),
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(flipCard))
        cardContainer.addGestureRecognizer(tap)
        cardContainer.isUserInteractionEnabled = true
    }

    @objc private func flipCard() {
        let options: UIView.AnimationOptions = isFrontVisible ? .transitionFlipFromRight : .transitionFlipFromLeft
        UIView.transition(with: cardContainer, duration: 0.35, options: [options, .showHideTransitionViews]) {
            self.frontLabel.isHidden.toggle()
            self.backLabel.isHidden.toggle()
        }
        isFrontVisible.toggle()
    }
}
