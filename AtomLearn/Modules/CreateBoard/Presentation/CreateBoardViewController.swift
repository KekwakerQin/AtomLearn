import UIKit

final class CreateBoardViewController: UIViewController {

    // MARK: - Dependencies
    private let viewModel: CreateBoardViewModel

    // MARK: - Init
    init(viewModel: CreateBoardViewModel) {
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
        title = "Новая доска"
        viewModel.onViewDidLoad()
    }
}
