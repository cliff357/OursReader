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
    }
}

// MARK: - Account management
extension DatabaseManager {
    
    // add user into fireStore
    func addUser(user:UserObject, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userID = user.userID else {
            completion(.failure(NSError(domain: "Invalid UserID", code: 0, userInfo: nil)))
            return
        }
        
        let data: [String: Any] = [
            "name": user.name ?? "",
            "fcmToken": user.fcmToken ?? "",
            "email": user.email ?? "",
            "login_type": user.login_type?.rawValue ?? 0,
            "friends": user.connections_userID ?? []
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
            "connections_userID": FieldValue.arrayUnion([friendID])
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
            "name": user.name ?? "",
            "fcmToken": user.fcmToken ?? "",
            "email": user.email ?? "",
            "login_type": user.login_type?.rawValue ?? 0,
            "connections_userID": user.connections_userID ?? [] 
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
    
}
