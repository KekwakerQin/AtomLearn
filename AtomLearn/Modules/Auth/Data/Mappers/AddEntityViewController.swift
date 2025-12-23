import UIKit

final class AddEntityViewController: UIViewController {

    private let service: BoardsService
    private let onCreated: (() -> Void)?

    init(
        service: BoardsService,
        onCreated: (() -> Void)? = nil
    ) {
        self.service = service
        self.onCreated = onCreated
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Новый борд"
    }

    // Пример: нажали кнопку "Создать"
    private func didTapCreate() {
        // здесь позже будет service.createBoard(...)
        onCreated?()
        dismiss(animated: true)
    }
}
