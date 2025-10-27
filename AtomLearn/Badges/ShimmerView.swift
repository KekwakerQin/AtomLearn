import UIKit

final class ShimmerView: UIView {
    private let gradient = CAGradientLayer()
    private var animating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = UIColor.secondarySystemFill
        gradient.colors = [
            UIColor.secondarySystemFill.cgColor,
            UIColor.tertiarySystemFill.cgColor,
            UIColor.secondarySystemFill.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.locations = [0, 0.5, 1]
        layer.addSublayer(gradient)
        layer.masksToBounds = true
        layer.cornerRadius = 8
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds.insetBy(dx: -bounds.width, dy: 0) // запас для анимации
    }

    func start() {
        guard !animating else { return }
        animating = true
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = 1.25
        animation.repeatCount = .infinity
        gradient.add(animation, forKey: "shimmer")
        isHidden = false
    }

    func stop() {
        animating = false
        gradient.removeAnimation(forKey: "shimmer")
        isHidden = true
    }
}
