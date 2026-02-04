import UIKit

final class BoardsSessionsHeaderView: UICollectionReusableView {
    static let reuseID = "BoardsSessionsHeaderView"

    private let card = UIView()
    private let titleLabel = UILabel()
    private let stack = UIStackView()

    private var sessions: [StudySessionState] = []

    var onSessionTapped: ((StudySessionState) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .clear

        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 18
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)

        titleLabel.text = "Незавершенные сессии"
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)

        stack.axis = .vertical
        stack.spacing = 8

        let content = UIStackView(arrangedSubviews: [titleLabel, stack])
        content.axis = .vertical
        content.spacing = 12
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = .init(top: 12, leading: 12, bottom: 12, trailing: 12)

        card.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
    }

    func configure(sessions: [StudySessionState]) {
        self.sessions = sessions
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, session) in sessions.enumerated() {
            let row = sessionRow(session, index: index)
            stack.addArrangedSubview(row)
        }
    }

    private func sessionRow(_ session: StudySessionState, index: Int) -> UIControl {
        let control = UIButton(type: .system)
        control.backgroundColor = .systemBackground
        control.layer.cornerRadius = 12
        control.tag = index
        control.addTarget(self, action: #selector(sessionTapped(_:)), for: .touchUpInside)

        let title = UILabel()
        title.text = session.boardTitle ?? session.boardId
        title.font = .systemFont(ofSize: 15, weight: .semibold)
        title.textColor = .label

        let subtitle = UILabel()
        subtitle.text = "Раунд \(session.round) · \(session.currentIndex + 1)/\(max(session.cards.count, 1))"
        subtitle.font = .systemFont(ofSize: 12)
        subtitle.textColor = .secondaryLabel

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel

        let textStack = UIStackView(arrangedSubviews: [title, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 4

        let h = UIStackView(arrangedSubviews: [textStack, UIView(), chevron])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 8
        // Important: the button must receive taps; otherwise, the stack view becomes the hit-test target.
        h.isUserInteractionEnabled = false

        control.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            h.topAnchor.constraint(equalTo: control.topAnchor, constant: 10),
            h.leadingAnchor.constraint(equalTo: control.leadingAnchor, constant: 12),
            h.trailingAnchor.constraint(equalTo: control.trailingAnchor, constant: -12),
            h.bottomAnchor.constraint(equalTo: control.bottomAnchor, constant: -10)
        ])

        return control
    }

    @objc private func sessionTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index >= 0, index < sessions.count else { return }
        onSessionTapped?(sessions[index])
    }

    static func preferredHeight(for count: Int) -> CGFloat {
        guard count > 0 else { return 0 }
        let rowHeight: CGFloat = 56
        let rowSpacing: CGFloat = 8
        let titleHeight: CGFloat = 20
        let contentPadding: CGFloat = 24
        let topBottom: CGFloat = 16
        let rows = CGFloat(count) * rowHeight + CGFloat(max(count - 1, 0)) * rowSpacing
        let content = titleHeight + 12 + rows + contentPadding
        return content + topBottom
    }
}
