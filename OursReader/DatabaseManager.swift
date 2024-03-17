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
            "first_name": user.firstName,
            "last_name": user.lastName
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
}
