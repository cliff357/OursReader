import Foundation
import CloudKit
import UIKit

class CloudKitManager {
    static let shared = CloudKitManager()
    
    // 通知名稱
    static let booksDidChangeNotification = NSNotification.Name("BooksDidChangeNotification")
    
    private init() {
        // Initialize mock data when manager is created
        DispatchQueue.main.async {
            DataAPIManager.shared.initializeMockData()
        }
    }
    
    // MARK: - Book Operations (使用 DataAPIManager)
    
    func fetchPublicBooks(completion: @escaping (Result<[CloudBook], Error>) -> Void) {
    }
    
    func fetchPrivateBooks(completion: @escaping (Result<[CloudBook], Error>) -> Void) {
        DataAPIManager.shared.fetchPrivateBooks(completion: completion)
    }
    
    func fetchUserBookshelf(firebaseUserID: String, completion: @escaping (Result<[UserBook], Error>) -> Void) {
        DataAPIManager.shared.fetchUserBookshelf(firebaseUserID: firebaseUserID, completion: completion)
    }
    
    func addBookToUserBookshelf(_ bookID: String, firebaseUserID: String, completion: @escaping (Result<UserBook, Error>) -> Void) {
        DataAPIManager.shared.addBookToUserBookshelf(bookID, firebaseUserID: firebaseUserID, completion: completion)
    }
    
    func removeBookFromUserBookshelf(bookID: String, firebaseUserID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        DataAPIManager.shared.removeBookFromUserBookshelf(bookID: bookID, firebaseUserID: firebaseUserID, completion: completion)
    }
    
    func updateUserBookProgress(bookID: String, firebaseUserID: String, currentPage: Int, bookmarkedPages: [Int], completion: @escaping (Result<UserBook, Error>) -> Void) {
        DataAPIManager.shared.updateUserBookProgress(bookID: bookID, firebaseUserID: firebaseUserID, currentPage: currentPage, bookmarkedPages: bookmarkedPages, completion: completion)
    }
    
    func fetchReadingProgress(bookID: String, firebaseUserID: String, completion: @escaping (Result<(currentPage: Int, bookmarkedPages: [Int]), Error>) -> Void) {
        DataAPIManager.shared.fetchReadingProgress(bookID: bookID, firebaseUserID: firebaseUserID, completion: completion)
    }
    
    func saveBookToPublicDatabase(_ book: CloudBook, completion: @escaping (Result<String, Error>) -> Void) {
        DataAPIManager.shared.saveBookToPublicDatabase(book) { result in
            switch result {
            case .success(let bookID):
                // 發送通知
                NotificationCenter.default.post(name: Self.booksDidChangeNotification, object: nil)
                completion(.success(bookID))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func saveBookToPrivateDatabase(_ book: CloudBook, completion: @escaping (Result<String, Error>) -> Void) {
        DataAPIManager.shared.saveBookToPrivateDatabase(book) { result in
            switch result {
            case .success(let bookID):
                // 發送通知
                NotificationCenter.default.post(name: Self.booksDidChangeNotification, object: nil)
                completion(.success(bookID))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Original CloudKit Methods (保留用於日後真正連接 iCloud)
    
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
    
    // 添加 loadCoverImage 方法（目前返回 mock 數據）
    func loadCoverImage(recordName: String, isPublic: Bool, completion: @escaping (Result<UIImage, Error>) -> Void) {
        // Mock implementation - 嘗試從 Assets 中載入圖片
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let image = UIImage(named: recordName) {
                completion(.success(image))
            } else {
                // 如果找不到指定圖片，返回預設圖片
                let defaultImages = ["cover_image_1", "cover_image_2", "cover_image_3"]
                let randomImage = defaultImages.randomElement() ?? "cover_image_1"
                
                if let image = UIImage(named: randomImage) {
                    completion(.success(image))
                } else {
                    let error = NSError(domain: "com.cliffchan.manwareader", code: 404, userInfo: [NSLocalizedDescriptionKey: "Cover image not found"])
                    completion(.failure(error))
                }
            }
        }
    }
}
