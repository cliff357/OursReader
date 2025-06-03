import Foundation
import WatchConnectivity

class AuthManager: NSObject, WCSessionDelegate {
    static let shared = AuthManager()
    
    private var session: WCSession = .default
    private let tokenKey = "firebaseAuthToken"
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Token Management
    
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let token = message["authToken"] as? String {
            saveToken(token)
            print("Received and saved auth token from iPhone")
        }
    }
}
