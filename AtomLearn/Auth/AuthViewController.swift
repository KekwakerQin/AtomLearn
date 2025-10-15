import UIKit

class AuthViewController: UIViewController {
    private let label = UILabel.make(text: "")
    private let stack = UIStackView()
    private let container = UIView()
    
    let button = UIButton(type: .system) // No in stack
    
    func addToStack() {
        [label].forEach {
            stack.addArrangedSubview($0)
        }
    }
    
    func removeTAMIC() {
        [container, button, stack, label].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addViews()
        setupUI()
        setupConstraints()
        view.backgroundColor = .black
    }
    
    override func viewDidAppear(_ animate: Bool) {
        super.viewDidAppear(true)
        label.alpha = 0
        
        animateLabel()
    }
    
    // MARK: - UI SETUP
    
    private func animateLabel(index: Int = 0) {
        guard index < StorageOfLabels.russian.count else { return }
        
        label.alpha = 0
        label.text = StorageOfLabels.russian[index]
        
        UIView.animate(withDuration: 0.65) {
            self.label.alpha = 1
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                UIView.animate(withDuration: 0.3) {
                    self.label.alpha = 0
                } completion: { _ in
                    let next = (index + 1) % StorageOfLabels.russian.count
                    self.animateLabel(index: next)
                }
            }
        }
    }
    
    private func setupUI() {
        // BUTTONS
        button.setTitle("Нажми", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(tap), for: .touchUpInside)
        
        // STACK
        stack.axis = .vertical
        stack.alignment = .center
        
        // LABELS
        label.textColor = .white
    }
    
    private func addViews() {
        // View
        view.addSubview(stack)
        view.addSubview(button)
        view.addSubview(container)
        
        // Stack
        addToStack()
    }
    
    private func setupConstraints() {
        removeTAMIC()
        
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 60),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: button.topAnchor),
            
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            
            ])
    }
    
    //MARK: - TARGETS
    
    @objc private func tap() {
        print("Tapped")
    }
}

