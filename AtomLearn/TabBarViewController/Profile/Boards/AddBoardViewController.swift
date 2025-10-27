import UIKit

final class AddBoardViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    private let onCreate: (String, String) -> Void

    init(onCreate: @escaping (String, String) -> Void) {
        self.onCreate = onCreate
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private let titleField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Название*"
        tf.borderStyle = .roundedRect
        return tf
    }()
    private let descView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.layer.cornerRadius = 8
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.separator.cgColor
        return tv
    }()
    private let createBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Создать", for: .normal)
        b.backgroundColor = .systemBlue
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 12
        b.heightAnchor.constraint(equalToConstant: 50).isActive = true
        b.isEnabled = false
        b.alpha = 0.5
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        title = "Новая доска"
        if let sheet = presentationController as? UISheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.selectedDetentIdentifier = .medium
        }

        titleField.delegate = self
        descView.delegate = self
        createBtn.addTarget(self, action: #selector(createTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            titleField,
            descView,
            createBtn
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        titleField.translatesAutoresizingMaskIntoConstraints = false
        descView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            descView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }

    private func validate() {
        let ok = !(titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        createBtn.isEnabled = ok
        createBtn.alpha = ok ? 1.0 : 0.5
    }

    func textFieldDidChangeSelection(_ textField: UITextField) { validate() }
    func textViewDidChange(_ textView: UITextView) { /* описание опционально */ }

    @objc private func createTapped() {
        let title = (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = descView.text ?? ""
        guard !title.isEmpty else { return }
        onCreate(title, desc)
        dismiss(animated: true)
    }
}
