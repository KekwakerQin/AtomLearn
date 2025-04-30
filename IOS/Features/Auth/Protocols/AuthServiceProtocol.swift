import FirebaseAuth
import UIKit
import RxSwift

protocol AuthServiceProtocol {
    func signInWithGoogle(from viewController: UIViewController) -> Single<AppUser>
//    func signInWithApple(fr om viewController: UIViewController) -> Single<AppUser>
    
    var currentUserID: String? { get }
    var isAuthorized: Bool { get }
    func signOut()
}
