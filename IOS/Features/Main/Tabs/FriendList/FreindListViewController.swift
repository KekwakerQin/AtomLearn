import UIKit

class FreindListViewController: UIViewController {
    
    var buttonOfBoardList = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        view = UIView.setupView(view: view)
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            
        ])
    }
}
