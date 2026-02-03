import UIKit

extension UIViewController {
    /// Hides keyboard when tapping outside inputs.
    func enableKeyboardDismissOnTap(cancelsTouchesInView: Bool = false) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleKeyboardDismissTap))
        tap.cancelsTouchesInView = cancelsTouchesInView
        view.addGestureRecognizer(tap)
    }

    @objc private func handleKeyboardDismissTap() {
        view.endEditing(true)
    }
}
