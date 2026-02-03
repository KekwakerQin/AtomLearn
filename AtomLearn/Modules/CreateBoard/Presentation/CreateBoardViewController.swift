import UIKit

final class CreateBoardViewController: UIViewController {
    
    // MARK: Dependencies
    private let viewModel: CreateBoardViewModel
    
    // MARK: UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    private let titleView = FormTextFieldView(
        title: "Название",
        placeholder: "Например: Подготовка к контрольной",
        helper: "Основная тема  ."
    )
    
    private let subjectView = FormTextFieldView(
        title: "Направление",
        placeholder: "Например: Арифметика",
        helper: "Узкая область знаний, к которой относится доска."
    )
    
    private let descriptionView = FormTextFieldView(
        title: "Описание (опционально)",
        placeholder: "О чём эта доска",
        helper: "Помогает тебе и другим понять контекст."
    )
    
    private let visibilityControl = UISegmentedControl(items: ["Публичный", "Закрытый"])
    private let intentControl = UISegmentedControl(items: ["Учёба", "Экзамен", "Работа", "Личное"])
    private let repetitionControl = UISegmentedControl()
    
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
        
        view.backgroundColor = .systemGroupedBackground
        
        configureNavigation()
        configureUI()
        enableKeyboardDismissOnTap()
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
        let models = viewModel.state.availableRepetitionModels
        guard repetitionControl.selectedSegmentIndex < models.count else { return }

        let model = models[repetitionControl.selectedSegmentIndex]
        viewModel.selectRepetitionModel(model)
    }
    
    @objc private func examDateChanged() {
        viewModel.updateExamDate(examDatePicker.date)
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
        descriptionView.textField.addTarget(self, action: #selector(descriptionChanged), for: .editingChanged)
        subjectView.textField.addTarget(self, action: #selector(subjectChanged), for: .editingChanged)
        
        visibilityControl.selectedSegmentIndex = 0 // public default
        visibilityControl.selectedSegmentTintColor = .systemBlue
        visibilityControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        visibilityControl.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .normal)
        visibilityControl.addTarget(self, action: #selector(visibilityChanged), for: .valueChanged)
        
        intentControl.selectedSegmentIndex = 0 // study default
        intentControl.selectedSegmentTintColor = .systemBlue
        intentControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        intentControl.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .normal)
        intentControl.addTarget(self, action: #selector(intentChanged), for: .valueChanged)
        
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
        contentStack.spacing = 16

        let header = makeHeaderCard()
        
        let main = FormSectionView(title: "Основное")
        main.addArranged(titleView)
        main.addArranged(descriptionView)
        main.addArranged(subjectView)
        
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
        
        [header, main, access, learning, tags, collabs].forEach { contentStack.addArrangedSubview($0) }
        
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

    private func makeHeaderCard() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        card.layer.cornerRadius = 18

        let title = UILabel()
        title.text = "Создание доски"
        // Apply rounded design if available, fall back to regular system font
        let titleSize: CGFloat = 22
        let titleWeight: UIFont.Weight = .bold
        if let roundedDescriptor = UIFont.systemFont(ofSize: titleSize, weight: titleWeight).fontDescriptor.withDesign(.rounded) {
            title.font = UIFont(descriptor: roundedDescriptor, size: titleSize)
        } else {
            title.font = .systemFont(ofSize: titleSize, weight: titleWeight)
        }

        let subtitle = UILabel()
        subtitle.text = "Опиши тему, выбери режим и стартуй учебный поток"
        subtitle.font = .systemFont(ofSize: 13, weight: .medium)
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [title, subtitle])
        stack.axis = .vertical
        stack.spacing = 6
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = .init(top: 14, leading: 14, bottom: 14, trailing: 14)

        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        return card
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
            
            self.repetitionControl.removeAllSegments()

            for (index, model) in state.availableRepetitionModels.enumerated() {
                self.repetitionControl.insertSegment(
                    withTitle: model.displayTitle,
                    at: index,
                    animated: false
                )
            }

            if let selectedIndex = state.availableRepetitionModels.firstIndex(of: state.repetitionModel) {
                self.repetitionControl.selectedSegmentIndex = selectedIndex
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
