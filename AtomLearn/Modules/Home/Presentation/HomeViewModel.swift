import Foundation

/// Состояние домашнего экрана.
struct HomeViewState: Equatable {
    /// Текст статуса.
    let statusText: String
    /// Данные изображения.
    let imageData: Data?
}

/// ViewModel для домашнего экрана.
final class HomeViewModel {
    // MARK: - Dependencies
    private let service: HomeService

    // MARK: - Public API
    /// Коллбэк для обновления состояния.
    var onStateChange: ((HomeViewState) -> Void)?
    /// Коллбэк для ошибок.
    var onError: ((Error) -> Void)?

    // MARK: - Init
    /// Создаёт ViewModel домашнего экрана.
    init(service: HomeService) {
        self.service = service
    }

    // MARK: - Lifecycle
    /// Запускает загрузку данных домашнего экрана.
    func load() {
        Task { await loadContent() }
    }

    // MARK: - Private helpers
    private func loadContent() async {
        await publish(state: HomeViewState(statusText: "Загрузка...", imageData: nil))

        do {
            let files = try await service.fetchBadgeList()
            guard let first = files.first else {
                await publish(state: HomeViewState(statusText: "В папке нет файлов", imageData: nil))
                return
            }

            let data = try await service.loadImage(url: first.url)
            let status = "Файлов: \(files.count)\nПервый файл: \(first.name)"
            await publish(state: HomeViewState(statusText: status, imageData: data))
        } catch {
            await publish(error: error)
        }
    }

    @MainActor
    private func publish(state: HomeViewState) {
        onStateChange?(state)
    }

    @MainActor
    private func publish(error: Error) {
        onError?(error)
    }
}
