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
    
    //check user exist in firestore by userID
    func checkUserExist(userID: String, completion: @escaping (Bool) -> ()) {
        Firestore.firestore().collection(DatabaseManager.Key.user).document(userID).getDocument { (document, error) in
            if let err = error {
                print(err.localizedDescription)
                completion(false)
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
}

// MARK: - Friend Management
extension DatabaseManager {
    // Add friend to this user
    func addFriend(friend: UserObject, completion: @escaping (Result<Void, Error>) -> Void ) {
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
    
    // Get all friends of the current user
    func getFriendsList(completion: @escaping (Result<[UserObject], Error>) -> Void) {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            completion(.failure(NSError(domain: "No current user", code: 0, userInfo: nil)))
            return
        }
        
        let currentUserID = currentUser.uid
        
        // First get the current user document to get the connections_userID array
        db.collection(Key.user).document(currentUserID).getDocument { (document, error) in
            if let error = error {
                print("Error getting user document: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists else {
                completion(.failure(NSError(domain: "User document not found", code: 0, userInfo: nil)))
                return
            }
            
            // Extract the connections_userID array
            guard let connections = document.data()?[Key.connections_userID] as? [String], !connections.isEmpty else {
                // User has no friends
                completion(.success([]))
                return
            }
            
            // Fetch only the friend documents we need using their IDs
            let friendsRef = self.db.collection(Key.user).whereField(FieldPath.documentID(), in: connections)
            friendsRef.getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error getting friends documents: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                var friends: [UserObject] = []
                
                for document in snapshot?.documents ?? [] {
                    let data = document.data()
                    let friendID = document.documentID
                    let name = data[Key.name] as? String
                    let email = data[Key.email] as? String
                    
                    // Create a minimal UserObject with just the essential fields
                    let friend = UserObject(
                        name: name,
                        userID: friendID,
                        fcmToken: nil,  // Only fetch essential data
                        email: email,
                        login_type: nil,
                        connections_userID: nil
                    )
                    
                    friends.append(friend)
                }
                
                completion(.success(friends))
            }
        }
    }
    
    // Async version for modern Swift concurrency
    func getFriendsListAsync() async throws -> [UserObject] {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            throw NSError(domain: "No current user", code: 0, userInfo: nil)
        }
        
        let currentUserID = currentUser.uid
        
        // Get the current user document to retrieve connections_userID array
        let userDocSnapshot = try await db.collection(Key.user).document(currentUserID).getDocument()
        
        guard userDocSnapshot.exists else {
            throw NSError(domain: "User document not found", code: 0, userInfo: nil)
        }
        
        // Extract connections
        guard let connections = userDocSnapshot.data()?[Key.connections_userID] as? [String], !connections.isEmpty else {
            return []  // No friends
        }
        
        // Query friends documents
        let friendsSnapshot = try await db.collection(Key.user)
            .whereField(FieldPath.documentID(), in: connections)
            .getDocuments()
        
        // Process and return friends
        return friendsSnapshot.documents.compactMap { document in
            let data = document.data()
            let friendID = document.documentID
            let name = data[Key.name] as? String
            let email = data[Key.email] as? String
            
            return UserObject(
                name: name,
                userID: friendID,
                fcmToken: nil,
                email: email,
                login_type: nil,
                connections_userID: nil
            )
        }
    }
    
    // Remove a friend from the current user's friend list
    func removeFriend(friendID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            completion(.failure(NSError(domain: "No current user", code: 0, userInfo: nil)))
            return
        }
        
        let currentUserID = currentUser.uid
        
        // Update the connections array in a transaction for data consistency
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            // Get current user document
            let userDocRef = self.db.collection(DatabaseManager.Key.user).document(currentUserID)
            let userDoc: DocumentSnapshot
            do {
                userDoc = try transaction.getDocument(userDocRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            // Update current user's connections
            guard var connections = userDoc.data()?[DatabaseManager.Key.connections_userID] as? [String] else {
                return nil
            }
            connections.removeAll { $0 == friendID }
            transaction.updateData([DatabaseManager.Key.connections_userID: connections], forDocument: userDocRef)
            
            // Fix Swift 6 async warning - replace try? with explicit error handling
            let friendDocRef = self.db.collection(DatabaseManager.Key.user).document(friendID)
            
            // Instead of using try?, handle the document fetch without throwing
            do {
                let friendDoc = try transaction.getDocument(friendDocRef)
                if let friendConnections = friendDoc.data()?[DatabaseManager.Key.connections_userID] as? [String] {
                    var updatedFriendConnections = friendConnections
                    updatedFriendConnections.removeAll { $0 == currentUserID }
                    transaction.updateData([DatabaseManager.Key.connections_userID: updatedFriendConnections], 
                                           forDocument: friendDocRef)
                }
            } catch {
                // Just log the error but continue with the transaction since this is optional
                print("Could not fetch friend document: \(error.localizedDescription)")
                // We don't need to rethrow or fail - just continue
            }
            
            return nil
        }) { (_, error) in
            if let error = error {
                print("Transaction failed: \(error)")
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

// MARK: - Push Setting
extension DatabaseManager {
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
    
    func updatePushSetting(_ pushSetting: Push_Setting, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            completion(.failure(NSError(domain: "Invalid Current User", code: 0, userInfo: nil)))
            return
        }

        let currentUserID = currentUser.uid
        let settingData = pushSetting.toDictionary()

        let db = Firestore.firestore()
        let userDocRef = db.collection(Key.user).document(currentUserID)

        // Add or update a setting in the push_setting array
        userDocRef.getDocument { (document, error) in
            if let document = document, document.exists {
                var existingSettings = document.get("push_setting") as? [[String: Any]] ?? []
                
                // Check if the setting with the same ID already exists
                if let index = existingSettings.firstIndex(where: { $0["id"] as? String == pushSetting.id }) {
                    // Update the existing setting
                    existingSettings[index] = settingData
                } else {
                    // Add the new setting
                    existingSettings.append(settingData)
                }
                
                // Write the updated array back to Firestore
                userDocRef.updateData(["push_setting": existingSettings]) { error in
                    if let error = error {
                        print("Error updating push setting: \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            } else {
                print("Document does not exist or failed to fetch: \(error?.localizedDescription ?? "No error message")")
                completion(.failure(error ?? NSError(domain: "Document Fetch Error", code: 0, userInfo: nil)))
            }
        }
    }
}
