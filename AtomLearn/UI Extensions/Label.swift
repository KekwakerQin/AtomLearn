import UIKit

enum FontWeight {
    case regular, medium, bold
    
    var uiFontWeight: UIFont.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .bold: return .bold
        }
    }
}

enum FontSize: CGFloat {
    case small = 16, standart = 24, large = 32
}

extension UILabel {
    static func make(text: String, _ size: FontSize = .standart, _ weight: FontWeight = .regular) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor(named: "TextColor")
        label.font = UIFont.systemFont(ofSize: size.rawValue, weight: weight.uiFontWeight)
        return label
    }
}

