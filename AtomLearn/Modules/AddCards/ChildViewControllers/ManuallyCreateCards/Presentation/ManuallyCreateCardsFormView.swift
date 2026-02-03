import UIKit

final class ManuallyCreateCardFormView: UIView {

    // MARK: - Dependencies
    var onQuestionChanged: ((String) -> Void)?
    var onAnswerChanged: ((String) -> Void)?
    var onRemoveTapped: (() -> Void)?

    // MARK: - UI
    private let cardContainer = UIView()
    private let headerLabel = UILabel()
    private let headerRow = UIStackView()
    private let removeButton = UIButton(type: .system)

    private let questionTitleLabel = UILabel()
    private let questionTextView = UITextView()

    private let answerTitleLabel = UILabel()
    private let answerTextView = UITextView()

    private let stack = UIStackView()

    // MARK: - Init
    init(index: Int) {
        super.init(frame: .zero)
        setupUI(index: index)
        setupTextViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Public API
    /// Updates UI fields without triggering callbacks.
    func render(index: Int, question: String, answer: String) {
        headerLabel.text = "Карточка \(index + 1)"
        questionTextView.text = question
        answerTextView.text = answer
    }
    
    /// Shows or hides the remove button.
    func setRemoveVisible(_ isVisible: Bool) {
        removeButton.isHidden = !isVisible
        removeButton.isEnabled = isVisible
    }

    /// Returns whether question is empty after trimming.
    func isQuestionEmpty() -> Bool {
        questionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns whether answer is empty after trimming.
    func isAnswerEmpty() -> Bool {
        answerTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Focuses question field.
    func focusQuestion() {
        questionTextView.becomeFirstResponder()
    }

    /// Focuses answer field.
    func focusAnswer() {
        answerTextView.becomeFirstResponder()
    }

    // MARK: - Private helpers
    private func setupUI(index: Int) {
        translatesAutoresizingMaskIntoConstraints = false

        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.layer.cornerRadius = 16
        cardContainer.backgroundColor = .secondarySystemBackground

        headerLabel.font = .boldSystemFont(ofSize: 16)
        headerLabel.text = "Карточка \(index + 1)"
        
        removeButton.setImage(UIImage(systemName: "trash"), for: .normal)
        removeButton.tintColor = .systemRed
        removeButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        removeButton.layer.cornerRadius = 14
        removeButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
        removeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
        removeButton.accessibilityLabel = "Удалить карточку"
        
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 8
        headerRow.addArrangedSubview(headerLabel)
        headerRow.addArrangedSubview(UIView())
        headerRow.addArrangedSubview(removeButton)

        questionTitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        questionTitleLabel.text = "Вопрос"

        answerTitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        answerTitleLabel.text = "Ответ"

        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(cardContainer)
        cardContainer.addSubview(stack)

        stack.addArrangedSubview(headerRow)
        stack.addArrangedSubview(questionTitleLabel)
        stack.addArrangedSubview(questionTextView)
        stack.addArrangedSubview(answerTitleLabel)
        stack.addArrangedSubview(answerTextView)

        NSLayoutConstraint.activate([
            cardContainer.topAnchor.constraint(equalTo: topAnchor),
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            stack.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: -12),

            questionTextView.heightAnchor.constraint(equalToConstant: 80),
            answerTextView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }

    @objc private func removeTapped() {
        onRemoveTapped?()
    }

    private func setupTextViews() {
        [questionTextView, answerTextView].forEach { tv in
            tv.font = .systemFont(ofSize: 15)
            tv.layer.cornerRadius = 12
            tv.layer.borderWidth = 1
            tv.layer.borderColor = UIColor.separator.cgColor
            tv.backgroundColor = .systemBackground
            tv.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            tv.delegate = self
        }
    }
}

extension ManuallyCreateCardFormView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView === questionTextView {
            onQuestionChanged?(textView.text ?? "")
        } else if textView === answerTextView {
            onAnswerChanged?(textView.text ?? "")
        }
    }
}
