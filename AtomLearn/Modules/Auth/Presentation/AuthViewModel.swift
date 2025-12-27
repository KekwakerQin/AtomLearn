import UIKit

/// Coordinator API for Auth flow navigation.
protocol AuthCoordinating: AnyObject {
    func showMain(for user: AppUser, animated: Bool)
}

/// ViewModel экрана авторизации: состояние, бизнес-логика, обработка ошибок и вызовы сервисов.
final class AuthViewModel {
    private let authService: AuthService
    private let signInPresenter: GoogleSignInPresenting
    private weak var coordinator: AuthCoordinating?

    weak var presentingViewController: UIViewController?

    var onLoadingChange: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    var onLabelAnimationStart: (() -> Void)?

    init(
        authService: AuthService,
        signInPresenter: GoogleSignInPresenting,
        coordinator: AuthCoordinating
    ) {
        self.authService = authService
        self.signInPresenter = signInPresenter
        self.coordinator = coordinator
    }

    public func onViewDidAppear() {
        onLabelAnimationStart?()
    }

    public func onSignInTap() {
        guard let presentingViewController else {
            onError?("Нет активного экрана для авторизации.")
            return
        }

        onLoadingChange?(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                let tokens = try await signInPresenter.signIn(from: presentingViewController)
                let user = try await authService.signInWithGoogle(tokens: tokens)
                await MainActor.run {
                    self.onLoadingChange?(false)
                    self.coordinator?.showMain(for: user, animated: true)
                }
            } catch {
                let message = self.message(for: error)
                await MainActor.run {
                    self.onLoadingChange?(false)
                    self.onError?(message)
                }
            }
        }
    }

    private func message(for error: Error) -> String {
        if let authError = error as? AuthError {
            switch authError {
            case .configurationMissing: return "Нет конфигурации Firebase."
            case .userCancelled: return "Вход отменён."
            case .providerError(let underlying): return "Ошибка Google: \(underlying.localizedDescription)"
            case .firebaseError(let underlying): return "Ошибка Firebase: \(underlying.localizedDescription)"
            case .unknown: return "Неизвестная ошибка."
            }
        }
        return error.localizedDescription
    }
}
