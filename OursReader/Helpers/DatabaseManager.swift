//
//  DatabaseManager.swift
//  OursReader
//
//  Created by Cliff Chan on 17/3/2024.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class DatabaseManager {
    static let shared = DatabaseManager()
    private let db = Firestore.firestore()
    
    //firebase key
    enum Key {
        static let user = "User"
        static let name = "name"
        static let fcmToken = "fcmToken"
        static let email = "email"
        static let login_type = "login_type"
        static let connections_userID = "connections_userID"
        static let push_setting = "push_setting"
        static let body = "body"
        static let title = "title"
    }
}

// MARK: - Account management
extension DatabaseManager {
    //MARK: User Data
    // add user into fireStore
    func addUser(user:UserObject, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userID = user.userID else {
            completion(.failure(NSError(domain: "Invalid UserID", code: 0, userInfo: nil)))
            return
        }
        
        let data: [String: Any] = [
            Key.name: user.name ?? "",
            Key.fcmToken: user.fcmToken ?? "",
            Key.email: user.email ?? "",
            Key.login_type: user.login_type?.rawValue ?? 0,
            Key.connections_userID: user.connections_userID ?? []
        ]
        
        db.collection(Key.user).document(userID).setData(data) { error in
            if let error = error {
                print("Error adding user: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("User added successfully")
                completion(.success(()))
            }
        }
    }
    
    // add friend to this user
    func addFriend(friend: UserObject, completion: @escaping (Result<Void, Error>) -> Void ) {
        //Update firestore user data by userid
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            completion(.failure(NSError(domain: "Invalid Current User", code: 0, userInfo: nil)))
            return
        }
        
        let currentUserID = currentUser.uid
        
        guard let friendID = friend.userID else {
            completion(.failure(NSError(domain: "Invalid Friend UserID", code: 0, userInfo: nil)))
            return
        }
        
        let userDocument = db.collection(Key.user).document(currentUserID)
        
        userDocument.updateData([
            Key.connections_userID: FieldValue.arrayUnion([friendID])
        ]) { error in
            if let error = error {
                print("Error adding friend: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("Friend added successfully")
                completion(.success(()))
            }
        }
        
    }
    
    // Update a user's data in Firestore
    func updateUser(user: UserObject, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userID = user.userID else {
            completion(.failure(NSError(domain: "Invalid UserID", code: 0, userInfo: nil)))
            return
        }
        
        let data: [String: Any] = [
            Key.name: user.name ?? "",
            Key.fcmToken: user.fcmToken ?? "",
            Key.email: user.email ?? "",
            Key.login_type: user.login_type?.rawValue ?? 0,
//            "connections_userID": user.connections_userID ?? []
        ]
        
        db.collection(Key.user).document(userID).updateData(data) { error in
            if let error = error {
                print("Error updating user: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("User updated successfully")
                completion(.success(()))
            }
        }
    }
    
    //check user exist in firestore
    func checkUserExist(email: String, completion: @escaping (Bool) -> ()) {
        Firestore.firestore().collection(DatabaseManager.Key.user).document(email).getDocument { (document, error) in
            if let err = error {
                print(err.localizedDescription)
            }
            else {
                if document?.exists == true {
                    completion(true)
                }
                else {
                    completion(false)
                }
            }
        }
    }
    
    func checkUserExist(userID: String, completion: @escaping (Bool) -> ()) {
        Firestore.firestore().collection(DatabaseManager.Key.user).document(userID).getDocument { (document, error) in
            if let err = error {
                print(err.localizedDescription)
            }
            else {
                if document?.exists == true {
                    completion(true)
                }
                else {
                    completion(false)
                }
            }
        }
    }
    
    func getAllFriendsToken(completion: @escaping (Result<[String], Error>) -> () ) {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            completion(.failure(NSError(domain: "Invalid Current User", code: 0, userInfo: nil)))
            return
        }
        
        let currentUserID = currentUser.uid
        
        
        //get all token from firebase
        db.collection(Key.user).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                
                var tokens:[String] = []
                
                let document = snapshot?.documents.first(where: { $0.documentID == currentUserID })
                
                if let connections_userID = document?.data()[Key.connections_userID] as? [String] {
                    for userID in connections_userID {
                        let friendDocument = snapshot?.documents.first(where: { $0.documentID == userID })
                        if let token = friendDocument?.data()["fcmToken"] as? String {
                            tokens.append(token)
                        }
                    }
                }
                
                completion(.success(tokens))
            }
        }
    }
    
    //MARK: Push Setting
    // Get user push setting in Firestore
    func getUserPushSetting(completion: @escaping (Result<[Push_Setting], Error>) -> () ) {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            completion(.failure(NSError(domain: "Invalid Current User", code: 0, userInfo: nil)))
            return
        }
        
        let currentUserID = currentUser.uid
        
        
        //get all token from firebase
        db.collection(Key.user).document(currentUserID).getDocument { (document, error) in
            if let error = error {
                print("Error getting document: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = document?.data(),
                  let settingsArray = data[Key.push_setting] as? [[String: Any]] else {
                print("No push settings found.")
                completion(.success([]))
                return
            }
            
            let pushSettings = settingsArray.compactMap { dict -> Push_Setting? in
                guard let id = dict["id"] as? String,
                      let title = dict["title"] as? String,
                      let body = dict["body"] as? String else { return nil }
                return Push_Setting(id: id, title: title, body: body)
            }
            
            completion(.success(pushSettings))
        }

    }
    
    func addPushSetting(_ pushSetting: Push_Setting, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            completion(.failure(NSError(domain: "Invalid Current User", code: 0, userInfo: nil)))
            return
        }
        
        let currentUserID = currentUser.uid
        
        db.collection(Key.user).document(currentUserID).updateData([
            Key.push_setting: FieldValue.arrayUnion([pushSetting.toDictionary()])
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func deletePushSetting(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            completion(.failure(NSError(domain: "Invalid Current User", code: 0, userInfo: nil)))
            return
        }
        
        let currentUserID = currentUser.uid
        
        db.collection(Key.user).document(currentUserID).getDocument { documentSnapshot, error in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let document = documentSnapshot, document.exists else {
                completion(.failure(NSError(domain: "User document does not exist", code: 0, userInfo: nil)))
                return
            }
            
            if var settingsArray = document.data()?[Key.push_setting] as? [[String: Any]] {
                if let index = settingsArray.firstIndex(where: {
                    let settingDict = $0
                    return settingDict["id"] as? String == id
                }) {
                    settingsArray.remove(at: index)
                    
                    self.db.collection(Key.user).document(currentUserID).updateData([
                        Key.push_setting: settingsArray
                    ]) { error in
                        if let error = error {
                            print("Error deleting push setting: \(error.localizedDescription)")
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                } else {
                    completion(.failure(NSError(domain: "Push setting not found", code: 0, userInfo: nil)))
                }
            } else {
                completion(.failure(NSError(domain: "No push settings available", code: 0, userInfo: nil)))
            }
        }
    }
}
