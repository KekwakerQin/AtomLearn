import UIKit

final class AddCardsCoordinator {

    // MARK: - Dependencies
    private let navigationController: UINavigationController
    private let board: Board
    private let user: AppUser

    // MARK: - Init
    init(
        navigationController: UINavigationController,
        board: Board,
        user: AppUser
    ) {
        self.navigationController = navigationController
        self.board = board
        self.user = user
    }

    // MARK: - Output
    var onCancel: (() -> Void)?
    var onFinish: (() -> Void)?

    // MARK: - Public API
    func start() {
        let viewModel = AddCardsViewModel(
            boardId: board.id,
            user: user
        )

        viewModel.onFinish = { [weak self] in
            self?.onFinish?()
        }

        viewModel.onCancel = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }

        // Simple placeholders for the three tabs
        func makePlaceholder(title: String, systemImage: String) -> UIViewController {
            let vc = UIViewController()
            vc.view.backgroundColor = .systemBackground

            let imageView = UIImageView(image: UIImage(systemName: systemImage))
            imageView.tintColor = .secondaryLabel
            imageView.translatesAutoresizingMaskIntoConstraints = false

            let label = UILabel()
            label.text = title
            label.textColor = .label
            label.font = .systemFont(ofSize: 20, weight: .semibold)
            label.translatesAutoresizingMaskIntoConstraints = false

            let stack = UIStackView(arrangedSubviews: [imageView, label])
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 12
            stack.translatesAutoresizingMaskIntoConstraints = false

            vc.view.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
                stack.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor)
            ])

            return vc
        }

        let vc = AddCardsViewController(
            viewModel: viewModel,
            makeManualVC: { makePlaceholder(title: "Добавить вручную", systemImage: "square.and.pencil") },
            makeAIVC: { makePlaceholder(title: "Добавить с AI", systemImage: "sparkles") },
            makeImportVC: { makePlaceholder(title: "Импорт из документа/сайта", systemImage: "doc.text.magnifyingglass") }
        )

        navigationController.pushViewController(vc, animated: true)
    }
}
