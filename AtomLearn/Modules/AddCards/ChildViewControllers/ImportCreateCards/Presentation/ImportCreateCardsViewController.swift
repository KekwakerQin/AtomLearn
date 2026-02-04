import UIKit
import UniformTypeIdentifiers

final class ImportCreateCardsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIDocumentPickerDelegate {
    private let viewModel: ImportCreateCardsViewModel
    var hasCards: Bool { viewModel.hasCards }

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let headerContainer = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let pickButton = UIButton(type: .system)
    private let filesStack = UIStackView()
    private let queryField = UITextField()
    private let countControl = UISegmentedControl(items: ["1", "5", "10", "20"])
    private let generateButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()

    private let bottomBar = UIView()
    private let addButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private var lastHeaderSize: CGSize = .zero

    init(viewModel: ImportCreateCardsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupTable()
        setupHeader()
        setupBottomBar()
        bind()
        enableKeyboardDismissOnTap()
        viewModel.onViewDidLoad()
        updateBottomBar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderLayout()
    }

    // MARK: - Setup
    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false
        tableView.register(GeneratedCardCell.self, forCellReuseIdentifier: "GeneratedCardCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
        tableView.contentInset.bottom = 96

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupHeader() {
        titleLabel.text = "Документ / сайт"
        let baseFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        if let roundedDescriptor = baseFont.fontDescriptor.withDesign(UIFontDescriptor.SystemDesign.rounded) {
            titleLabel.font = UIFont(descriptor: roundedDescriptor, size: 0)
        } else {
            titleLabel.font = baseFont
        }
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        subtitleLabel.text = "Выбери 1–3 файла (PDF/текст/RTF/изображение). Генерация строго по документам."
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        pickButton.setTitle("Выбрать документы (до 3)", for: .normal)
        pickButton.setTitleColor(.white, for: .normal)
        pickButton.backgroundColor = .systemIndigo
        pickButton.layer.cornerRadius = 12
        pickButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        pickButton.addTarget(self, action: #selector(pickDocuments), for: .touchUpInside)

        filesStack.axis = .vertical
        filesStack.spacing = 6

        queryField.placeholder = "Поиск по документам / вопрос"
        queryField.borderStyle = .roundedRect
        queryField.delegate = self
        queryField.autocorrectionType = .yes
        queryField.addTarget(self, action: #selector(queryChanged), for: .editingChanged)
        queryField.setContentCompressionResistancePriority(.required, for: .vertical)

        countControl.selectedSegmentIndex = viewModel.state.selectedCountIndex
        countControl.addTarget(self, action: #selector(countChanged), for: .valueChanged)
        countControl.setContentCompressionResistancePriority(.required, for: .vertical)

        generateButton.setTitle("Сгенерировать", for: .normal)
        generateButton.setTitleColor(.white, for: .normal)
        generateButton.backgroundColor = .systemBlue
        generateButton.layer.cornerRadius = 12
        generateButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        generateButton.setContentCompressionResistancePriority(.required, for: .vertical)

        errorLabel.font = .systemFont(ofSize: 13)
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        let buttonRow = UIStackView(arrangedSubviews: [generateButton, spinner])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 10
        buttonRow.alignment = .center

        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 18

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            pickButton,
            filesStack,
            queryField,
            countControl,
            buttonRow,
            errorLabel
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = .init(top: 16, leading: 16, bottom: 16, trailing: 16)

        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        headerContainer.backgroundColor = .clear
        headerContainer.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -8)
        ])

        tableView.tableHeaderView = headerContainer
        updateHeaderLayout()
    }

    private func setupBottomBar() {
        bottomBar.backgroundColor = .systemBackground
        bottomBar.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        bottomBar.layer.shadowOpacity = 1
        bottomBar.layer.shadowOffset = CGSize(width: 0, height: -4)
        bottomBar.layer.shadowRadius = 8
        bottomBar.isHidden = true

        configureBottomButton(addButton, title: "Добавить все", color: .systemGreen)
        configureBottomButton(deleteButton, title: "Удалить", color: .systemGray)

        addButton.addTarget(self, action: #selector(addSelectedTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteSelectedTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [deleteButton, addButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually

        bottomBar.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBar)
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        let bottomAnchor: NSLayoutYAxisAnchor
        if #available(iOS 15.0, *) {
            bottomAnchor = view.keyboardLayoutGuide.topAnchor
        } else {
            bottomAnchor = view.safeAreaLayoutGuide.bottomAnchor
        }

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: bottomAnchor),

