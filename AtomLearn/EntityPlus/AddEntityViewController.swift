// Экран создания сущности: борд или карточка
import UIKit
import FirebaseAuth
import FirebaseFirestore

final class AddEntityViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    // MARK: - Properties

    // Тип создаваемой сущности
    enum EntityType { case board, card }

    // Выбранный тип (борд/карточка)
    private var selectedType: EntityType?
    // Целевой борд для карточки
    private var selectedBoardID: String?
    // Список доступных бордов
    private var boards: [Board] = []
    // Сервис работы с бордами
    private let service: BoardsService

    // Контейнер для скролла
    private let scrollView = UIScrollView()
    // Коллбэк после успешного создания
    private let onCreated: () -> Void

    // MARK: - UI

    // Переключатель: Борд / Карточка
    private let typeSegment = UISegmentedControl(items: ["Борд", "Карточка"])
    // Выбор борда для карточки
    private let boardPicker = UIPickerView()
    // Поле заголовка (обязательное)
    private let titleField = UITextField()
    // Поле описания
    private let descField = UITextField()
    // Кнопка создания
    private let createButton = UIButton(type: .system)

    // MARK: - Init

    init(service: BoardsService, onCreated: @escaping () -> Void) {
        self.service = service
        self.onCreated = onCreated
        super.init(nibName: nil, bundle: nil)
    }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    // Настройка интерфейса и загрузка бордов
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        loadBoards()
    }

    // MARK: - Setup

    // Конфигурируем контролы, стек и жесты
    private func setupUI() {
        // Сегмент
        typeSegment.addTarget(self, action: #selector(typeChanged), for: .valueChanged)
        typeSegment.selectedSegmentIndex = 0
        selectedType = .board

        // Picker
        boardPicker.dataSource = self
        boardPicker.delegate = self

        // Поля
        titleField.placeholder = "Название*"
        titleField.borderStyle = .roundedRect
        titleField.returnKeyType = .next
        titleField.delegate = self
        titleField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)

        descField.placeholder = "Описание"
        descField.borderStyle = .roundedRect
        descField.returnKeyType = .done
        descField.delegate = self
        descField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)

        // Кнопка
        createButton.setTitle("Создать", for: .normal)
        createButton.isEnabled = false
        createButton.alpha = 0.5
        createButton.backgroundColor = .systemBlue
        createButton.tintColor = .white
        createButton.layer.cornerRadius = 10
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)

        // Скролл
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        view.addSubview(scrollView)

        let stack = UIStackView(arrangedSubviews: [typeSegment, boardPicker, titleField, descField, createButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 40),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        boardPicker.isHidden = true

        // Тап по фону — спрятать клаву
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        // Стартовая валидация
        updateButtonState()
    }

    // MARK: - Data

    // Подписка на борды текущего пользователя
    private func loadBoards() {
        let uid = Auth.auth().currentUser?.uid ?? "mock-user"
        service.observeBoards(ownerUID: uid) { [weak self] result in
            guard let self else { return }
            if case let .success(list) = result {
                self.boards = list
                self.boardPicker.reloadAllComponents()

                // Автоподстановка last/first при типе .card, если ещё не выбран борд
                if self.selectedType == .card && self.selectedBoardID == nil {
                    if let lastID = UserDefaults.standard.string(forKey: "lastBoardID"),
                       let idx = list.firstIndex(where: { $0.id == lastID }) {
                        self.selectedBoardID = lastID
                        self.boardPicker.selectRow(idx, inComponent: 0, animated: false)
                    } else if !list.isEmpty {
                        self.selectedBoardID = list[0].id
                        self.boardPicker.selectRow(0, inComponent: 0, animated: false)
                    }
                }
                self.updateButtonState()
            }
        }
    }

    // MARK: - Actions

    // Смена типа: показываем/скрываем picker
    @objc private func typeChanged() {
        selectedType = (typeSegment.selectedSegmentIndex == 0) ? .board : .card
        boardPicker.isHidden = (selectedType != .card)

        // При переключении на "Карточка" — подставим last/first, чтобы кнопка могла активироваться
        if selectedType == .card && selectedBoardID == nil {
            if let lastID = UserDefaults.standard.string(forKey: "lastBoardID"),
               let idx = boards.firstIndex(where: { $0.id == lastID }) {
                selectedBoardID = lastID
                boardPicker.selectRow(idx, inComponent: 0, animated: false)
            } else if !boards.isEmpty {
                selectedBoardID = boards[0].id
                boardPicker.selectRow(0, inComponent: 0, animated: false)
            }
        }
        updateButtonState()
        dismissKeyboard()
    }

    // Валидация при изменении текста
    @objc private func textDidChange() {
        updateButtonState()
    }

    // Скрыть клавиатуру
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // Активируем кнопку, если данные валидны
    private func updateButtonState() {
        let hasTitle = !(titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let canCreate: Bool
        switch selectedType {
        case .board:
            canCreate = hasTitle
        case .card:
            canCreate = hasTitle && (selectedBoardID != nil)
        case .none:
            canCreate = false
        }
        createButton.isEnabled = canCreate
        createButton.alpha = canCreate ? 1.0 : 0.5
    }

    // Создание борда или карточки
    @objc private func createTapped() {
        guard let type = selectedType else { return }
        let title = (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        let desc = descField.text ?? ""
        let uid = Auth.auth().currentUser?.uid ?? "mock-user"

        Task {
            do {
                switch type {
                case .board:
                    try await service.createBoard(ownerUID: uid, title: title, description: desc)
                case .card:
                    guard let boardID = selectedBoardID else { return }
                    // Запоминаем последний борд для автоподстановки
                    UserDefaults.standard.set(boardID, forKey: "lastBoardID")
                    try await Firestore.firestore()
                        .collection("boards").document(boardID)
                        .collection("cards")
                        .addDocument(data: [
                            "title": title,
                            "description": desc,
                            "createdAt": FieldValue.serverTimestamp()
                        ])
                }
                await MainActor.run {
                    self.dismiss(animated: true)
                    self.onCreated()
                }
            } catch {
                let a = UIAlertController(title: "Ошибка", message: error.localizedDescription, preferredStyle: .alert)
                a.addAction(UIAlertAction(title: "OK", style: .default))
                present(a, animated: true)
            }
        }
    }

    // MARK: - Picker

    // Один компонент — список бордов
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    // Количество строк = число бордов
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { boards.count }
    // Заголовок строки — название борда
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        boards[row].title
    }
    // Выбор борда и обновление состояния кнопки
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedBoardID = boards[row].id
        updateButtonState()
    }

    // MARK: - UITextFieldDelegate

    // Переключение фокуса: title → desc, затем скрыть клавиатуру
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === titleField {
            descField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
