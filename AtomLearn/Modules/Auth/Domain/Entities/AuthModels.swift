import Foundation

// Пара токенов от Google — для авторизации через Firebase
struct GoogleTokens {
    let idToken: String
    let accessToken: String
}

// Модель пользователя приложения
struct AppUser: Decodable {
    let uid: String
    let name: String
    let email: String?
    let displayName: String? // Отображаемое имя (если есть)
}

// Возможные ошибки авторизации
enum AuthError: Error {
    case configurationMissing // Не найден clientID или конфигурация
    case userCancelled // Пользователь отменил вход
    case providerError(Error) // Ошибка со стороны провайдера (Google и др.)
    case firebaseError(Error) // Ошибка Firebase
    case unknown // Непредвиденная ошибка
}
