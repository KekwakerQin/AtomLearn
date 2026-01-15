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

        navigationController?.interactivePopGestureRecognizer?.delegate = self

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Добавить",
            style: .done,
            target: self,
            action: #selector(addTapped)
        )
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("viewDidDisappear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("viewWillDisappear")
    }
    
    @objc private func addTapped() {
        viewModel.addCard()
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        navigationController?.popViewController(animated: true)
        viewModel.cancel()
    }
}

extension AddCardsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
