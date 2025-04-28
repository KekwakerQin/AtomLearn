import UIKit

extension UIButton {
    static func standart(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor(named: "BackgroundColor"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        button.backgroundColor = UIColor(named: "TextColor")
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}

extension UIView {
    static func setupView(view: UIView) -> UIView {
        let view = view
        view.backgroundColor = UIColor(named: "BackgroundColor")
        return view
    }
}
