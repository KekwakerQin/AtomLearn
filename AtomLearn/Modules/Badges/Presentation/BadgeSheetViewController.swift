import UIKit

// Экран с информацией о бейдже (лист)
final class BadgeSheetViewController: UIViewController {
    // Бейдж для показа
    private let badge: Badge
    // Провайдер изображений (Supabase)
    private let images: SupabaseImages

    // Картинка бейджа
    private let imageView = UIImageView()
    // Заголовок
    private let titleLabel = UILabel()
    // Описание
    private let descLabel = UILabel()
    // Шиммер-заглушка на время загрузки
    private let shimmer = ShimmerView()

    // Внедряем зависимости
    init(badge: Badge, images: SupabaseImages) {
        self.badge = badge
        self.images = images
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // Настройка UI и запуск загрузки
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.heightAnchor.constraint(equalToConstant: 180).isActive = true

        titleLabel.text = badge.name
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textAlignment = .center
        descLabel.font = .preferredFont(forTextStyle: .body)
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel, descLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -20)
        ])

        // Шиммер поверх большой картинки
        shimmer.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(shimmer)
        NSLayoutConstraint.activate([
            shimmer.topAnchor.constraint(equalTo: imageView.topAnchor),
            shimmer.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            shimmer.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            shimmer.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
        ])

        // Загружаем картинку (сначала thumbnail, потом fallback)
        loadImage()
    }

    // Загрузка картинки: сначала thumbnail, затем оригинал (fallback)
    @MainActor private func loadImage() {
        shimmer.start()
        Task {
            // Thumbnail для листа (быстрее, легче)
            if let thumbURL = try? images.thumbnailURL(for: badge.imagePath, width: 512, quality: 80),
               let (data, resp) = try? await URLSession.shared.data(from: thumbURL),
               (resp as? HTTPURLResponse)?.statusCode == 200,
               let img = UIImage(data: data) {
                self.imageView.image = img
                self.shimmer.stop()
                return
            }
            // Fallback: оригинальное изображение
            if let origURL = try? await images.originalURL(for: badge.imagePath),
               let (data, resp) = try? await URLSession.shared.data(from: origURL),
               (resp as? HTTPURLResponse)?.statusCode == 200,
               let img = UIImage(data: data) {
                self.imageView.image = img
                self.shimmer.stop()
            } else {
                // Лог для отладки
                print("[LOG:WARN] BadgeSheet: failed to load image for path: \(badge.imagePath)")
                self.shimmer.stop()
            }
        }
    }
}
