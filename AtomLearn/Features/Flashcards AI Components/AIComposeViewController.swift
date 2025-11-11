import UIKit

/// Экран "Сгенерировать с ИИ":
/// - Вставляешь исходный текст
/// - Выбираешь кол-во карточек (подсказка модели)
/// - Нажимаешь "Сгенерировать" → LLM → парсим → пишем батчем в Firestore
final class AIComposeViewController: UIViewController, UITextViewDelegate {

    // Входные зависимости
    private let boardId: String
    private let owner: AppUser
    private let ai: FlashcardAIServiceProtocol

    // UI
    private let sourceText = UITextView()
    private let countStepper = UIStepper()
    private let countLabel = UILabel()
    private let generateButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)

    // Сколько просим карточек у модели (подсказка, не гарантия)
    private var desiredCount: Int = 5 {
        didSet { updateCountUI() }
    }

    init(boardId: String, owner: AppUser, ai: FlashcardAIServiceProtocol) {
        self.boardId = boardId
        self.owner = owner
        self.ai = ai
        super.init(nibName: nil, bundle: nil)
    }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Сгенерировать с ИИ"
        view.backgroundColor = .systemBackground
        setupUI()
    }

    // --- UI-настройка, всё предельно просто ---
    private func setupUI() {
        // Текстовая область под исходник
        sourceText.font = .systemFont(ofSize: 16)
        sourceText.layer.cornerRadius = 12
        sourceText.layer.borderWidth = 1
        sourceText.layer.borderColor = UIColor.separator.cgColor
        sourceText.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        sourceText.delegate = self
        sourceText.text = "Вставьте текст для генерации карточек…"
        sourceText.textColor = .placeholderText
        sourceText.isScrollEnabled = true

        // Степпер и лейбл — сколько карточек хотим
        countStepper.minimumValue = 1
        countStepper.maximumValue = 20
        countStepper.value = Double(desiredCount)
        countStepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
        updateCountUI()

        // Кнопка "Сгенерировать"
        generateButton.setTitle("Сгенерировать", for: .normal)
        generateButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        generateButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
//        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        generateButton.addTarget(self, action: #selector(generateBase), for: .touchUpInside)
        
        spinner.hidesWhenStopped = true

        // Вёрстка — обычный вертикальный стек
        let countRow = UIStackView(arrangedSubviews: [countLabel, countStepper])
        countRow.axis = .horizontal
        countRow.alignment = .center
        countRow.distribution = .fill
        countRow.spacing = 12

        let stack = UIStackView(arrangedSubviews: [
            sectionTitle("Исходный текст"),
            sourceText,
            sectionTitle("Сколько карточек"),
            countRow,
            generateButton,
            spinner
        ])
        stack.axis = .vertical
        stack.spacing = 12

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        sourceText.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            sourceText.heightAnchor.constraint(equalToConstant: 220)
        ])
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .secondaryLabel
        return l
    }

    private func updateCountUI() {
        countLabel.text = "Целевое число карточек: \(desiredCount)"
    }

    // --- Действия ---
    @objc private func stepperChanged() {
        desiredCount = Int(countStepper.value)
    }
    
    @objc private func generateBase() {
        Task {
            await testPing()
        }
    }

    @objc private func generateTapped() {
        // валидируем текст
        let raw = sourceText.textColor == .placeholderText ? "" : (sourceText.text ?? "")
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            alert("Вставьте текст для генерации.")
            return
        }

        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                // 1) Генерим карточки локально (Card)
                let cards = try await ai.generateCards(
                    sourceText: text,
                    boardId: boardId,
                    ownerId: owner.uid,
                    countHint: desiredCount
                )
                // 2) Пишем их батчем в Firestore
                try await ai.saveToFirestore(cards)
                await MainActor.run {
                    self.setLoading(false)
                    self.alert("Готово! Добавлено: \(cards.count)") {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.alert("Ошибка: \(error.localizedDescription)")
                }
            }
        }
    }

    private func setLoading(_ flag: Bool) {
        generateButton.isEnabled = !flag
        flag ? spinner.startAnimating() : spinner.stopAnimating()
    }
    
    // MARK: - Test ping
    func testPing() async {
        struct ChatMessage: Codable { let role: String; let content: String }
        struct ChatRequest: Codable {
            let model: String
            let messages: [ChatMessage]
            let max_tokens: Int
            let temperature: Double
        }
        struct Choice: Codable { let message: ChatMessage?; let text: String? }
        struct ChatResponse: Codable { let choices: [Choice] }
        struct ORError: Codable { struct Inner: Codable { let message: String?; let type: String? }
            let error: Inner?
        }

        // 0) Быстрая проверка ключа
        guard !AppConfig.openRouterAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("OpenRouter API key пустой.")
            return
        }
        
        // 1) Валидация ключа
           let rawKey = AppConfig.openRouterAPIKey
           let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
           guard key.hasPrefix("sk-or-"), key.count > 20 else {
               print("OpenRouter API key пустой/неверный. Сейчас: \(key.isEmpty ? "<empty>" : key.prefix(8) + "...")")
               return
           }

        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(AppConfig.openRouterAPIKey)", forHTTPHeaderField: "Authorization")
        // для free-моделей и некоторых ключей:
        req.setValue("https://atomlearn.app", forHTTPHeaderField: "HTTP-Referer")
        req.setValue("AtomLearn iOS", forHTTPHeaderField: "X-Title")

        let body = ChatRequest(
            // "meta-llama/llama-3.3-70b-instruct:free"
            // "mistralai/mistral-7b-instruct:free"
            model: "nvidia/nemotron-nano-9b-v2:free",
            messages: [.init(role: "user", content: "Привет! Отвечай с подробным описанием и усложни задачу чтобы я точно не понял ответп. Вопрос: 2+2?")],
            max_tokens: 50,
            temperature: 0.2
        )

        do {
            req.httpBody = try JSONEncoder().encode(body)
        } catch {
            print("Не удалось кодировать тело запроса:", error.localizedDescription)
            return
        }

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            let http = resp as? HTTPURLResponse
            let status = http?.statusCode ?? -1

            // Печатаем raw-ответ для диагностики
            let raw = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            print("HTTP \(status)")
            print("RAW:\n\(raw)")

            // Если статус не 2xx — пробуем декодировать ошибку OpenRouter
            guard (200...299).contains(status) else {
                if let orErr = try? JSONDecoder().decode(ORError.self, from: data),
                   let msg = orErr.error?.message {
                    print("OpenRouter error:", msg)
                } else {
                    print("Нестандартная ошибка (статус \(status))")
                }
                return
            }

            // Пробуем обычный ответ Chat API
            if let decoded = try? JSONDecoder().decode(ChatResponse.self, from: data),
               let first = decoded.choices.first {
                // Некоторые провайдеры кладут текст в message.content, некоторые — просто в text
                let content = first.message?.content ?? first.text ?? "<пусто>"
                print("Ответ от модели:", content)
            } else {
                // Может прийти не тот формат → пытаемся показать, что именно внутри
                print("Не удалось распарсить ChatResponse, см. RAW выше.")
            }
        } catch {
            print("Ошибка сети/декодирования:", error.localizedDescription)
        }
    }
    //MARK: - DELETE UP


    private func alert(_ msg: String, completion: (() -> Void)? = nil) {
        let a = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(a, animated: true)
    }

    // placeholder-поведение
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = nil
            textView.textColor = .label
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text?.isEmpty == true {
            textView.text = "Вставьте текст для генерации карточек…"
            textView.textColor = .placeholderText
        }
    }
}


