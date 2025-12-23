import Foundation

/// Источники данных для сервисов (Firestore/Supabase/локальное хранилище).
enum ServiceSource {
    case firestore
    case supabase
    case local
}

/// Базовый протокол фабрики сервиса с выбором источника данных.
protocol ServiceProtocol {
    associatedtype Service

    /// Создаёт сервис для выбранного источника.
    static func make(source: ServiceSource) -> Service
}

/// Универсальная фабрика для создания сервисов по источнику данных.
struct ServiceFactory {
    /// Возвращает сервис из конкретной фабрики.
    static func make<T: ServiceProtocol>(_ type: T.Type = T.self, source: ServiceSource) -> T.Service {
        T.make(source: source)
    }
}
