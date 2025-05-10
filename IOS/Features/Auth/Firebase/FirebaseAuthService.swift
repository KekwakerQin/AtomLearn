import Firebase
import FirebaseAuth
import GoogleSignIn
import RxSwift
import AuthenticationServices
import CryptoKit // для nonce
import RxSwift

final class FirebaseAuthService: AuthServiceProtocol {
    
    private let googleAuthHandler = GoogleAuthHandler()
//    private let appleAuthHandler = AppleAuthHandler()

//    func signInWithApple(from viewController: UIViewController) -> Single<AppUser> {
//        appleAuthHandler.signIn(from: viewController)
//    }
    
    func signInWithGoogle(from viewController: UIViewController) -> Single<AppUser> {
        googleAuthHandler.signIn(from: viewController)
    }
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    var isAuthorized: Bool {
        currentUserID != nil
    }
    
    func signOut() {
        try? Auth.auth().signOut()
    }
}
