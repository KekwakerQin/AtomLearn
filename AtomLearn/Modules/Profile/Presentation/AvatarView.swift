import UIKit

final class AvatarView: UIView {
    private let imageView = UIImageView()
    private let initialsLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        layer.cornerRadius = 36
        clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false

        initialsLabel.font = .systemFont(ofSize: 24, weight: .bold)
        initialsLabel.textColor = .systemBlue
        initialsLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageView)
        addSubview(initialsLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            initialsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func configure(name: String, image: UIImage?) {
        if let image {
            imageView.image = image
            initialsLabel.text = nil
            backgroundColor = .clear
        } else {
            imageView.image = nil
            initialsLabel.text = AvatarView.initials(from: name)
            backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        }
    }

    private static func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(1)).uppercased()
    }
}
