import UIKit
import FirebaseAuth
import FirebaseFirestore

/// Общий экран создания карточки:
/// - Если board заранее известен → сразу выбор режима (ИИ/Вручную/С медиа) → форма
/// - Если board неизвестен → сначала выбрать доску → режим → форма
final class ComposeCardViewController: UIViewController,
                                       UIPickerViewDataSource, UIPickerViewDelegate,
                                       UITextViewDelegate, UITextFieldDelegate, UIScrollViewDelegate {

    // MARK: - Types
    private enum Phase { case selectBoard, chooseMode, form }
    private enum CardMode { case ai, manual, media }

    // MARK: - Dependencies
    private let service: BoardsService
    private let user: AppUser

    // MARK: - State
    private var phase: Phase = .selectBoard
    private var mode: CardMode = .manual

    private var boards: [Board] = []
    private var selectedBoardID: String?
    private let preselectedBoardID: String?

    // MARK: - Firestore
    private let db = Firestore.firestore()
    private var boardsListener: ListenerRegistration?

    // MARK: - UI (container)
    private let scroll = UIScrollView()
    private let stack  = UIStackView()

    // MARK: - UI (phase: selectBoard)
    private let boardTitle = UILabel()
    private let boardPickerContainer = UIView()
    private let boardPicker = UIPickerView()
    private let boardHint = UILabel()
    private let nextButton = UIButton(type: .system)

    // MARK: - UI (phase: form)
    private let frontField = UITextView()
    private let backField  = UITextView()
    private let typeControl = UISegmentedControl(items: Card.ContentType.allCases.map { $0.rawValue })
    private let statusControl = UISegmentedControl(items: Card.Status.allCases.map { $0.rawValue })
    private let visibilityControl = UISegmentedControl(items: Card.Visibility.allCases.map { $0.rawValue })
    private let languageField = UITextField()
    private let tagsField = UITextField()
    private let saveButton = UIButton(type: .system)

    // MARK: - Init
    /// - Parameters:
    ///   - preselectedBoardID: если передан, этап выбора доски пропускается
    init(service: BoardsService, user: AppUser, preselectedBoardID: String? = nil) {
        self.service = service
        self.user = user
        self.preselectedBoardID = preselectedBoardID
        self.selectedBoardID = preselectedBoardID
        super.init(nibName: nil, bundle: nil)
    }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    deinit { boardsListener?.remove() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Фаза по умолчанию: если есть preselected → сразу выбор режима, иначе выбор доски
        phase = (preselectedBoardID == nil) ? .selectBoard : .chooseMode

        setupCommonUI()
        configurePhaseUI()

        loadBoardsIfNeeded()

        // Клавиатура: во sheet жест скролла не должен угонять сам лист
        if #available(iOS 15.0, *), let sheet = navigationController?.sheetPresentationController ?? self.sheetPresentationController {
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
    }

    // MARK: - UI: common container
    private func setupCommonUI() {
        navigationItem.title = "Новая карточка"

        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.keyboardDismissMode = .interactive
        scroll.alwaysBounceVertical = true
        scroll.delegate = self

        view.addSubview(scroll)
        scroll.addSubview(stack)

        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = .init(top: 20, leading: 16, bottom: 24, trailing: 16)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])

        // Глобальные жесты скрытия клавиатуры
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingNow))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(endEditingOnPan(_:)))
        pan.cancelsTouchesInView = false
        view.addGestureRecognizer(pan)
    }

    // MARK: - UI per phase
    private func configurePhaseUI() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        switch phase {
        case .selectBoard:
            buildSelectBoardSection()
        case .chooseMode:
            presentModeSheet() // сразу показываем выбор режима; после выбора переходим в .form
            // На фоне пусть будет короткий хинт про выбранную доску
            buildChosenBoardHint()
        case .form:
            buildFormSection()
        }
    }

    // MARK: - Phase: selectBoard
    private func buildSelectBoardSection() {
        // Заголовок
        boardTitle.text = "Доска"
        boardTitle.font = .systemFont(ofSize: 13, weight: .medium)
        boardTitle.textColor = .secondaryLabel

        // Контейнер
        boardPickerContainer.backgroundColor = .secondarySystemBackground
        boardPickerContainer.layer.cornerRadius = 14
        boardPickerContainer.clipsToBounds = true
        boardPickerContainer.translatesAutoresizingMaskIntoConstraints = false

        boardPicker.translatesAutoresizingMaskIntoConstraints = false
        boardPicker.dataSource = self
        boardPicker.delegate = self
        boardPickerContainer.addSubview(boardPicker)
        NSLayoutConstraint.activate([
            boardPicker.topAnchor.constraint(equalTo: boardPickerContainer.topAnchor, constant: 8),
            boardPicker.bottomAnchor.constraint(equalTo: boardPickerContainer.bottomAnchor, constant: -8),
            boardPicker.leadingAnchor.constraint(equalTo: boardPickerContainer.leadingAnchor),
            boardPicker.trailingAnchor.constraint(equalTo: boardPickerContainer.trailingAnchor),
            boardPicker.heightAnchor.constraint(equalToConstant: 180)
        ])

        boardHint.text = "Выберите доску, куда добавить карточку"
        boardHint.font = .systemFont(ofSize: 13)
        boardHint.textColor = .secondaryLabel
        boardHint.textAlignment = .center

        nextButton.setTitle("Далее", for: .normal)
        nextButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        nextButton.backgroundColor = .systemBlue
        nextButton.tintColor = .white
        nextButton.layer.cornerRadius = 12
        nextButton.isEnabled = (selectedBoardID != nil)
        nextButton.alpha = nextButton.isEnabled ? 1.0 : 0.5
        nextButton.addTarget(self, action: #selector(nextFromBoardTapped), for: .touchUpInside)

        stack.addArrangedSubview(boardTitle)
        stack.addArrangedSubview(boardPickerContainer)
        stack.addArrangedSubview(boardHint)
        stack.setCustomSpacing(20, after: boardPickerContainer)
        stack.addArrangedSubview(nextButton)
    }

    // MARK: - Phase: mode sheet + hint
    private func presentModeSheet() {
        let sheet = UIAlertController(title: "Создать карточку", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Сгенерировать по ИИ", style: .default) { [weak self] _ in
            self?.mode = .ai
            self?.showStub("ИИ-генерация пока в разработке")
            self?.phase = .form
            self?.configurePhaseUI()
        })
        sheet.addAction(UIAlertAction(title: "Сгенерировать вручную", style: .default) { [weak self] _ in
            self?.mode = .manual
            self?.phase = .form
            self?.configurePhaseUI()
        })
        sheet.addAction(UIAlertAction(title: "Сгенерировать с медиа", style: .default) { [weak self] _ in
            self?.mode = .media
            self?.showStub("Режим с медиа пока в разработке")
            self?.phase = .form
            self?.configurePhaseUI()
        })
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel) { [weak self] _ in
            // Если пришли сюда без preselected, при отмене возвращаемся к выбору доски
            if self?.preselectedBoardID == nil {
                self?.phase = .selectBoard
                self?.configurePhaseUI()
            }
        })
        present(sheet, animated: true)
    }

    private func buildChosenBoardHint() {
        let hint = UILabel()
        hint.textAlignment = .center
        hint.font = .systemFont(ofSize: 13)
        hint.textColor = .secondaryLabel
        hint.text = "Вы выбрали доску. Дальше — режим создания."
        stack.addArrangedSubview(hint)
    }

    // MARK: - Phase: form
    private func buildFormSection() {
        title = "Новая карточка"

        configure(textView: frontField, placeholder: "Вопрос (front)")
        configure(textView: backField,  placeholder: "Ответ (back)")
        NSLayoutConstraint.activate([
            frontField.heightAnchor.constraint(equalToConstant: 140),
            backField.heightAnchor.constraint(equalToConstant: 140)
        ])

        typeControl.selectedSegmentIndex = Card.ContentType.allCases.firstIndex(of: .text) ?? 0
        statusControl.selectedSegmentIndex = Card.Status.allCases.firstIndex(of: .published) ?? 0
        visibilityControl.selectedSegmentIndex = Card.Visibility.allCases.firstIndex(of: .private) ?? 0

        configure(textField: languageField, placeholder: "Язык (например: ru)", text: "ru")
        configure(textField: tagsField, placeholder: "Теги (через запятую)", text: nil)

        let kbToolbar = makeKeyboardToolbar()
        [frontField, backField].forEach { $0.inputAccessoryView = kbToolbar }
        [languageField, tagsField].forEach { $0.inputAccessoryView = kbToolbar }

        saveButton.setTitle("Сохранить", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        saveButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        stack.addArrangedSubview(section(title: "Front", view: frontField))
        stack.addArrangedSubview(section(title: "Back", view: backField))
        stack.addArrangedSubview(section(title: "Тип контента", view: typeControl))
        stack.addArrangedSubview(section(title: "Статус", view: statusControl))
        stack.addArrangedSubview(section(title: "Видимость", view: visibilityControl))
        stack.addArrangedSubview(section(title: "Язык", view: languageField))
        stack.addArrangedSubview(section(title: "Теги", view: tagsField))
        stack.setCustomSpacing(16, after: tagsField)
        stack.addArrangedSubview(saveButton)
    }

    // MARK: - Data
    private func loadBoardsIfNeeded() {
        guard preselectedBoardID == nil else { return } // не нужно, если борд уже известен
        let uid = Auth.auth().currentUser?.uid ?? user.uid

        boardsListener = service.observeBoards(ownerUID: uid) { [weak self] result in
            guard let self else { return }
            if case let .success(list) = result {
                self.boards = list
                self.boardPicker.reloadAllComponents()

                if self.selectedBoardID == nil {
                    if let lastID = UserDefaults.standard.string(forKey: "lastBoardID"),
                       let idx = list.firstIndex(where: { $0.id == lastID }) {
                        self.selectedBoardID = lastID
                        self.boardPicker.selectRow(idx, inComponent: 0, animated: false)
                    } else if let first = list.first {
                        self.selectedBoardID = first.id
                        self.boardPicker.selectRow(0, inComponent: 0, animated: false)
                    }
                }

                self.boardHint.text = list.isEmpty
                    ? "У вас пока нет досок. Сначала создайте борд."
                    : "Выберите доску, куда добавить карточку"

                self.nextButton.isEnabled = (self.selectedBoardID != nil)
                self.nextButton.alpha = self.nextButton.isEnabled ? 1.0 : 0.5
            }
        }
    }

    // MARK: - Actions
    @objc private func nextFromBoardTapped() {
        guard selectedBoardID != nil else { return }
        // запомним последний выбранный
        if let id = selectedBoardID { UserDefaults.standard.set(id, forKey: "lastBoardID") }
        phase = .chooseMode
        configurePhaseUI()
    }

    @objc private func saveTapped() {
        guard let boardID = selectedBoardID else {
            toast("Не выбрана доска")
            return
        }
        let front = trimmedOrNil(frontField)
        let back  = trimmedOrNil(backField) ?? ""
        guard let frontNonEmpty = front, !frontNonEmpty.isEmpty else {
            let a = UIAlertController(title: "Заполните front", message: nil, preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
            return
        }

        let type = Card.ContentType.allCases[typeControl.selectedSegmentIndex]
        let status = Card.Status.allCases[statusControl.selectedSegmentIndex]
        let visibility = Card.Visibility.allCases[visibilityControl.selectedSegmentIndex]
        let language = (languageField.text ?? "ru").trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = tagsField.text?
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? []

        let data: [String: Any] = [
            "boardId": boardID,
            "ownerId": user.uid,
            "front": frontNonEmpty,
            "back": back,
            "type": type.rawValue,
            "language": language.isEmpty ? "ru" : language,
            "tags": tags,
            "status": status.rawValue,
            "visibility": visibility.rawValue,
            "reviewStats": ["correct": 0, "wrong": 0],
            "spacedRepetition": [
                "ease": 2.5, "intervalDays": 0,
                "dueAt": FieldValue.serverTimestamp(),
                "reps": 0, "lapses": 0
            ],
            "isDeleted": false,
            "version": 1,
            "views": 0,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        db.collection("boards").document(boardID)
            .collection("cards")
            .addDocument(data: data) { [weak self] error in
                if let error { print("[ComposeCard] save error:", error.localizedDescription) }
                self?.dismiss(animated: true)
            }
    }

    // MARK: - Helpers
    private func configure(textView: UITextView, placeholder: String) {
        textView.font = .systemFont(ofSize: 16)
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 12
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.textContainerInset = .init(top: 10, left: 8, bottom: 10, right: 8)
        textView.text = placeholder
        textView.textColor = .placeholderText
        textView.delegate = self
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.inputAccessoryView = makeKeyboardToolbar()
    }

    private func configure(textField: UITextField, placeholder: String, text: String?) {
        textField.placeholder = placeholder
        textField.text = text
        textField.borderStyle = .roundedRect
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.inputAccessoryView = makeKeyboardToolbar()
    }

    private func section(title: String, view: UIView) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        let container = UIStackView(arrangedSubviews: [titleLabel, view])
        container.axis = .vertical
        container.spacing = 6
        return container
    }

    private func makeKeyboardToolbar() -> UIToolbar {
        let tb = UIToolbar()
        tb.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(endEditingNow))
        tb.items = [flex, done]
        return tb
    }

    @objc private func endEditingNow() { view.endEditing(true) }
    @objc private func endEditingOnPan(_ g: UIPanGestureRecognizer) { if g.state == .began { view.endEditing(true) } }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { view.endEditing(true) }

    func textViewDidBeginEditing(_ tv: UITextView) {
        if tv.textColor == .placeholderText { tv.text = nil; tv.textColor = .label }
    }
    func textViewDidEndEditing(_ tv: UITextView) {
        if tv.text?.isEmpty == true { tv.textColor = .placeholderText }
    }

    private func trimmedOrNil(_ tv: UITextView) -> String? {
        if tv.textColor == .placeholderText { return nil }
        return tv.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - UIPicker
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { boards.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { boards[row].title }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedBoardID = boards[row].id
        nextButton.isEnabled = true
        nextButton.alpha = 1.0
        UserDefaults.standard.set(boards[row].id, forKey: "lastBoardID")
    }

    // MARK: - Presentation helper
    /// Рекомендуемая презентация как sheet до верха:
    static func present(from host: UIViewController, service: BoardsService, user: AppUser, preselectedBoardID: String? = nil) {
        let vc = ComposeCardViewController(service: service, user: user, preselectedBoardID: preselectedBoardID)
        if #available(iOS 15.0, *), let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.selectedDetentIdentifier = .large
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        }
        vc.modalPresentationStyle = .pageSheet
        host.present(vc, animated: true)
    }
    
    // MARK: - Alerts
    private func toast(_ text: String) {
        let a = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        present(a, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { a.dismiss(animated: true) }
    }
    private func showStub(_ message: String) {
        let a = UIAlertController(title: "Скоро", message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}
