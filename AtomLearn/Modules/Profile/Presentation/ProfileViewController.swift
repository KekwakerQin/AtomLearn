import UIKit

// Экран профиля пользователя
final class ProfileViewController: UIViewController {
    // MARK: - Dependencies
    private let viewModel: ProfileViewModel
    private let authService: AuthService

    // Вкладки: профиль, доски, учёба
    enum Tab { case profile, boards, study }

    // Текущий пользователь
    private let user: AppUser
    /// Создаёт экран профиля.
    init(
        user: AppUser,
        viewModel: ProfileViewModel = ProfileViewModel(service: ProfileRepository()),
        authService: AuthService = AuthServiceImpl()
    ) {
        self.user = user
        self.viewModel = viewModel
        self.authService = authService
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        print("DEINIT \(self)")
    }
    
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI

    // Аватар пользователя
    private let avatar = AvatarView()
    // Стек кнопок вкладок
    private let buttonsStack = UIStackView()
    // Контейнер для вложенных контроллеров
    private let container = UIView()

    // Кнопка профиля
    private let btnProfile = UIButton(type: .system)
    // Кнопка досок
    private let btnBoards  = UIButton(type: .system)
    // Кнопка учёбы
    private let btnStudy   = UIButton(type: .system)

    // MARK: - Child ViewControllers

    // Экран информации профиля
    private lazy var infoVC = ProfileInfoViewController(
        user: user,
        viewModel: ProfileInfoViewModel(authService: authService)
    )
    // Экран списка досок
    private lazy var boardsVC = BoardsViewController(user: user, service: BoardsRepository())
    // Экран обучения
    private lazy var studyVC  = StudyViewController()

    // Верхняя панель (аватар + кнопки)
    private let header = UIStackView()      // сохраним ссылку

    // MARK: - Lifecycle

    // Настройка интерфейса и стартовая вкладка
    override func viewDidLoad() {
        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
        view.backgroundColor = .clear
        view.isOpaque = false
        container.backgroundColor = .clear
        header.backgroundColor = .clear
        buttonsStack.backgroundColor = .clear
        
        setupHeader()
        setupContainer()
        switchTo(.boards)
        bind()
        applyProfile(nil)
        viewModel.onViewDidLoad(userId: user.uid)
    }
    
    // Скрываем навбар на экране профиля
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // скрываем навбар — уберётся и слово «Профиль», всё поднимется
        navigationController?.setNavigationBarHidden(true, animated: false)
        viewModel.onViewDidLoad(userId: user.uid)
    }
    
    // Возвращаем навбар при уходе с экрана
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // вернём бар на других экранах
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    // MARK: - Setup

    // Настройка верхней панели (аватар и вкладки)
    private func setupHeader() {
        // avatar
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))
        avatar.layer.cornerRadius = 18
        avatar.clipsToBounds = true

        // верхний «табар»
        configure(btnProfile, system: "person", tag: 0)
        configure(btnBoards,  system: "square.grid.2x2", tag: 1)
        configure(btnStudy,   system: "graduationcap",   tag: 2)

        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 16
        buttonsStack.alignment = .center
        buttonsStack.distribution = .fillEqually
        buttonsStack.addArrangedSubview(btnProfile)
        buttonsStack.addArrangedSubview(btnBoards)
        buttonsStack.addArrangedSubview(btnStudy)

        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        header.translatesAutoresizingMaskIntoConstraints = false

        let spacer = UIView()
        header.addArrangedSubview(avatar)
        header.addArrangedSubview(spacer)
        header.addArrangedSubview(buttonsStack)
        
        view.addSubview(header)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            avatar.widthAnchor.constraint(equalToConstant: 36),
            avatar.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func bind() {
        viewModel.onProfileUpdated = { [weak self] draft in
            self?.applyProfile(draft)
        }
        viewModel.onError = { [weak self] error in
            self?.showError(error)
        }
    }

    private func applyProfile(_ draft: ProfileDraft?) {
        let displayName = draft?.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        ? (draft?.displayName ?? user.name)
        : (user.displayName ?? user.name)

        let image = ProfileAvatarStore.shared.loadImage(path: draft?.avatarPath)
        avatar.configure(name: displayName, image: image)
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: (error as? LocalizedError)?.errorDescription ?? error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }

    // Настройка контейнера для дочерних контроллеров
    private func setupContainer() {
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8), // у header есть супервью
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // Конфигурация кнопки вкладки
    private func configure(_ b: UIButton, system name: String, tag: Int) {
        b.setImage(UIImage(systemName: name), for: .normal)
        b.tintColor = .label
        b.tag = tag
        b.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        b.heightAnchor.constraint(equalToConstant: 36).isActive = true
    }

    // MARK: - Actions

    // Обработка нажатия вкладки
    @objc private func tabTapped(_ sender: UIButton) {
        switch sender.tag {
        case 0: switchTo(.profile)
        case 1: switchTo(.boards)
        default: switchTo(.study)
        }
    }

    // Подсветка активной вкладки
    private func setActive(_ tab: Tab) {
        [btnProfile, btnBoards, btnStudy].forEach { $0.alpha = 0.6 }
        switch tab {
        case .profile: btnProfile.alpha = 1
        case .boards:  btnBoards.alpha = 1
        case .study:   btnStudy.alpha = 1
        }
    }

    // Встраивание дочернего контроллера в контейнер
    private func embed(_ child: UIViewController) {
        children.forEach { $0.willMove(toParent: nil); $0.view.removeFromSuperview(); $0.removeFromParent() }
        addChild(child)
        child.view.frame = container.bounds
        child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(child.view)
        child.didMove(toParent: self)
    }

    // Переключение между вкладками
    private func switchTo(_ tab: Tab) {
        setActive(tab)
        switch tab {
        case .profile: embed(infoVC)
        case .boards:  embed(boardsVC)
        case .study:   embed(studyVC)
        }
    }

    // Переход к экрану кастомизации профиля
    @objc private func avatarTapped() {
        let vc = ProfileCustomizationViewController(user: user, authService: authService)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Public API
extension ProfileViewController {
    // Открывает вкладку досок извне (например, после создания)
    func openBoardsTab() {
        switchTo(.boards)
        setActive(.boards)
    }
}
