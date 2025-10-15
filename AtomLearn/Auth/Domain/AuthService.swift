import FirebaseAuth

final class AuthService {
    static func isUserLoggedIn() -> Bool {
        return FirebaseAuth.Auth.auth().currentUser != nil
    }
    
    
}
