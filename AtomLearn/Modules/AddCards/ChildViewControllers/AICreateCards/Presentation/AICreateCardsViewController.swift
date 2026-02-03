import UIKit

final class AICreateCardsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
    private let viewModel: AICreateCardsViewModel

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let headerContainer = UIView()
    private let titleLabel = UILabel()
    private let promptTextView = UITextView()
    private let countControl = UISegmentedControl(items: ["1", "5", "10", "20"])
    private let generateButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()

    // MARK: - Init
    init(viewModel: AICreateCardsViewModel) {
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
        titleLabel.text = "AI генератор"
        // Use rounded system font when available; fall back to standard system font
        let baseTitleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        if let roundedDescriptor = baseTitleFont.fontDescriptor.withDesign(.rounded) {
            titleLabel.font = UIFont(descriptor: roundedDescriptor, size: 22)
        } else {
            titleLabel.font = baseTitleFont
        }

        promptTextView.font = .systemFont(ofSize: 15)
        promptTextView.layer.cornerRadius = 14
        promptTextView.layer.borderWidth = 1
        promptTextView.layer.borderColor = UIColor.separator.cgColor
        promptTextView.backgroundColor = .systemBackground
        promptTextView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        promptTextView.delegate = self
        promptTextView.heightAnchor.constraint(equalToConstant: 110).isActive = true

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

        let stack = UIStackView(arrangedSubviews: [titleLabel, promptTextView, countControl, buttonRow, errorLabel])
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
            self.promptTextView.text = state.inputText
            self.countControl.selectedSegmentIndex = state.selectedCountIndex
            self.generateButton.isEnabled = !state.isLoading
            self.generateButton.alpha = state.isLoading ? 0.6 : 1

            if state.isLoading {
                self.spinner.startAnimating()
            } else {
                self.spinner.stopAnimating()
            }

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

    // MARK: - Actions
    @objc private func generateTapped() {
        view.endEditing(true)
        viewModel.generateTapped()
    }

    @objc private func countChanged() {
        viewModel.updateCountIndex(countControl.selectedSegmentIndex)
    }

    func textViewDidChange(_ textView: UITextView) {
        viewModel.updateInput(textView.text ?? "")
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
}
