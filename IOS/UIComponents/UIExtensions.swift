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

extension UILabel {
    static func standardForHeadingLabel(_ text: String) -> UILabel {
        let label = UILabel()
        
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = UIColor(named: "TextColor")
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }
    
    static func subText(_ text: String) -> UILabel {
        let label = UILabel()
        
        label.text = text
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = UIColor(named: "TextColor")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        
        return label
    }

}

extension UITextField {
    static func standartForCreatingField(_ text: String) -> UITextField {
        let textField = UITextField()
        
        textField.placeholder = text
//        textField.backgroundColor = UIColor(named: "BackgroundColor")?.withAlphaComponent(0.8)
        textField.backgroundColor = .lightGray
        textField.tintColor = UIColor(named: "BackgroundColor")
        textField.layer.cornerRadius = 12
        textField.layer.masksToBounds = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.font = .systemFont(ofSize: 16)
        
        return textField
    }
    
 
}

extension UIPickerView {
    static func standartForCreatingPicker(_ options: [String]) {
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            options.count
        }
        
        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            options[row]
        }
        
        func pickerView(_ pickerView: UIPickerView, didSElectRow row: Int, inComponent component: Int ) {
            
        }
    }
}
