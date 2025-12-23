import FirebaseAuth
import GoogleSignIn
import UIKit

/// Репозиторий данных авторизации: низкоуровневые вызовы Firebase/Google SDK.
final class FirebaseAuthRepository {
    // Вход через Google — создаёт Firebase-пользователя
    func signInWithGoogle(tokens: GoogleTokens) async throws -> AppUser {
        // Формируем credential из токенов Google
        let credential = FirebaseAuth.GoogleAuthProvider.credential(
            withIDToken: tokens.idToken,
            accessToken: tokens.accessToken
        )

        do {
            // Авторизуем пользователя через Firebase
            let authData = try await Auth.auth().signIn(with: credential)
            let u = authData.user
            return AppUser(
                uid: u.uid,
                name: u.displayName ?? "",
                email: u.email,
                displayName: u.displayName
            )
        } catch {
            throw AuthError.firebaseError(error)
        }
    }

    // Выход из аккаунта - Firebase + Google
    func signOut() async throws {
        do {
            // Выходим из Firebase
            try Auth.auth().signOut()
            
            // Чистим Google SignIn, чтобы при следующем входе не подхватывалась старая сессия
            if let _ = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                .first {
                GIDSignIn.sharedInstance.signOut()
            }
        } catch {
            throw AuthError.firebaseError(error)
        }
    }
}
