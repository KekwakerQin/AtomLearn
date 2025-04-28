import FirebaseAuth
import RxSwift

protocol UserServiceProtocol {
    func createUserIfNeeded(from firebaseUser: FirebaseAuth.User) -> Single<AppUser>
}
