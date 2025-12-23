// Домашний экран: тест интеграции Supabase
import UIKit
import Supabase

final class HomeViewController: UIViewController {
    // MARK: - Dependencies
    private let viewModel: HomeViewModel

    // MARK: - UI

    // Превью изображения (результат загрузки)
    private let imageView = UIImageView()
    // Статус/лог загрузки
    private let status = UILabel()

    // MARK: - Init
    /// Создаёт домашний экран.
    init(viewModel: HomeViewModel = HomeViewModel(service: HomeRepository())) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.onViewDidLoad()
        testSupabase()
    }

    // MARK: - UI
    // Настройка интерфейса
    private func setupUI() {
        view.backgroundColor = .systemBackground
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true

        status.text = "Тест Supabase…"
        status.numberOfLines = 0
        status.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [status, imageView])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 16

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            imageView.heightAnchor.constraint(equalToConstant: 160)
        ])
    }

    // MARK: - Networking
    // Тест: листинг папки и загрузка первого файла
    private func testSupabase() {
        let client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        )
        let bucket = SupabaseConfig.bucket
        let folder = "badges/badge_icons" // Папка в бакете (без завершающего /)

        Task { @MainActor in
            // 1) Листинг папки и показ первого файла
            do {
                let files = try await client.storage
                    .from(bucket)
                    .list(path: folder, options: .init(limit: 1000))

                // отсортируем по имени и возьмём первый
                for f in files  {
                    print(f.name)
                }
                print("Done")
                let sorted = files.sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }

                if let first = sorted.first {
                    let firstPath = "\(folder)/\(first.name)"   // собрали полный путь
                    // публичный или подписанный URL
                    if let publicURL = try? client.storage.from(bucket).getPublicURL(path: firstPath) {
                        await self.downloadAndShow(from: publicURL, labelPrefix: "first-from-list")
                    } else {
                        let signedURL = try await client.storage
                            .from(bucket)
                            .createSignedURL(path: firstPath, expiresIn: 600)
                        await self.downloadAndShow(from: signedURL, labelPrefix: "first-from-list-signed")
                    }
                } else {
                    status.text = "В папке нет файлов"
                }

                // если нужен список всех URL (необязательно для UI)
                var results: [(name: String, url: URL)] = []
                for f in files {
                    let fullPath = "\(folder)/\(f.name)"
                    if let u = try? client.storage.from(bucket).getPublicURL(path: fullPath) {
                        results.append((f.name, u))
                    } else {
                        let u = try await client.storage.from(bucket).createSignedURL(path: fullPath, expiresIn: 600)
                        results.append((f.name, u))
                    }
                }
                print("[LOG:INFO] Найдено файлов: \(results.count)")
                results.forEach { print("- \($0.name) → \($0.url)") }
                status.text = (status.text ?? "") + "\nФайлов: \(results.count)"
            } catch {
                print("[LOG:ERROR] LIST error: \(error.localizedDescription)")
                status.text = "LIST error: \(error.localizedDescription)"
            }

            // 2) (опционально) Тест фиксированного файла knownPath
            let knownPath = SupabaseConfig.knownPath
            do {
                let publicURL = try client.storage.from(bucket).getPublicURL(path: knownPath)
                await self.downloadAndShow(from: publicURL, labelPrefix: "public")
            } catch {
                // если бакет приватный — подпишем
                do {
                    let signedURL = try await client.storage
                        .from(bucket)
                        .createSignedURL(path: knownPath, expiresIn: 600)
                    await self.downloadAndShow(from: signedURL, labelPrefix: "signed")
                } catch {
                    print("[LOG:WARN] knownPath error: \(error.localizedDescription)")
                    status.text = (status.text ?? "") + "\nknownPath error: \(error.localizedDescription)"
                }
            }
        }
    }

    // Загрузка картинки и показ в imageView
    private func downloadAndShow(from url: URL, labelPrefix: String) async {
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            if let http = resp as? HTTPURLResponse {
                print("\(labelPrefix) GET status:", http.statusCode)
            }
            guard let img = UIImage(data: data) else {
                status.text = (status.text ?? "") + "\n\(labelPrefix): не картинка"
                return
            }
            imageView.image = img
            status.text = (status.text ?? "") + "\n\(labelPrefix): ок (\(url.lastPathComponent))"
            print("[LOG:INFO] \(labelPrefix) image loaded: \(url.lastPathComponent)")
        } catch {
            print("[LOG:ERROR] \(labelPrefix) download error: \(error.localizedDescription)")
            status.text = (status.text ?? "") + "\n\(labelPrefix) download error: \(error.localizedDescription)"
        }
    }
}
