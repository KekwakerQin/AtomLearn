import UIKit

class WindowTestViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // Создаём экземпляр кастомной вью
        let debugView = DebugTouchableView()
        debugView.frame = CGRect(x: 100, y: 200, width: 200, height: 50)
        debugView.backgroundColor = .systemGray6

        // Добавляем вью в иерархию
        view.addSubview(debugView)
    }
}

class DebugTouchableView: UIView {
    let touchMargin: CGFloat = 100

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expandedBounds = bounds.insetBy(dx: -touchMargin, dy: -touchMargin)
        return expandedBounds.contains(point)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Рисуем обычную границу
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.stroke(bounds)

        // Рисуем расширенную кликабельную зону
        let expandedBounds = bounds.insetBy(dx: -touchMargin, dy: -touchMargin)
        context.setStrokeColor(UIColor.systemRed.cgColor)
        context.setLineDash(phase: 0, lengths: [4, 4])
        context.stroke(expandedBounds)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("🔴 Touched inside DebugTouchableView!")
    }
}
