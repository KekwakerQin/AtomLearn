import FirebaseAuth
import GoogleSignIn

/// Service API для работы с авторизацией без зависимостей на UIKit.
protocol AuthService {
    /// Выполняет вход через Google и возвращает пользователя.
    func signInWithGoogle(tokens: GoogleTokens) async throws -> AppUser
    /// Выполняет выход пользователя из приложения.
    func signOut() async throws
    /// Возвращает текущего пользователя, если он авторизован.
    func currentUser() -> AppUser? // Геттер текущего пользователя
}

/// Реализация сервиса авторизации: бизнес-логика Auth и вызовы репозитория.
final class AuthServiceImpl: AuthService {
    // MARK: - Dependencies
    private let repo: AuthRepositoryProtocol

    // MARK: - Init
    /// Внедрение зависимостей (провайдер и репозиторий).
    init(
        source: ServiceSource = .firestore,
        repo: AuthRepositoryProtocol? = nil
    ) {
        if let repo {
            self.repo = repo
        } else {
            self.repo = ServiceFactory.make(AuthRepositoryFactory.self, source: source)
        }
    }

    // MARK: - AuthService
    /// Вход через Google (двойной шаг: Google SDK → Firebase).
    func signInWithGoogle(tokens: GoogleTokens) async throws -> AppUser {
        // Авторизация через репозиторий
        let user = try await repo.signInWithGoogle(tokens: tokens)

        print("[LOG:INFO] AuthService signed in as: \(user.uid)")
        return user
    }

    /// Выход из аккаунта.
    @MainActor
    func signOut() async throws {
        // 1) Google Sign-Out (если пользователь входил через Google)
        // Это безопасно вызывать даже если не был залогинен.
        GIDSignIn.sharedInstance.signOut()

        // Если ты хочешь “жёстко” отвязать доступ (revoke), можно так:
        // GIDSignIn.sharedInstance.disconnect { error in ... }
        // Но disconnect async — обычно для обычного “Выйти” достаточно signOut().

        // 2) Firebase Sign-Out
        do {
            try Auth.auth().signOut()
        } catch {
            throw AuthServiceError.unknown(error)
        }

        // 3) Если у тебя есть свой accessToken в Keychain/UserDefaults — почисти тут.
        // tokenStore.clear()
    }

    /// Получение текущего пользователя (если авторизован).
    func currentUser() -> AppUser? {
        guard let fbUser = Auth.auth().currentUser else { return nil }
        return AppUser(
            uid: fbUser.uid,
            name: fbUser.displayName ?? "",
            email: fbUser.email,
            displayName: fbUser.displayName
        )
    }
}

enum AuthServiceError: LocalizedError {
    case googleSignOutFailed
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .googleSignOutFailed:
            return "Не удалось выполнить выход из Google."
        case .unknown(let error):
            return "Ошибка выхода: \(error.localizedDescription)"
        }
    }
}
