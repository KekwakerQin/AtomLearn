import UIKit

/// UI-утилита для анимации текста на экране авторизации.
final class AuthLabelAnimator {
    private let labels: [String]
    private let fadeInDuration: TimeInterval
    private let visibleDuration: TimeInterval
    private let fadeOutDuration: TimeInterval
    private var currentIndex = 0
    private var isAnimating = false

    init(
        labels: [String] = StorageOfLabels.russian,
        fadeInDuration: TimeInterval = 0.65,
        visibleDuration: TimeInterval = 2.0,
        fadeOutDuration: TimeInterval = 0.3
    ) {
        self.labels = labels
        self.fadeInDuration = fadeInDuration
        self.visibleDuration = visibleDuration
        self.fadeOutDuration = fadeOutDuration
    }

    func startAnimating(label: UILabel) {
        guard !isAnimating, !labels.isEmpty else { return }
        isAnimating = true
        animate(label: label)
    }

    func stopAnimating() {
        isAnimating = false
    }

    private func animate(label: UILabel) {
        guard isAnimating else { return }
        label.alpha = 0
        label.text = labels[currentIndex]

        UIView.animate(withDuration: fadeInDuration) {
            label.alpha = 1
        } completion: { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + self.visibleDuration) {
                UIView.animate(withDuration: self.fadeOutDuration) {
                    label.alpha = 0
                } completion: { [weak self] _ in
                    guard let self else { return }
                    self.currentIndex = (self.currentIndex + 1) % self.labels.count
                    self.animate(label: label)
                }
            }
        }
    }
}
