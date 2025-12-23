import FirebaseAuth

// Протокол сервиса авторизации
protocol AuthService {
    func signInWithGoogle(tokens: GoogleTokens) async throws -> AppUser
    func signOut() async throws
    func currentUser() -> AppUser? // Геттер текущего пользователя
}

// Реализация сервиса авторизации через Firebase + Google
final class AuthServiceImpl: AuthService {
    private let repo: FirebaseAuthRepository

    // Внедрение зависимостей (провайдер и репозиторий)
    init(
        repo: FirebaseAuthRepository = .init()
    ) {
        self.repo = repo
    }

    // MARK: - Sign In

    // Вход через Google (двойной шаг: Google SDK → Firebase)
    func signInWithGoogle(tokens: GoogleTokens) async throws -> AppUser {
        // Авторизация через Firebase
        let user = try await repo.signInWithGoogle(tokens: tokens)

        print("[LOG:INFO] AuthService signed in as: \(user.uid)")
        return user
    }

    // MARK: - Sign Out

    // Выход из аккаунта
    @MainActor
    func signOut() async throws {
        try await repo.signOut()  // выход из Firebase
        print("[LOG:INFO] AuthService user signed out")
    }

    // MARK: - Current user (по Firebase напрямую)

    // Получение текущего пользователя (если авторизован)
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
