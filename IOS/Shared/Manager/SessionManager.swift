import FirebaseAuth
import RxSwift

final class SessionManager {
    static let shared = SessionManager()
    private init() {}

    var currentUser: AppUser?
    
    func bootstrapSessionIfNeeded() -> Completable {
        guard let user = Auth.auth().currentUser else {
            return .empty() // просто завершение, если пользователя нет
        }
        
        return FirestoreUserService().fetchUser(uid: user.uid)
            .do(onSuccess: { [weak self] appUser in
                self?.currentUser = appUser
            })
            .asCompletable()
    }
}
