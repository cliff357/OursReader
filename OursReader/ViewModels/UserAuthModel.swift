//
//  UserAuthModel.swift
//  OursReader
//
//  Created by Cliff Chan on 18/3/2024.
//

import SwiftUI

import GoogleSignIn
import FirebaseCore
import FirebaseAuth
import CryptoKit
import AuthenticationServices
import FirebaseMessaging

enum AuthenticationState {
  case unauthenticated
  case authenticating
  case authenticated
}

enum AuthenticationFlow {
  case login
  case signUp
}

class UserAuthModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    static let shared: UserAuthModel = .init()
    
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String = ""
    
    @Published var nickName: String = ""
    @Published var userData: UserObject?
    
    // Unhashed nonce.
    var currentNonce: String?
    
    
    override init() {
        super.init()
        
        Storage.save(Storage.Key.userLoginType, UserType.email.rawValue)
        self.check()
    }
    
    func check() {
        if let name = Storage.getString(Storage.Key.nickName) {
            self.nickName = name
        }
        
        var token = ""
        if let t = Storage.getString(Storage.Key.pushToken) {
            token = t
        }
        
        var loginType: UserType?
        if let t = Storage.getInt(Storage.Key.userLoginType) {
            loginType = UserType.init(rawValue: t)
        }
        
        Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                self.isLoggedIn = true
                self.userData = UserObject(name: self.nickName, userID: user.uid, fcmToken: token, email: user.email, login_type: loginType)

                Storage.save(Storage.Key.userName, user.displayName ?? "")
                Storage.save(Storage.Key.userEmail, user.email ?? "")
                
                //TODO: get user imageurl
//                guard let uhk.rl = user.photoURL else { return }
                //self.profilePicUrl =  //user.photoURL?.imageURL(withDimension: 100)!.absoluteString
            } else {
                self.isLoggedIn = false
                let router = HomeRouter.shared
                Storage.removeAllUserDefaultsObject()
                
                // do nothing if user is in signup page
                // because signup error will check this state
                if router.path.last == .signup {
                    return
                }
                
                router.reset()
            }
        }
        
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                self.errorMessage = "error: \(error.localizedDescription)"
            }
            
        }
    }
    
    func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    func getCurrentFirebaseUser() -> User? {
        if let user = Auth.auth().currentUser {
            return user
        }
        
        return nil
    }
    //MARK: Google Sign in
    func signInByGoogle() {
        
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {return}
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [unowned self] result, error in
            if let error = error {
                self.errorMessage = "error: \(error.localizedDescription)"
            }
            
            guard let user = result?.user, let idToken = user.idToken?.tokenString else {return }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { result, error in
                if (error != nil) {
                    // Error. If error.code == .MissingOrInvalidNonce, make sure
                    // you're sending the SHA256-hashed nonce as a hex string with
                    // your request to Apple.
                    print(error?.localizedDescription)
                    return
                }
                
                let user = result?.user
                
                var token = ""
                if let t = Messaging.messaging().fcmToken {
                    token = t
                }
                
                DatabaseManager.shared.checkUserExist(email: user?.uid ?? "") { result in
                    if result {
                        print("user already exist")
                    } else {
                        Storage.save(Storage.Key.userLoginType, UserType.google.rawValue)
                        
                        DatabaseManager.shared.addUser(user:  UserObject(name: self.nickName,
                                                                         userID: user?.uid,
                                                                         fcmToken: token ,
                                                                         email: user?.email,
                                                                         login_type: .google)) { result in
                            switch result {
                            case .success:
                                print("user added successfully")
                            case .failure(let error):
                                print("error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    //MARK: Apple Sign in
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // Single-sign-on with Apple
    @available(iOS 13, *)
    func startSignInWithAppleFlow() {
        
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if (error != nil) {
                    // Error. If error.code == .MissingOrInvalidNonce, make sure
                    // you're sending the SHA256-hashed nonce as a hex string with
                    // your request to Apple.
                    print(error?.localizedDescription)
                    return
                }
                
                let user = authResult?.user
                
                var token = ""
                if let t = Messaging.messaging().fcmToken {
                    token = t
                }
                
                DatabaseManager.shared.checkUserExist(email: user?.uid ?? "") { result in
                    if result {
                        print("user already exist")
                    } else {
                        Storage.save(Storage.Key.userLoginType, UserType.apple.rawValue)
                        
                        DatabaseManager.shared.addUser(user:  UserObject(name: self.nickName,
                                                                         userID: user?.uid,
                                                                         fcmToken: token,
                                                                         email: user?.email,
                                                                         login_type: .apple)) { result in
                            switch result {
                            case .success:
                                print("user added successfully")
                            case .failure(let error):
                                print("error: \(error.localizedDescription)")
                            }
                        }
                        
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
    }
    
    //MARK: Create user in firebase
    func createUser(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print(error.localizedDescription)
                completion("create user failed: \(error.localizedDescription)") // Pass nil to indicate failure
            } else {
                guard let user = result?.user else {
                    completion(nil)
                    return
                }
                
                var token = ""
                if let t = Messaging.messaging().fcmToken {
                    token = t
                }
                
                Storage.save(Storage.Key.userLoginType, UserType.email.rawValue)
                
                DatabaseManager.shared.addUser(user:  UserObject(name: self.nickName,
                                                                 userID: user.uid,
                                                                 fcmToken: token,
                                                                 email: email,
                                                                 login_type: .email)) { result in
                    switch result {
                    case .success:
                        print("user added successfully")
                    case .failure(let error):
                        print("error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    //MARK: Login with firebase
    func loginUser(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                // 登入失敗，回傳錯誤訊息
                completion(error.localizedDescription)
            } else {
                // 登入成功，回傳成功訊息
                completion("Login success")
                
                
            }
        }
    }
}
