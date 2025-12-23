import Foundation

// Менеджер для сетевых запросов - отвечает за работу с API
final class NetworkManager {
    static let shared = NetworkManager() // Синглтон
    private init() {}
    
    // Получить профиль пользователя с сервера (пример)
    @discardableResult
    func fetchUserProfile(completion: @escaping (Result<AppUser, Error>) -> Void) -> URLSessionDataTask? {
        // Проверяем корректность URL
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/users/1") else {
            completion(.failure(NSError(domain: "BadURL", code: -1, userInfo: nil)))
            return nil
        }
        
        // Запускаем запрос к серверу
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error {
                // Ошибка сети
                completion(.failure(error))
                return
            }
            
            // Проверяем статус код
            guard let httpResp = response as? HTTPURLResponse, (200..<300).contains(httpResp.statusCode) else {
                completion(.failure(NSError(domain: "HTTP", code: -2, userInfo: [NSLocalizedDescriptionKey: "Bad status code"])))
                return
            }
            
            // Проверяем наличие данных
            guard let data else {
                completion(.failure(NSError(domain: "Network", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty response"])))
                return
            }
            
            // Декодируем ответ в модель AppUser
            Task { @MainActor in
                do {
                    let profile = try JSONDecoder().decode(AppUser.self, from: data)
                    completion(.success(profile))
                } catch {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
        return task
    }
}
