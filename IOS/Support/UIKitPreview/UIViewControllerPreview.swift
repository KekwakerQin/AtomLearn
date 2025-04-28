#if DEBUG
import SwiftUI
import UIKit

struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    
    let viewControllerBuilder: () -> ViewController
    
    init(_ builder: @escaping () -> ViewController) {
        self.viewControllerBuilder = builder
    }
    
    func makeUIViewController(context: Context) -> ViewController {
        viewControllerBuilder()
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}
#endif
