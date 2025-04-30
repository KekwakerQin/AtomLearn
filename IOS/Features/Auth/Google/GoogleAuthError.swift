import Foundation

enum GoogleAuthError: LocalizedError {
    case missingClientID
    case missingRootViewController
    case missingIDToken
    case firebaseSignInFailed(Error)
    case unknown
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .missingClientID: return "Missing client ID"
        case .missingRootViewController: return "Missing root view controller"
        case .missingIDToken: return "Missing ID Token"
        case .firebaseSignInFailed(let error): return "Firebase auth error: \(error.localizedDescription)"
        case .unknown: return "Unknown error"
        case .timeout: return "Timeout"
        }
    }
}
