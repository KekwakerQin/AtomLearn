import UIKit
import UniformTypeIdentifiers

final class ImportCreateCardsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIDocumentPickerDelegate {
    private let viewModel: ImportCreateCardsViewModel

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let headerContainer = UIView()
    private let titleLabel = UILabel()
    private let pickButton = UIButton(type: .system)
    private let filesStack = UIStackView()
    private let queryField = UITextField()
    private let countControl = UISegmentedControl(items: ["1", "5", "10", "20"])
    private let generateButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()

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
        bind()
        enableKeyboardDismissOnTap()
    }

    // MARK: - Setup
    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(GeneratedCardCell.self, forCellReuseIdentifier: "GeneratedCardCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140

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

        countControl.selectedSegmentIndex = viewModel.state.selectedCountIndex
        countControl.addTarget(self, action: #selector(countChanged), for: .valueChanged)

        generateButton.setTitle("Сгенерировать", for: .normal)
        generateButton.setTitleColor(.white, for: .normal)
        generateButton.backgroundColor = .systemBlue
        generateButton.layer.cornerRadius = 12
        generateButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)

        errorLabel.font = .systemFont(ofSize: 13)
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        let buttonRow = UIStackView(arrangedSubviews: [generateButton, spinner])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 10
        buttonRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
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

        headerContainer.backgroundColor = .clear
        headerContainer.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            stack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor)
        ])

        tableView.tableHeaderView = headerContainer
        updateHeaderLayout()
    }

    private func updateHeaderLayout() {
        headerContainer.setNeedsLayout()
        headerContainer.layoutIfNeeded()
        let size = headerContainer.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        )
        headerContainer.frame = CGRect(origin: .zero, size: size)
        tableView.tableHeaderView = headerContainer
    }

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            guard let self else { return }
            self.queryField.text = state.query
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

            self.updateHeaderLayout()
            self.tableView.reloadData()
        }
    }

    private func renderFiles(_ files: [URL]) {
        filesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, url) in files.enumerated() {
            let row = fileRow(name: url.lastPathComponent, index: index)
            filesStack.addArrangedSubview(row)
        }
    }

    private func fileRow(name: String, index: Int) -> UIView {
        let label = UILabel()
        label.text = name
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .label

        let removeButton = UIButton(type: .system)
        removeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        removeButton.tintColor = .systemRed
        removeButton.tag = index
        removeButton.addTarget(self, action: #selector(removeFile(_:)), for: .touchUpInside)

        let h = UIStackView(arrangedSubviews: [label, UIView(), removeButton])
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
    @objc private func pickDocuments() {
        let types: [UTType] = [.plainText, .text, .pdf, .rtf]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
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
        cell.onAccept = { [weak self] in
            self?.viewModel.accept(id: item.id)
        }
        cell.onSkip = { [weak self] in
            self?.viewModel.skip(id: item.id)
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
