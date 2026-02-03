import UIKit

final class StudySessionViewController: UIViewController {
    private let boardTitle: String
    private let store: StudySessionStore

    private var state: StudySessionState
    private var isFrontVisible = true

    // MARK: - UI
    private let headerLabel = UILabel()
    private let roundLabel = UILabel()
    private let progressLabel = UILabel()

    private let cardContainer = UIView()
    private let frontLabel = UILabel()
    private let backLabel = UILabel()

    private let hintLabel = UILabel()

    private let hardButton = UIButton(type: .system)
    private let easyButton = UIButton(type: .system)

    private let summaryView = UIView()
    private let summaryTitle = UILabel()
    private let summaryStats = UILabel()
    private let repeatButton = UIButton(type: .system)
    private let finishButton = UIButton(type: .system)

    init(state: StudySessionState, boardTitle: String, store: StudySessionStore = .shared) {
        self.state = state
        self.boardTitle = boardTitle
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Учёба"
        setupUI()
        render()
        persist()
    }

    private func setupUI() {
        headerLabel.text = boardTitle
        headerLabel.font = roundedSystemFont(ofSize: 22, weight: .bold)
        headerLabel.numberOfLines = 2

        roundLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        roundLabel.textColor = .secondaryLabel

        progressLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        progressLabel.textColor = .secondaryLabel

        let headerStack = UIStackView(arrangedSubviews: [headerLabel, roundLabel, progressLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 4

        cardContainer.backgroundColor = .systemBackground
        cardContainer.layer.cornerRadius = 20
        cardContainer.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        cardContainer.layer.shadowOpacity = 1
        cardContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        cardContainer.layer.shadowRadius = 16
        cardContainer.translatesAutoresizingMaskIntoConstraints = false

        frontLabel.font = .systemFont(ofSize: 20, weight: .bold)
        frontLabel.textAlignment = .center
        frontLabel.numberOfLines = 0

        backLabel.font = .systemFont(ofSize: 18, weight: .regular)
        backLabel.textAlignment = .center
        backLabel.numberOfLines = 0
        backLabel.isHidden = true

        let cardStack = UIStackView(arrangedSubviews: [frontLabel, backLabel])
        cardStack.axis = .vertical
        cardStack.alignment = .center
        cardStack.spacing = 8

        cardContainer.addSubview(cardStack)
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: 24),
            cardStack.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -16),
            cardStack.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: -24)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(flipCard))
        cardContainer.addGestureRecognizer(tap)

        hintLabel.text = "Нажми на карточку, чтобы перевернуть"
        hintLabel.font = .systemFont(ofSize: 12, weight: .medium)
        hintLabel.textColor = .secondaryLabel
        hintLabel.textAlignment = .center

        configureButton(hardButton, title: "Сложно", color: .systemRed)
        configureButton(easyButton, title: "Запомнил", color: .systemGreen)
        hardButton.addTarget(self, action: #selector(hardTapped), for: .touchUpInside)
        easyButton.addTarget(self, action: #selector(easyTapped), for: .touchUpInside)

        let buttons = UIStackView(arrangedSubviews: [hardButton, easyButton])
        buttons.axis = .horizontal
        buttons.spacing = 12
        buttons.distribution = .fillEqually

        let mainStack = UIStackView(arrangedSubviews: [headerStack, cardContainer, hintLabel, buttons])
        mainStack.axis = .vertical
        mainStack.spacing = 16

        view.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        setupSummaryView()
    }

    private func setupSummaryView() {
        summaryView.backgroundColor = .systemBackground
        summaryView.layer.cornerRadius = 20
        summaryView.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        summaryView.layer.shadowOpacity = 1
        summaryView.layer.shadowOffset = CGSize(width: 0, height: 8)
        summaryView.layer.shadowRadius = 16
        summaryView.isHidden = true

        summaryTitle.font = roundedSystemFont(ofSize: 22, weight: .bold)
        summaryTitle.textAlignment = .center

        summaryStats.font = .systemFont(ofSize: 14, weight: .regular)
        summaryStats.textColor = .secondaryLabel
        summaryStats.numberOfLines = 0
        summaryStats.textAlignment = .center

        configureButton(repeatButton, title: "Повторить сложные", color: .systemBlue)
        configureButton(finishButton, title: "Завершить", color: .systemGreen)
        repeatButton.addTarget(self, action: #selector(repeatHardTapped), for: .touchUpInside)
        finishButton.addTarget(self, action: #selector(finishTapped), for: .touchUpInside)

        let actions = UIStackView(arrangedSubviews: [repeatButton, finishButton])
        actions.axis = .vertical
        actions.spacing = 10

        let stack = UIStackView(arrangedSubviews: [summaryTitle, summaryStats, actions])
        stack.axis = .vertical
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = .init(top: 16, leading: 16, bottom: 16, trailing: 16)

        summaryView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: summaryView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: summaryView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: summaryView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: summaryView.bottomAnchor)
        ])

        view.addSubview(summaryView)
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            summaryView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            summaryView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            summaryView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func configureButton(_ button: UIButton, title: String, color: UIColor) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = color
        button.layer.cornerRadius = 14
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }

    private func render() {
        roundLabel.text = "Раунд \(state.round)"

        let total = state.cards.count
        if state.currentIndex < total {
            summaryView.isHidden = true
            cardContainer.isHidden = false
            hintLabel.isHidden = false
            hardButton.isHidden = false
            easyButton.isHidden = false

            let card = state.cards[state.currentIndex]
            frontLabel.text = card.front
            backLabel.text = card.back
            progressLabel.text = "\(state.currentIndex + 1) / \(max(total, 1))"

            if !isFrontVisible {
                frontLabel.isHidden = false
                backLabel.isHidden = true
                isFrontVisible = true
            }
        } else {
            showSummary()
        }
    }

    private func showSummary() {
        summaryView.isHidden = false
        cardContainer.isHidden = true
        hintLabel.isHidden = true
        hardButton.isHidden = true
        easyButton.isHidden = true

        let total = state.correctCount + state.wrongCount
        summaryTitle.text = state.hardCards.isEmpty ? "Сессия завершена" : "Раунд завершён"
        summaryStats.text = "Всего карточек: \(total)\nСложные: \(state.hardCards.count)\nЗапомнил: \(state.correctCount)"

        repeatButton.isHidden = state.hardCards.isEmpty
    }

    @objc private func flipCard() {
        guard state.currentIndex < state.cards.count else { return }
        let options: UIView.AnimationOptions = isFrontVisible ? .transitionFlipFromRight : .transitionFlipFromLeft
        UIView.transition(with: cardContainer, duration: 0.35, options: [options, .showHideTransitionViews]) {
            self.frontLabel.isHidden.toggle()
            self.backLabel.isHidden.toggle()
        }
        isFrontVisible.toggle()
    }

    @objc private func hardTapped() {
        markCurrent(isHard: true)
    }

    @objc private func easyTapped() {
        markCurrent(isHard: false)
    }

    private func markCurrent(isHard: Bool) {
        guard state.currentIndex < state.cards.count else { return }
        let card = state.cards[state.currentIndex]

        if isHard {
            state.hardCards.append(card)
            state.wrongCount += 1
        } else {
            state.correctCount += 1
        }

        state.currentIndex += 1
        persist()
        render()
    }

    @objc private func repeatHardTapped() {
        guard !state.hardCards.isEmpty else { return }
        state.cards = state.hardCards
        state.hardCards = []
        state.currentIndex = 0
        state.round += 1
        persist()
        render()
    }

    @objc private func finishTapped() {
        state.isCompleted = true
        persist()
        store.deleteSession(boardId: state.boardId)
        navigationController?.popViewController(animated: true)
    }

    private func persist() {
        store.save(state: state)
    }

    // MARK: - Fonts
    private func roundedSystemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = base.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        } else {
            return base
        }
    }
}
