import UIKit
import Supabase

// Экран со списком бейджей
final class BadgesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    // MARK: - Properties
    private var items: [Badge] = []           // Данные для коллекции
    private let repo = BadgeRepository()      // Репозиторий бейджей (Firestore)

    // Клиент Supabase
    private lazy var supabaseClient = SupabaseClient(
        supabaseURL: SupabaseConfig.url,
        supabaseKey: SupabaseConfig.anonKey
    )

    // Провайдер изображений (Supabase Storage)
    private lazy var images = SupabaseImages(
        client: supabaseClient,
        bucket: SupabaseConfig.bucket,
        baseURL: SupabaseConfig.url
    )

    // Коллекция с компоновкой 3 в ряд
    private lazy var collection: UICollectionView = {
        let layout = BadgesViewController.makeLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.dataSource = self
        cv.delegate = self
        cv.register(BadgeGridCell.self, forCellWithReuseIdentifier: "cell")
        return cv
    }()

    // MARK: - Lifecycle
    // Настройка экрана и старт загрузки
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        view.addSubview(collection)
        collection.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collection.topAnchor.constraint(equalTo: view.topAnchor),
            collection.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collection.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collection.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        Task { await load() }
    }

    // Перезапуск шиммера при возврате
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Перезапускаем шимер на видимых ячейках при возврате на экран/вкладку
        for cell in collection.visibleCells {
            (cell as? BadgeGridCell)?.startShimmerIfNeeded()
        }
    }

    // MARK: - Data
    // Загружаем список бейджей из Firestore
    private func load() async {
        do {
            let badges = try await repo.fetchAll()
            self.items = badges
            await MainActor.run { self.collection.reloadData() }
        } catch {
            print("[LOG:WARN] Ошибка загрузки Firestore: \(error.localizedDescription)")
        }
    }

    // MARK: - UICollectionViewDataSource
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int { items.count }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! BadgeGridCell
        let badge = items[indexPath.item]
        cell.configure(title: badge.name)

        // Шимер включаем сразу
        cell.setImage(nil)

        // Загрузка: сначала thumbnail через CDN, иначе fallback на signed
        Task {
            // Ключ для кеша
            let cacheKey = badge.imagePath + "_88"
            if let cached = ImageCache.shared.object(forKey: cacheKey as NSString) {
                await MainActor.run {
                    if cv.indexPath(for: cell) == indexPath { cell.setImage(cached) }
                }
                return
            }

            // 1) попробовать миниатюру
            if let thumbURL = try? images.thumbnailURL(for: badge.imagePath, width: 128, quality: 70) {
                var req = URLRequest(url: thumbURL)
                req.cachePolicy = .returnCacheDataElseLoad
                if let (data, resp) = try? await URLSession.shared.data(for: req),
                   (resp as? HTTPURLResponse)?.statusCode == 200,
                   let img = UIImage(data: data) {
                    ImageCache.shared.setObject(img, forKey: cacheKey as NSString)
                    await MainActor.run {
                        if cv.indexPath(for: cell) == indexPath { cell.setImage(img) }
                    }
                    return
                }
            }

            // 2) fallback: signed original
            do {
                let origURL = try await images.originalURL(for: badge.imagePath)
                var req = URLRequest(url: origURL)
                req.cachePolicy = .returnCacheDataElseLoad
                let (data, resp) = try await URLSession.shared.data(for: req)
                if (resp as? HTTPURLResponse)?.statusCode == 200, let img = UIImage(data: data) {
                    ImageCache.shared.setObject(img, forKey: cacheKey as NSString)
                    await MainActor.run {
                        if cv.indexPath(for: cell) == indexPath { cell.setImage(img) }
                    }
                } else {
                    await MainActor.run {
                        if cv.indexPath(for: cell) == indexPath { cell.setImage(nil) }
                    }
                }
            } catch {
                await MainActor.run {
                    if cv.indexPath(for: cell) == indexPath { cell.setImage(nil) }
                }
                print("[LOG:WARN] Ошибка загрузки изображения: \(error.localizedDescription)")
            }
        }

        return cell
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let badge = items[indexPath.item]
        let vc = BadgeSheetViewController(badge: badge, images: images)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.largestUndimmedDetentIdentifier = .medium
        }
        present(vc, animated: true)
    }

    // MARK: - Layout
    // 3 колонки
    static func makeLayout() -> UICollectionViewCompositionalLayout {
        let spacing: CGFloat = 12

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupHeight: CGFloat = 140 // картинка + подпись
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(groupHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)
        group.interItemSpacing = .fixed(spacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)

        return UICollectionViewCompositionalLayout(section: section)
    }
}

// Ячейка грида бейджа
final class BadgeGridCell: UICollectionViewCell {
    // MARK: - Subviews
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let shimmer = ShimmerView()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08      // мягкая
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.masksToBounds = false

        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .systemGray5

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .clear

        titleLabel.font = .preferredFont(forTextStyle: .footnote)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        let v = UIStackView(arrangedSubviews: [imageView, titleLabel])
        v.axis = .vertical
        v.spacing = 8
        v.alignment = .fill

        contentView.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            v.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            v.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            v.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])

        // Shimmer поверх imageView
        shimmer.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(shimmer)
        NSLayoutConstraint.activate([
            shimmer.topAnchor.constraint(equalTo: imageView.topAnchor),
            shimmer.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            shimmer.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            shimmer.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
        ])
        shimmer.isHidden = true
    }
    
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        startShimmerIfNeeded()
    }

    // MARK: - API
    func configure(title: String) {
        titleLabel.text = title
    }

    func setImage(_ img: UIImage?) {
        imageView.image = img
        if img != nil { shimmer.stop() } else { shimmer.start() }
    }

    func startShimmerIfNeeded() {
        if imageView.image == nil { shimmer.start() }
    }
}

final class ImageCache {
    static let shared = NSCache<NSString, UIImage>()
}
