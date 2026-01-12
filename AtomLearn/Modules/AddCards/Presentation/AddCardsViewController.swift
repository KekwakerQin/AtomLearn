import UIKit

final class AddCardsViewController: UIViewController {
    
    // MARK: - Dependencies
    private let viewModel: AddCardsViewModel
    
    // MARK: - Init
    init(viewModel: AddCardsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        print("DEINIT \(self)")
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        viewModel.onViewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Отмена",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Добавить",
            style: .done,
            target: self,
            action: #selector(addTapped)
        )
    }

    @objc private func addTapped() {
        viewModel.addCard()
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        viewModel.cancel()
    }
}
