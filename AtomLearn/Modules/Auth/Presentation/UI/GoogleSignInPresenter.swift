import FirebaseCore
import GoogleSignIn
import UIKit

protocol GoogleSignInPresenting {
    @MainActor
    func signIn(from presenting: UIViewController) async throws -> GoogleTokens
}

// Провайдер входа через Google в UI-слое
final class GoogleSignInPresenter: GoogleSignInPresenting {
    @MainActor
    func signIn(from presenting: UIViewController) async throws -> GoogleTokens {
        // Берём clientID из Firebase-конфигурации
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.configurationMissing
        }
        // Настраиваем Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        // Запускаем нативный UI авторизации и ждём результат
        let result: GIDSignInResult = try await withCheckedThrowingContinuation { cont in
            GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { result, error in
                // Ошибка провайдера (например, отмена пользователем)
                if let error {
                    // -5 обычно cancel; оставим общий обработчик кратко
                    cont.resume(throwing: AuthError.providerError(error)); return
                }
                guard let result else { cont.resume(throwing: AuthError.unknown); return }
                cont.resume(returning: result)
            }
        }

        // Достаём токены из результата
        guard let idToken = result.user.idToken?.tokenString else { throw AuthError.unknown }
        let accessToken = result.user.accessToken.tokenString
        return GoogleTokens(idToken: idToken, accessToken: accessToken) // Возвращаем пару токенов
    }
}
