//import Foundation
//import AuthenticationServices
//import CryptoKit
//import FirebaseAuth
//import RxSwift
//import UIKit
//
//final class AppleAuthHandler: NSObject {
//    
//    private var singleCallback: ((SingleEvent<AppUser>) -> Void)?
//    private var currentNonce: String?
//
//    func signIn(from viewController: UIViewController) -> Single<AppUser> {
//        return Single.create { [weak self] single in
//            guard let self else { return Disposables.create() }
//            
//            let nonce = Self.randomNonceString()
//            self.currentNonce = nonce
//            
//            let request = ASAuthorizationAppleIDProvider().createRequest()
//            request.requestedScopes = [.fullName, .email]
//            request.nonce = Self.sha256(nonce)
//            
//            let controller = ASAuthorizationController(authorizationRequests: [request])
//            controller.delegate = self
//            controller.presentationContextProvider = self
//            
//            self.singleCallback = single
//            
//            controller.performRequests()
//            
//            return Disposables.create()
//        }
//    }
//}
//
//// MARK: - ASAuthorizationControllerDelegate
//
//extension AppleAuthHandler: ASAuthorizationControllerDelegate {
//    
//    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
//        guard
//            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
//            let idTokenData = appleIDCredential.identityToken,
//            let idTokenString = String(data: idTokenData, encoding: .utf8),
//            let nonce = currentNonce
//        else {
//            singleCallback?(.failure(
//                NSError(domain: "AppleAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing credentials"])
//            ))
//            return
//        }
//
//        let credential = OAuthProvider.credential(
//            withProviderID: "apple.com",
//            idToken: idTokenString,
//            rawNonce: nonce
//        )
//        
//        Auth.auth().signIn(with: credential) { result, error in
//            if let error = error {
//                self.singleCallback?(.failure(error))
//                return
//            }
//
//            guard let user = result?.user else {
//                self.singleCallback?(.failure(
//                    NSError(domain: "AppleAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
//                ))
//                return
//            }
//
//            FirestoreUserService().createUserIfNeeded(from: user)
//                .subscribe(onSuccess: { appUser in
//                    SessionManager.shared.currentUser = appUser
//                    self.singleCallback?(.success(appUser))
//                }, onFailure: { error in
//                    self.singleCallback?(.failure(error))
//                })
//                .disposed(by: DisposeBag())
//        }
//    }
//    
//    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
//        singleCallback?(.failure(error))
//    }
//}
//
//// MARK: - Presentation Context
//
//extension AppleAuthHandler: ASAuthorizationControllerPresentationContextProviding {
//    
//    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
//        UIApplication.shared.windows.first { $0.isKeyWindow }!
//    }
//}
//
//// MARK: - Nonce Utils
//
//extension AppleAuthHandler {
//    
//    static func randomNonceString(length: Int = 32) -> String {
//        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
//        var result = ""
//        var remainingLength = length
//
//        while remainingLength > 0 {
//            let randoms: [UInt8] = (0..<16).map { _ in
//                var random: UInt8 = 0
//                let error = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
//                if error == errSecSuccess {
//                    return random
//                } else {
//                    fatalError("Failed to generate secure random nonce.")
//                }
//            }
//
//            randoms.forEach { random in
//                if remainingLength == 0 { return }
//                if random < charset.count {
//                    result.append(charset[Int(random)])
//                    remainingLength -= 1
//                }
//            }
//        }
//
//        return result
//    }
//
//    static func sha256(_ input: String) -> String {
//        let data = Data(input.utf8)
//        let hashed = SHA256.hash(data: data)
//        return hashed.compactMap { String(format: "%02x", $0) }.joined()
//    }
//}
