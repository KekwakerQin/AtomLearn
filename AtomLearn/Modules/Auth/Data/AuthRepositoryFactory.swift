import Foundation

/// Протокол репозитория авторизации для подмены источника данных.
protocol AuthRepositoryProtocol {
    /// Вход через Google и возврат пользователя.
    func signInWithGoogle(tokens: GoogleTokens) async throws -> AppUser
    /// Выход пользователя.
    func signOut() async throws
}

/// Фабрика репозиториев авторизации для выбора источника данных.
struct AuthRepositoryFactory: ServiceProtocol {
    static func make(source: ServiceSource) -> AuthRepositoryProtocol {
        switch source {
        case .firestore:
            return FirebaseAuthRepository()
        case .supabase:
            return SupabaseAuthRepository()
        case .local:
            return LocalAuthRepository()
        }
    }
}

/// Заготовка репозитория под Supabase (stub).
final class SupabaseAuthRepository: AuthRepositoryProtocol {
    func signInWithGoogle(tokens: GoogleTokens) async throws -> AppUser {
        throw AuthError.unknown
    }

    func signOut() async throws {
        // TODO(Auth): реализовать выход через Supabase.
    }
}

/// Заготовка локального репозитория (stub, например, для офлайн/моков).
final class LocalAuthRepository: AuthRepositoryProtocol {
    func signInWithGoogle(tokens: GoogleTokens) async throws -> AppUser {
        throw AuthError.unknown
    }

    func signOut() async throws {
        // TODO(Auth): реализовать локальный выход.
    }
}
