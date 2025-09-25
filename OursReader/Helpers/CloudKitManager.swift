import Foundation
import CloudKit
import UIKit

class CloudKitManager {
    static let shared = CloudKitManager()
    
    // CloudKit container identifier
    private let containerIdentifier = "iCloud.com.cliffchan.manwareader"
    
    // CloudKit databases
    private lazy var container: CKContainer = {
        return CKContainer(identifier: containerIdentifier)
    }()
    
    private lazy var publicDatabase: CKDatabase = {
        return container.publicCloudDatabase
    }()
    
    private lazy var privateDatabase: CKDatabase = {
        return container.privateCloudDatabase
    }()
    
    // Check if the user is signed into iCloud
    func checkUserStatus(completion: @escaping (Result<CKUserIdentity?, Error>) -> Void) {
        container.fetchUserRecordID { userRecordID, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Get user identity for display
            if let userRecordID = userRecordID {
                self.container.discoverUserIdentity(withUserRecordID: userRecordID) { userIdentity, error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(userIdentity))
                    }
                }
            } else {
                completion(.success(nil))
            }
        }
    }
    
    // Helper method to link a Firebase user ID with the CloudKit user
    // This simply stores the Firebase ID in a user record for reference
    func linkFirebaseUser(firebaseUserID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        container.fetchUserRecordID { userRecordID, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let userRecordID = userRecordID else {
                completion(.failure(NSError(domain: "com.cliffchan.manwareader", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user record ID"])))
                return
            }
            
            // Create a record to store the Firebase user ID
            let userRecord = CKRecord(recordType: "UserLink", recordID: CKRecord.ID(recordName: "UserLink-\(userRecordID.recordName)"))
            userRecord["firebaseUserID"] = firebaseUserID
            userRecord["cloudKitUserID"] = userRecordID.recordName
            
            self.privateDatabase.save(userRecord) { _, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
}
