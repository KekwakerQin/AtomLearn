import UIKit

protocol Holding: AnyObject {
    func updateData()
}

class CellViewController: UIViewController, Holding {
    func updateData() {
        //
    }
    
    var text: String?
    var themeOfPresentation: String?
    var label = UILabel()
    let label1 = UILabel()
    let btn = UIButton()
    private var loadingIndicator = UIActivityIndicatorView(style: .large)
    private var workItem: DispatchWorkItem?

    weak var p: Holding?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        self.p = self
        
        [label1, label, btn].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        view.addSubview(loadingIndicator)
        loadingIndicator.center = view.center
        loadingIndicator.style = .large
        
        loadingIndicator.startAnimating()

        btn.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.loadUser()
        }
        
        self.workItem = item
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: item)
        
        NSLayoutConstraint.activate([
            btn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            btn.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            btn.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            btn.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            btn.topAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            label1.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10),
            label1.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

    }
    
    func loadUser() {
        NetworkManager.shared.fetchUserProfile { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                
                switch result {
                case .success(let profile):
                    self.label.text = profile.name
                    self.label.textColor = .white
                case .failure(let error):
                    self.label.text = error as? String
                    self.label.textColor = .red
                }
                
                UIView.animate(withDuration: 0.6) { [weak self] in
                    self?.loadingIndicator.alpha = 0
                } completion: { [weak self] _ in
                    UIView.animate(withDuration: 0.6) {
                        self?.loadingIndicator.stopAnimating()
                        self?.label.alpha = 1
                    } completion: { [weak self] _ in
                        UIView.animate(withDuration: 0.6) {
                            self?.btn.alpha = 1
                        }

                    }
                }
            }
        }
        
        self.loadingIndicator.stopAnimating()
        self.label.alpha = 0
        self.label.textAlignment = .center
        self.label.font = .boldSystemFont(ofSize: 55)
        
        self.label1.text = self.themeOfPresentation ?? "None"
        self.label1.alpha = 0
        self.label1.font = .systemFont(ofSize: 22)
        self.label1.textAlignment = .center

        self.btn.titleLabel?.font = .systemFont(ofSize: 20)
        self.btn.setTitle("Back", for: .normal)
        self.btn.backgroundColor = .darkGray
        self.btn.alpha = 0
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("viewDidDisappear")
        workItem?.cancel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
        
    @objc func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
        navigationController?.popViewController(animated: true)
    }
    
    deinit {
        print("Deinited \(text) controller")
    }
}
