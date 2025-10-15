import UIKit
import FirebaseCore
import GoogleSignIn

final class GoogleAuthProvider {
    func signIn(from presenting: UIViewController) async throws -> GoogleTokens {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.configurationMissing
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        let result: GIDSignInResult = try await withCheckedThrowingContinuation { cont in
            GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { result, error in
                if let error {
                    // -5 обычно cancel; оставим общий обработчик кратко
                    cont.resume(throwing: AuthError.providerError(error)); return
                }
                guard let result else { cont.resume(throwing: AuthError.unknown); return }
                cont.resume(returning: result)
            }
        }

        guard let idToken = result.user.idToken?.tokenString else { throw AuthError.unknown }
        let accessToken = result.user.accessToken.tokenString
        return GoogleTokens(idToken: idToken, accessToken: accessToken)
    }
}
