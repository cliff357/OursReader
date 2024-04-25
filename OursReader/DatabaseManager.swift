//
//  DatabaseManager.swift
//  OursReader
//
//  Created by Cliff Chan on 17/3/2024.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

// MARK: - Account management
extension DatabaseManager {
    public func insertUser(with user: User, completion: @escaping (Bool)-> Void) {
        let userDetail = [
            "email": user.safeEmail,
            "user_uid" : user.userUid,
            "name": user.name
        ] as [String : Any]
        self.database.child("users").setValue(userDetail, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard !snapshot.exists() else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    public func saveUserFcmToken(with user: User, token: String, completion: @escaping (Bool)-> Void) {
        let userDetail = [
            "fcm_token": token
        ] as [String : Any]
        self.database.child("users").child(user.safeEmail).setValue(userDetail, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
}
