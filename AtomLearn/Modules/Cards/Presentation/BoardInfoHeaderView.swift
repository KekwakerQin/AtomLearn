import UIKit

final class BoardInfoHeaderView: UICollectionReusableView {
    static let reuseID = "BoardInfoHeaderView"

    private let titleLabel = UILabel()
    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let metaStack = UIStackView()
    private let studyButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)

    private let rootStack = UIStackView()
    private let infoCard = UIView()

    private let diaryTitleLabel = UILabel()
    private let diaryCard = UIView()
    private let diaryStack = UIStackView()

    private var documents: [BoardDocument] = []

    var onStudyTapped: (() -> Void)?
    var onSettingsTapped: (() -> Void)?
    var onDocumentTapped: ((BoardDocument) -> Void)?
    var onDocumentRename: ((BoardDocument) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .clear

        rootStack.axis = .vertical
        rootStack.spacing = 12
        rootStack.alignment = .fill
        rootStack.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(rootStack)
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            rootStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        setupInfoCard()
        setupDiarySection()

        rootStack.addArrangedSubview(infoCard)
        rootStack.addArrangedSubview(diaryTitleLabel)
        rootStack.addArrangedSubview(diaryCard)
    }

    private func setupInfoCard() {
        infoCard.backgroundColor = .systemBackground
        infoCard.layer.cornerRadius = 18
        infoCard.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        infoCard.layer.shadowOpacity = 1
        infoCard.layer.shadowOffset = CGSize(width: 0, height: 6)
        infoCard.layer.shadowRadius = 12

        titleLabel.text = "Информация о борде"
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        settingsButton.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        settingsButton.tintColor = .systemBlue
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        settingsButton.setContentHuggingPriority(.required, for: .horizontal)
        settingsButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        settingsButton.widthAnchor.constraint(equalToConstant: 28).isActive = true
        settingsButton.heightAnchor.constraint(equalToConstant: 28).isActive = true

        let baseNameFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        if #available(iOS 13.0, *) {
            if let roundedDescriptor = baseNameFont.fontDescriptor.withDesign(.rounded) {
                nameLabel.font = UIFont(descriptor: roundedDescriptor, size: 22)
            } else {
                nameLabel.font = baseNameFont
            }
        } else {
            nameLabel.font = baseNameFont
        }
        nameLabel.numberOfLines = 2
        nameLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 3
        descriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        metaStack.axis = .horizontal
        metaStack.spacing = 12
        metaStack.distribution = .fillEqually
        metaStack.setContentCompressionResistancePriority(.required, for: .vertical)

        studyButton.setTitle("Учиться по этой доске", for: .normal)
        studyButton.setTitleColor(.white, for: .normal)
        studyButton.backgroundColor = .systemBlue
        studyButton.layer.cornerRadius = 12
        studyButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        studyButton.addTarget(self, action: #selector(studyTapped), for: .touchUpInside)
        studyButton.setContentCompressionResistancePriority(.required, for: .vertical)

        let headerRow = UIStackView(arrangedSubviews: [titleLabel, UIView(), settingsButton])
        headerRow.axis = .horizontal
        headerRow.alignment = .center

        let content = UIStackView(arrangedSubviews: [headerRow, nameLabel, descriptionLabel, metaStack, studyButton])
        content.axis = .vertical
        content.spacing = 10
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = .init(top: 14, leading: 14, bottom: 14, trailing: 14)
        content.setContentCompressionResistancePriority(.required, for: .vertical)

        infoCard.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: infoCard.topAnchor),
            content.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor)
        ])
    }

    private func setupDiarySection() {
        diaryTitleLabel.text = "Дневник"
        diaryTitleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        diaryTitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        diaryCard.backgroundColor = .secondarySystemBackground
        diaryCard.layer.cornerRadius = 18
        diaryCard.isUserInteractionEnabled = true

        diaryStack.axis = .vertical
        diaryStack.spacing = 8
        diaryStack.isLayoutMarginsRelativeArrangement = true
        diaryStack.directionalLayoutMargins = .init(top: 12, leading: 12, bottom: 12, trailing: 12)
        diaryStack.isUserInteractionEnabled = true

        diaryCard.addSubview(diaryStack)
        diaryStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            diaryStack.topAnchor.constraint(equalTo: diaryCard.topAnchor),
            diaryStack.leadingAnchor.constraint(equalTo: diaryCard.leadingAnchor),
            diaryStack.trailingAnchor.constraint(equalTo: diaryCard.trailingAnchor),
            diaryStack.bottomAnchor.constraint(equalTo: diaryCard.bottomAnchor)
        ])
    }

    func configure(board: Board, documents: [BoardDocument]) {
        nameLabel.text = board.title
        descriptionLabel.text = board.description.isEmpty ? "Описание пока не добавлено" : board.description

        metaStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        metaStack.addArrangedSubview(metaPill(title: "Создан", value: formatted(board.createdAt)))
        metaStack.addArrangedSubview(metaPill(title: "Участники", value: "\(1 + board.memberUIDs.count + board.editorUIDs.count)"))

        self.documents = documents
        rebuildDiary()
    }

    private func rebuildDiary() {
        diaryStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard !documents.isEmpty else {
            let empty = UILabel()
            empty.text = "Здесь пока ничего нет"
            empty.font = .systemFont(ofSize: 14, weight: .medium)
            empty.textColor = .secondaryLabel
            empty.numberOfLines = 2
            empty.textAlignment = .center
            empty.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
            diaryStack.addArrangedSubview(empty)
            return
        }

        for (index, doc) in documents.enumerated() {
            let row = diaryRow(document: doc, index: index)
            diaryStack.addArrangedSubview(row)
        }
    }

    private func diaryRow(document: BoardDocument, index: Int) -> UIView {
        let control = UIControl()
        control.backgroundColor = .systemBackground
        control.layer.cornerRadius = 12
        control.tag = index
        control.addTarget(self, action: #selector(documentTapped(_:)), for: .touchUpInside)

        let title = UILabel()
        title.text = document.title
        title.font = .systemFont(ofSize: 14, weight: .semibold)
        title.textColor = .label
        title.numberOfLines = 1
        title.setContentCompressionResistancePriority(.required, for: .vertical)

        let subtitle = UILabel()
        subtitle.text = document.fileName
        subtitle.font = .systemFont(ofSize: 11)
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 2
        subtitle.setContentCompressionResistancePriority(.required, for: .vertical)

        let textStack = UIStackView(arrangedSubviews: [title, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 2

        let renameButton = UIButton(type: .system)
        renameButton.setImage(UIImage(systemName: "pencil"), for: .normal)
        renameButton.tintColor = .systemBlue
        renameButton.tag = index
        renameButton.addTarget(self, action: #selector(renameTapped(_:)), for: .touchUpInside)

        let h = UIStackView(arrangedSubviews: [textStack, UIView(), renameButton])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 8
        textStack.isUserInteractionEnabled = false

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

    private func metaPill(title: String, value: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.12)
        container.layer.cornerRadius = 12

        container.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
        container.setContentHuggingPriority(.required, for: .vertical)
        container.setContentCompressionResistancePriority(.required, for: .vertical)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14, weight: .bold)
        valueLabel.textColor = .systemTeal

        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .center

        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])

        return container
    }

    @objc private func studyTapped() {
        onStudyTapped?()
    }

    @objc private func settingsTapped() {
        onSettingsTapped?()
    }

    @objc private func documentTapped(_ sender: UIControl) {
        let index = sender.tag
        guard index >= 0, index < documents.count else { return }
        onDocumentTapped?(documents[index])
    }

    @objc private func renameTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index >= 0, index < documents.count else { return }
        onDocumentRename?(documents[index])
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    static func preferredHeight(docCount: Int) -> CGFloat {
        let infoHeight: CGFloat = 240
        let titleHeight: CGFloat = 22
        let emptyRow: CGFloat = 72
        let rowHeight: CGFloat = 64
        let rowSpacing: CGFloat = 8
        let diaryPadding: CGFloat = 24

        let diaryRowsHeight: CGFloat
        if docCount == 0 {
            diaryRowsHeight = emptyRow
        } else {
            diaryRowsHeight = CGFloat(docCount) * rowHeight + CGFloat(max(docCount - 1, 0)) * rowSpacing
        }

        let diaryCardHeight = diaryRowsHeight + diaryPadding
        return infoHeight + 12 + titleHeight + 8 + diaryCardHeight + 16
    }
}
