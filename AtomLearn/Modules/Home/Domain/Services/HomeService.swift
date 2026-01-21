import Foundation

/// Модель файла бейджа для домашнего экрана.
struct HomeBadgeFile: Equatable {
    /// Имя файла.
    let name: String
    /// URL файла в хранилище.
    let url: URL
}

/// Протокол сервиса для домашнего экрана.
protocol HomeService {
    /// Возвращает список файлов бейджей.
    func fetchBadgeList() async throws -> [HomeBadgeFile]
    /// Загружает изображение по URL.
    func loadImage(url: URL) async throws -> Data
}
