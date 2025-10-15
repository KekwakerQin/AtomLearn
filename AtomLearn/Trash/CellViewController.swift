import UIKit

class CellViewController: UIViewController {
    var text: String?
    var themeOfPresentation: String?
    let label = UILabel()
    let label1 = UILabel()
    let btn = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        label.text = text
        label.alpha = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 55)
        view.addSubview(label)
        
        label1.text = themeOfPresentation ?? "None"
        label1.alpha = 0
        label1.font = .systemFont(ofSize: 22)
        label1.textAlignment = .center
        label1.textColor = .white
        label1.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label1)

        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.titleLabel?.font = .systemFont(ofSize: 20)
        btn.setTitle("Back", for: .normal)
        btn.backgroundColor = .darkGray
        btn.alpha = 0
        btn.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        view.addSubview(btn)
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animate(withDuration: 0.6) {
            self.label.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.6) {
                self.label1.alpha = 1
            } completion: { _ in
                UIView.animate(withDuration: 0.6) {
                    self.btn.alpha = 1
                }

            }
        }
    }
        
    @objc func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
    
    deinit {
        print("Deinited \(text) controller")
    }
}
