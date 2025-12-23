import UIKit

final class ShimmerView: UIView {
    private let gradient = CAGradientLayer()
    private var isAnimating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.masksToBounds = true
        layer.cornerRadius = 8

        // более контрастные цвета (видно и в light, и в dark)
        let base = UIColor.systemGray5.cgColor
        let highlight = UIColor.systemGray4.cgColor

        gradient.colors = [base, highlight, base]
        gradient.locations = [0, 0.5, 1]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(gradient)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Делаем слой шире, чтобы «блик» мог уехать за границы
        gradient.frame = bounds.insetBy(dx: -bounds.width, dy: 0)
    }

    func start() {
        guard !isAnimating else { return }
        isAnimating = true
        isHidden = false

        // Анимация «блика» через сдвиг locations
        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue = [-1, -0.5, 0]
        anim.toValue   = [1, 1.5, 2]
        anim.duration = 1.2
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        gradient.add(anim, forKey: "shimmer.locations")
    }

    func stop() {
        isAnimating = false
        gradient.removeAnimation(forKey: "shimmer.locations")
        isHidden = true
    }
}
