import UIKit

// Расширение для получения активного окна приложения
extension UIApplication {
    // Текущее главное окно (keyWindow)
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

// Переключение корневого контроллера с анимацией
func switchRoot(to newRoot: UIViewController, animated: Bool = true, duration: TimeInterval = 0.25) {
    // Получаем главное окно
    guard let window = UIApplication.shared.keyWindow else {
        // Фолбэк: если окно не найдено, просто назначаем root
        UIApplication.shared.keyWindow?.rootViewController = newRoot
        return
    }

    // Временно отключаем/включаем анимации
    let oldState = UIView.areAnimationsEnabled
    UIView.setAnimationsEnabled(animated)

    window.rootViewController = newRoot
    guard animated else { return }

    // Настройка анимации перехода
    let transition = CATransition()
    transition.type = .fade
    transition.duration = duration
    window.layer.add(transition, forKey: kCATransition)
    // Возвращаем исходное состояние анимаций
    UIView.setAnimationsEnabled(oldState)
}
