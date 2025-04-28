import UIKit

enum IconFactory {
    
    static func makeSymbol(name: String,
                           size: CGFloat = 24,
                           tintColor: UIColor = .label) -> UIImageView {
        let imageView = UIImageView(image: UIImage(systemName: name)? .withRenderingMode(.alwaysTemplate))
        imageView.tintColor = tintColor
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: size).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: size).isActive = true
        return imageView
    }
    
}
