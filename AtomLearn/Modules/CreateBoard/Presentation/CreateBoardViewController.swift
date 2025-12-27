import UIKit

final class CreateBoardViewController: UIViewController {
    
    // MARK: Dependencies
    private let viewModel: CreateBoardViewModel
    
    // MARK: UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    private let titleView = FormTextFieldView(
        title: "Название",
        placeholder: "Например: Swift основы",
        helper: "Коротко и понятно. Можно потом поменять."
    )
    
    private let subjectView = FormTextFieldView(
        title: "Subject",
        placeholder: "Например: Swift / Biology",
        helper: "Subject — узкая направленность общего тега. Например: tag=Programming, subject=Swift."
    )
    
    private let descriptionView = FormTextFieldView(
        title: "Описание (опционально)",
        placeholder: "О чём эта доска",
        helper: "Помогает тебе и другим понять контекст."
    )
    
    private let visibilityControl = UISegmentedControl(items: ["Public", "Private"])
    private let intentControl = UISegmentedControl(items: ["Study", "Exam", "Work", "Personal"])
    private let repetitionControl = UISegmentedControl(items: ["FSRS", "FSRS Exam", "SRS", "Everyday"])
    
    private let examDatePicker = UIDatePicker()
    
    private let tagsView = TagsPickerView()
    private let collaboratorsView = CollaboratorsInputView()
    
    private let loader = UIActivityIndicatorView(style: .medium)
    
    // MARK: Init
    init(viewModel: CreateBoardViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("DEINIT \(self)")
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        configureNavigation()
        configureUI()
        setupKeyboardDismiss()
        setupKeyboardObservers()
        bind()
        
        viewModel.onViewDidLoad()
    }
    
    // MARK: Actions
    @objc private func cancelTapped() {
        viewModel.cancel()
    }
    
    @objc private func createTapped() {
        viewModel.createBoard()
    }
    
    @objc private func titleChanged() {
        viewModel.updateTitle(titleView.textField.text ?? "")
    }
    
    @objc private func subjectChanged() {
        viewModel.updateSubject(subjectView.textField.text ?? "")
    }
    
    @objc private func descriptionChanged() {
        viewModel.updateDescription(descriptionView.textField.text ?? "")
    }
    
    @objc private func visibilityChanged() {
        let v: BoardVisibility = (visibilityControl.selectedSegmentIndex == 1) ? .private : .public
        viewModel.selectVisibility(v)
    }
    
    @objc private func intentChanged() {
        let i: BoardLearningIntent
        switch intentControl.selectedSegmentIndex {
        case 1: i = .exam
        case 2: i = .work
        case 3: i = .personal
        default: i = .study
        }
        viewModel.selectIntent(i)
    }
    
    @objc private func repetitionChanged() {
        let m: BoardRepetitionModel
        switch repetitionControl.selectedSegmentIndex {
        case 1: m = .fsrs_exam
        case 2: m = .srs
        case 3: m = .everyday
        default: m = .fsrs
        }
        viewModel.selectRepetitionModel(m)
    }
    
    @objc private func examDateChanged() {
        viewModel.updateExamDate(examDatePicker.date)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: Private helpers
    private func configureNavigation() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Отмена",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        
        loader.hidesWhenStopped = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Создать",
            style: .done,
            target: self,
            action: #selector(createTapped)
        )
    }
    
    private func configureUI() {
        // Inputs
        titleView.textField.addTarget(self, action: #selector(titleChanged), for: .editingChanged)
        subjectView.textField.addTarget(self, action: #selector(subjectChanged), for: .editingChanged)
        descriptionView.textField.addTarget(self, action: #selector(descriptionChanged), for: .editingChanged)
        
        visibilityControl.selectedSegmentIndex = 0 // public default
        visibilityControl.addTarget(self, action: #selector(visibilityChanged), for: .valueChanged)
        
        intentControl.selectedSegmentIndex = 0 // study default
        intentControl.addTarget(self, action: #selector(intentChanged), for: .valueChanged)
        
        repetitionControl.selectedSegmentIndex = 0 // fsrs default
        repetitionControl.addTarget(self, action: #selector(repetitionChanged), for: .valueChanged)
        
        examDatePicker.datePickerMode = .date
        examDatePicker.preferredDatePickerStyle = .inline
        examDatePicker.addTarget(self, action: #selector(examDateChanged), for: .valueChanged)
        
        // Tags callbacks
        tagsView.onAddTag = { [weak self] tag in self?.viewModel.addTag(tag) }
        tagsView.onRemoveTagAt = { [weak self] idx in self?.viewModel.removeTag(at: idx) }
        
        // Collaborators callbacks
        collaboratorsView.onAdd = { [weak self] uid, role in self?.viewModel.addCollaborator(uid: uid, role: role) }
        collaboratorsView.onRemoveAt = { [weak self] idx in self?.viewModel.removeCollaborator(at: idx) }
        
        // Layout
        contentStack.axis = .vertical
        contentStack.spacing = 14
        
        let main = FormSectionView(title: "Основное")
        main.addArranged(titleView)
        main.addArranged(subjectView)
        main.addArranged(descriptionView)
        
        let access = FormSectionView(title: "Доступ")
        access.addArranged(visibilityControl)
        
        let learning = FormSectionView(title: "Обучение")
        learning.addArranged(intentControl)
        learning.addArranged(repetitionControl)
        learning.addArranged(examDatePicker)
        
        let tags = FormSectionView(title: "Теги")
        tags.addArranged(tagsView)
        
        let collabs = FormSectionView(title: "Участники (опционально)")
        collabs.addArranged(collaboratorsView)
        
        [main, access, learning, tags, collabs].forEach { contentStack.addArrangedSubview($0) }
        
        scrollView.addSubview(contentStack)
        view.addSubview(scrollView)
        scrollView.contentInsetAdjustmentBehavior = .never
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }
    
    private func bind() {
        viewModel.onStateChanged = { [weak self] state in
            guard let self else { return }
            
            // sync controls if VM changed defaults
            self.visibilityControl.selectedSegmentIndex = (state.visibility == .private) ? 1 : 0
            
            switch state.intent {
            case .study: self.intentControl.selectedSegmentIndex = 0
            case .exam: self.intentControl.selectedSegmentIndex = 1
            case .work: self.intentControl.selectedSegmentIndex = 2
            case .personal: self.intentControl.selectedSegmentIndex = 3
            }
            
            switch state.repetitionModel {
            case .fsrs: self.repetitionControl.selectedSegmentIndex = 0
            case .fsrs_exam: self.repetitionControl.selectedSegmentIndex = 1
            case .srs: self.repetitionControl.selectedSegmentIndex = 2
            case .everyday: self.repetitionControl.selectedSegmentIndex = 3
            default: self.repetitionControl.selectedSegmentIndex = 0
            }
            
            self.examDatePicker.isHidden = !state.isExamDateVisible
            self.navigationItem.rightBarButtonItem?.isEnabled = state.canCreate
            
            self.tagsView.render(selected: state.tags, suggested: state.suggestedTags)
            self.collaboratorsView.render(items: state.extraCollaborators)
        }
        
        viewModel.onLoadingChanged = { [weak self] isLoading in
            guard let self else { return }
            self.setLoading(isLoading)
        }
        
        viewModel.onError = { [weak self] message in
            let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
    
    private func setLoading(_ isLoading: Bool) {
        if isLoading {
            loader.startAnimating()
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loader)
        } else {
            loader.stopAnimating()
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Создать",
                style: .done,
                target: self,
                action: #selector(createTapped)
            )
        }
        
        navigationItem.leftBarButtonItem?.isEnabled = !isLoading
        view.isUserInteractionEnabled = !isLoading
    }
    
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }

        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let intersection = view.bounds.intersection(keyboardFrameInView)
        let keyboardInset = max(0, intersection.height)

        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options,
            animations: {
                let visibleHeight = self.scrollView.bounds.height - keyboardInset
                let contentHeight = self.scrollView.contentSize.height

                let effectiveInset = contentHeight > visibleHeight ? keyboardInset : 0

                self.scrollView.contentInset.bottom = effectiveInset
                self.scrollView.scrollIndicatorInsets.bottom = effectiveInset
            },
            completion: nil
        )
    }
}
