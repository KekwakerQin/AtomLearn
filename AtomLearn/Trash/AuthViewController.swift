import UIKit

class AuthViewController: UIViewController {
    
    // MARK: - ITEMS -
    
    var titleLabel = UILabel.make("Atom Learn", .large, .bold)
    var titleLabel1 = UILabel.make("Auth1", .standart, .medium)
    var titleLabel2 = UILabel.make("Auth2", .small, .regular)
    var button = UIButton()

    var stackView = UIStackView()

    // MARK: - SCREEN -

    override func viewDidLoad() {
        super.viewDidLoad()
        print("loaded")
        view.backgroundColor = UIColor(named: "BackgroundColor")
        setupUI()
        setupViews()
        setupButton()
        setupConstraints()
        
    }
    
    // MARK: - SETUPS -
    
    func setupButton() {
        
        button.backgroundColor = .black
        button.setTitle("Нажать", for: .normal)
        button.setTitle("Нажимаем...", for: .highlighted)
        button.setTitle("Нажата!", for: .selected)
        button.setTitle("Дальше - некуда", for: [.selected, .highlighted])
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        var doubleTap = UITapGestureRecognizer(target: self, action: #selector(makeReaction))
        doubleTap.numberOfTapsRequired = 2
        button.addGestureRecognizer(doubleTap)
    }
    
    func setupUI() {
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 60
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(titleLabel1)
        stackView.addArrangedSubview(titleLabel2)
        stackView.addArrangedSubview(button)
        stackView.backgroundColor = .blue
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            
        ])
    }
    
    func setupViews() {
        view.addSubview(stackView)
    }
    
    // MARK: - METHODS -
    
    var counter = 0
    var doubleTouch = 0
    var isAnimated = false
    
    @objc private func buttonTapped() {
        
        guard !isAnimated else {
            print("Не пропустили")
            return
        }
        
        isAnimated = true
        
        self.button.isEnabled = false
        
        UIView.animate(withDuration: 5) {
            self.button.setTitle("Loading...", for: .normal)
            self.button.backgroundColor = .red
        } completion: { _ in
            UIView.animate(withDuration: 1) {
                self.button.setTitle("Load", for: .normal)
            } completion: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    UIView.animate(withDuration: 0.3) {
                        self.button.setTitle("Repeat", for: .normal)
                        self.button.backgroundColor = .black
                    }
                    self.isAnimated = false
                    self.button.isEnabled = true
                    print("[LOG BUTTON] : Finished")
                    
                }
            }
        }
    }
    @objc private func makeReaction() {
        print(doubleTouch)
        guard doubleTouch % 2 == 0 else {
            doubleTouch += 1
            return
        }
        titleLabel1.text = "Make Reaction"
        print("Реакция вызвалась \(counter)")
        doubleTouch += 1
        counter += 1
    }
}
