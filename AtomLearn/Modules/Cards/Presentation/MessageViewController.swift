import UIKit

private struct MessageThread: Identifiable {
    let id = UUID()
    let name: String
    let lastMessage: String
    let time: String
    let isOnline: Bool
    let unreadCount: Int
    let accent: UIColor
}

// Экран списка сообщений (чаты)
final class MessagesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    // MARK: - Properties
    private var threads: [MessageThread] = [
        MessageThread(name: "Иван", lastMessage: "Привет! Как продвигается проект?", time: "09:40", isOnline: true, unreadCount: 2, accent: .systemTeal),
        MessageThread(name: "Сеня", lastMessage: "Глянь PR #42, плиз", time: "09:12", isOnline: false, unreadCount: 0, accent: .systemOrange),
        MessageThread(name: "Дима", lastMessage: "Подтверди схему авторизации", time: "Вчера", isOnline: true, unreadCount: 1, accent: .systemIndigo),
        MessageThread(name: "HR", lastMessage: "Назначим созвон на завтра?", time: "Вчера", isOnline: false, unreadCount: 0, accent: .systemPink)
    ]

    private var filteredThreads: [MessageThread] = []

    // MARK: - UI
    private let headerView = GradientHeaderView(colors: [
        UIColor(red: 0.12, green: 0.18, blue: 0.24, alpha: 1),
        UIColor(red: 0.12, green: 0.44, blue: 0.50, alpha: 1)
    ])

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let searchField = UITextField()

    private let table = UITableView(frame: .zero, style: .plain)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        filteredThreads = threads
        enableKeyboardDismissOnTap()
        setupHeader()
        setupTable()
    }

    // MARK: - Setup
    private func setupHeader() {
        headerView.layer.cornerRadius = 20
        headerView.clipsToBounds = true
        headerView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "Сообщения"
        titleLabel.textColor = .white
        // Use UIFontDescriptor to get a rounded system font if available
        let baseTitleFont = UIFont.systemFont(ofSize: 26, weight: .bold)
        if let roundedDescriptor = baseTitleFont.fontDescriptor.withDesign(.rounded) {
            titleLabel.font = UIFont(descriptor: roundedDescriptor, size: 26)
        } else {
            titleLabel.font = baseTitleFont
        }

        subtitleLabel.text = "4 новых диалога за сегодня"
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .medium)

        let searchContainer = UIView()
        searchContainer.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        searchContainer.layer.cornerRadius = 14

        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = .white
        searchIcon.setContentHuggingPriority(.required, for: .horizontal)

        searchField.textColor = .white
        searchField.attributedPlaceholder = NSAttributedString(
            string: "Поиск сообщений",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
        )
        searchField.autocorrectionType = .no
        searchField.autocapitalizationType = .none
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)

        let searchStack = UIStackView(arrangedSubviews: [searchIcon, searchField])
        searchStack.axis = .horizontal
        searchStack.spacing = 8
        searchStack.alignment = .center

        searchContainer.addSubview(searchStack)
        searchStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchStack.topAnchor.constraint(equalTo: searchContainer.topAnchor, constant: 8),
            searchStack.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 12),
            searchStack.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -12),
            searchStack.bottomAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: -8)
        ])

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, searchContainer])
        headerStack.axis = .vertical
        headerStack.spacing = 10

        headerView.addSubview(headerStack)
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            headerStack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16)
        ])

        view.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 160)
        ])
    }

    private func setupTable() {
        table.dataSource = self
        table.delegate = self
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.rowHeight = 86
        table.register(MessageThreadCell.self, forCellReuseIdentifier: "cell")

        view.addSubview(table)
        table.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Actions
    @objc private func searchChanged() {
        let query = (searchField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            filteredThreads = threads
        } else {
            filteredThreads = threads.filter {
                $0.name.lowercased().contains(query.lowercased()) ||
                $0.lastMessage.lowercased().contains(query.lowercased())
            }
        }
        table.reloadData()
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredThreads.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MessageThreadCell
        let thread = filteredThreads[indexPath.row]
        cell.configure(with: thread)
        return cell
    }
}

// MARK: - Cell
private final class MessageThreadCell: UITableViewCell {
    private let container = UIView()
    private let avatar = UILabel()
    private let onlineDot = UIView()
    private let nameLabel = UILabel()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let badgeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 16
        container.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        container.layer.shadowOpacity = 1
        container.layer.shadowOffset = CGSize(width: 0, height: 4)
        container.layer.shadowRadius = 8

        avatar.font = .systemFont(ofSize: 16, weight: .bold)
        avatar.textAlignment = .center
        avatar.textColor = .white
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 22
        avatar.translatesAutoresizingMaskIntoConstraints = false

        onlineDot.backgroundColor = .systemGreen
        onlineDot.layer.cornerRadius = 5
        onlineDot.layer.borderWidth = 2
        onlineDot.layer.borderColor = UIColor.systemBackground.cgColor
        onlineDot.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        messageLabel.font = .systemFont(ofSize: 13)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 2

        timeLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        timeLabel.textColor = .tertiaryLabel

        badgeLabel.font = .systemFont(ofSize: 11, weight: .bold)
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = .systemRed
        badgeLabel.layer.cornerRadius = 10
        badgeLabel.clipsToBounds = true
        badgeLabel.textAlignment = .center

        let textStack = UIStackView(arrangedSubviews: [nameLabel, messageLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let rightStack = UIStackView(arrangedSubviews: [timeLabel, badgeLabel])
        rightStack.axis = .vertical
        rightStack.alignment = .trailing
        rightStack.spacing = 6

        let h = UIStackView(arrangedSubviews: [avatar, textStack, rightStack])
        h.axis = .horizontal
        h.spacing = 12
        h.alignment = .center

        contentView.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(h)
        container.addSubview(onlineDot)
        h.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            avatar.widthAnchor.constraint(equalToConstant: 44),
            avatar.heightAnchor.constraint(equalToConstant: 44),

            h.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            h.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            h.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            h.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),

            onlineDot.widthAnchor.constraint(equalToConstant: 10),
            onlineDot.heightAnchor.constraint(equalToConstant: 10),
            onlineDot.trailingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 2),
            onlineDot.bottomAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 2)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func configure(with thread: MessageThread) {
        avatar.text = String(thread.name.prefix(1))
        avatar.backgroundColor = thread.accent
        nameLabel.text = thread.name
        messageLabel.text = thread.lastMessage
        timeLabel.text = thread.time
        onlineDot.isHidden = !thread.isOnline

        if thread.unreadCount > 0 {
            badgeLabel.text = " \(thread.unreadCount) "
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
    }
}

private final class GradientHeaderView: UIView {
    private let gradientLayer = CAGradientLayer()

    init(colors: [UIColor]) {
        super.init(frame: .zero)
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
