import FirebaseAuth

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
    private let repo: FirebaseAuthRepository

    // MARK: - Init
    /// Внедрение зависимостей (провайдер и репозиторий).
    init(
        repo: FirebaseAuthRepository = .init()
    ) {
        self.repo = repo
    }

    // MARK: - AuthService
    /// Вход через Google (двойной шаг: Google SDK → Firebase).
    func signInWithGoogle(tokens: GoogleTokens) async throws -> AppUser {
        // Авторизация через Firebase
        let user = try await repo.signInWithGoogle(tokens: tokens)

        print("[LOG:INFO] AuthService signed in as: \(user.uid)")
        return user
    }

    /// Выход из аккаунта.
    @MainActor
    func signOut() async throws {
        try await repo.signOut()  // выход из Firebase
        print("[LOG:INFO] AuthService user signed out")
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