            stack.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor, constant: -12)
        ])
    }

    private func configureBottomButton(_ button: UIButton, title: String, color: UIColor) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = color
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
    }

    private func updateHeaderLayout() {
        headerContainer.setNeedsLayout()
        headerContainer.layoutIfNeeded()
        let size = headerContainer.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        )
        guard size != lastHeaderSize else { return }
        lastHeaderSize = size
        headerContainer.frame = CGRect(origin: .zero, size: size)
        tableView.tableHeaderView = headerContainer
    }

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            guard let self else { return }
            if !self.queryField.isFirstResponder, self.queryField.text != state.query {
                self.queryField.text = state.query
            }
            self.countControl.selectedSegmentIndex = state.selectedCountIndex
            self.generateButton.isEnabled = !state.isLoading
            self.generateButton.alpha = state.isLoading ? 0.6 : 1

            if state.isLoading {
                self.spinner.startAnimating()
            } else {
                self.spinner.stopAnimating()
            }

            self.renderFiles(state.files)

            if let error = state.errorMessage, !error.isEmpty {
                self.errorLabel.text = error
                self.errorLabel.isHidden = false
            } else {
                self.errorLabel.isHidden = true
            }

            self.updateBottomBar()
            if !self.queryField.isFirstResponder {
                self.updateHeaderLayout()
                self.tableView.reloadData()
            }
        }
    }

    private func updateBottomBar() {
        let selectedCount = viewModel.state.cards.filter { $0.isSelected && $0.status == .pending }.count
        let hasCards = !viewModel.state.cards.isEmpty
        bottomBar.isHidden = !hasCards
        tableView.contentInset.bottom = bottomBar.isHidden ? 16 : 96

        if selectedCount == 0 {
            deleteButton.isHidden = true
            addButton.setTitle("Добавить все", for: .normal)
        } else {
            deleteButton.isHidden = false
            deleteButton.setTitle("Удалить (\(selectedCount))", for: .normal)
            addButton.setTitle("Добавить (\(selectedCount))", for: .normal)
        }

        addButton.isEnabled = hasCards && !viewModel.state.isLoading
        addButton.alpha = addButton.isEnabled ? 1 : 0.6
        deleteButton.isEnabled = selectedCount > 0 && !viewModel.state.isLoading
        deleteButton.alpha = deleteButton.isEnabled ? 1 : 0.5
    }

    private func renderFiles(_ files: [BoardDocument]) {
        filesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, doc) in files.enumerated() {
            let row = fileRow(name: doc.title, subtitle: doc.fileName, index: index)
            filesStack.addArrangedSubview(row)
        }
    }

    private func fileRow(name: String, subtitle: String, index: Int) -> UIView {
        let label = UILabel()
        label.text = name
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .label
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 11, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        let removeButton = UIButton(type: .system)
        removeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        removeButton.tintColor = .systemRed
        removeButton.tag = index
        removeButton.addTarget(self, action: #selector(removeFile(_:)), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [label, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let h = UIStackView(arrangedSubviews: [textStack, UIView(), removeButton])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 8

        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 10
        container.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            h.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            h.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            h.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            h.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        return container
    }

    // MARK: - Actions
    
    let docxType = UTType(
        filenameExtension: "docx",
        conformingTo: .data
    )!
    
    @objc private func pickDocuments() {
        let docx = UTType(filenameExtension: "docx", conformingTo: .data)!

        let types: [UTType] = [
            .plainText,
            .text,
            .pdf,
            .rtf,
            .image,
            docx
        ]

        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: types,
            asCopy: true
        )
        picker.allowsMultipleSelection = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func removeFile(_ sender: UIButton) {
        viewModel.removeFile(at: sender.tag)
    }

    @objc private func queryChanged() {
        viewModel.updateQuery(queryField.text ?? "")
    }

    @objc private func countChanged() {
        viewModel.updateCountIndex(countControl.selectedSegmentIndex)
    }

    @objc private func generateTapped() {
        view.endEditing(true)
        viewModel.generateTapped()
    }

    @objc private func addSelectedTapped() {
        let selectedCount = viewModel.state.cards.filter { $0.isSelected && $0.status == .pending }.count
        if selectedCount == 0 {
            viewModel.addAll()
        } else {
            viewModel.addSelected()
        }
    }

    @objc private func deleteSelectedTapped() {
        viewModel.deleteSelected()
    }

    // MARK: - UIDocumentPickerDelegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if urls.count > 3 {
            viewModel.setFiles(Array(urls.prefix(3)))
            showInfo("Можно выбрать максимум 3 документа")
        } else {
            viewModel.setFiles(urls)
        }
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.state.cards.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GeneratedCardCell", for: indexPath) as! GeneratedCardCell
        let item = viewModel.state.cards[indexPath.row]
        cell.configure(with: item)
        cell.onToggleSelection = { [weak self] in
            self?.viewModel.toggleSelection(id: item.id)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = viewModel.state.cards[indexPath.row]
        viewModel.toggleExpand(id: item.id)
    }

    private func showInfo(_ message: String) {
        let alert = UIAlertController(title: "Подсказка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}
