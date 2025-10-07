import Foundation
import CloudKit
import UIKit

class CloudKitManager {
    static let shared = CloudKitManager()
    
    // 通知名稱
    static let booksDidChangeNotification = NSNotification.Name("BooksDidChangeNotification")
    
    // CloudKit container identifier - 請確認這個 ID 是否正確
    private let containerIdentifier = "iCloud.com.cliffchan.manwareader"
    
    // CloudKit databases
    private lazy var container: CKContainer = {
        return CKContainer(identifier: containerIdentifier)
    }()
    
    private lazy var privateDatabase: CKDatabase = {
        return container.privateCloudDatabase
    }()
    
    // MARK: - Private Database Access
    
    var privateDB: CKDatabase {
        return privateDatabase
    }
    
    private init() {
        // 初始化時檢查 CloudKit 可用性
        checkCloudKitAvailability()
    }
    
    // MARK: - CloudKit Availability Check
    
    private func checkCloudKitAvailability() {
        print("🔍 Checking CloudKit availability...")
        container.accountStatus { accountStatus, error in
            DispatchQueue.main.async {
                switch accountStatus {
                case .available:
                    print("✅ CloudKit is available")
                    // 測試容器訪問
                    self.testContainerAccess()
                case .noAccount:
                    print("⚠️ No iCloud account - User needs to sign in to iCloud")
                case .restricted:
                    print("⚠️ iCloud account is restricted - Parental controls or device restrictions")
                case .couldNotDetermine:
                    print("❌ Could not determine iCloud account status")
                case .temporarilyUnavailable:
                    print("⚠️ iCloud account temporarily unavailable - Check network connection")
                @unknown default:
                    print("❓ Unknown iCloud account status: \(accountStatus.rawValue)")
                }
                
                if let error = error {
                    print("❌ CloudKit account status error: \(error.localizedDescription)")
                    print("   Error domain: \(error._domain)")
                    print("   Error code: \(error._code)")
                }
            }
        }
    }
    
    // 測試容器訪問
    private func testContainerAccess() {
        print("🔍 Testing container access...")
        
        // 測試 private database 訪問 - 完全移除排序
        let testQuery = CKQuery(recordType: "Book", predicate: NSPredicate(value: true))
        // 完全移除排序描述符
        // testQuery.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        
        privateDatabase.perform(testQuery, inZoneWith: nil) { records, error in
            if let error = error {
                print("❌ Private Database Access Error: \(error.localizedDescription)")
                if let ckError = error as? CKError {
                    print("   CKError Code: \(ckError.code.rawValue)")
                    print("   CKError Description: \(ckError.localizedDescription)")
                    
                    // 如果還是有錯誤，可能是 Record Type 不存在
                    if ckError.code.rawValue == 12 {
                        print("🔧 This usually means the 'Book' Record Type doesn't exist yet")
                        print("   Please check CloudKit Dashboard and create the Record Types first")
                    }
                }
            } else {
                print("✅ Private Database is accessible (found \(records?.count ?? 0) Book records)")
            }
        }
    }
    
    // 添加一個測試函數來驗證 container
    func verifyContainerSetup() {
        print("🔍 === Verifying CloudKit Container Setup ===")
        print("📦 Container ID: \(containerIdentifier)")
        
        container.accountStatus { accountStatus, error in
            DispatchQueue.main.async {
                print("📱 Account Status: \(accountStatus)")
                if let error = error {
                    print("❌ Account Error: \(error.localizedDescription)")
                }
                
                // 測試 container 的 schema 信息
                self.container.fetchUserRecordID { userRecordID, error in
                    if let userRecordID = userRecordID {
                        print("✅ User Record ID: \(userRecordID.recordName)")
                        
                        // 檢查 Development vs Production 環境
                        print("🌍 Current Environment: Development (Debug Build)")
                        
                    } else if let error = error {
                        print("❌ Fetch User Record ID Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - User Books Operations (簡化版 - 只有用戶個人書籍)
    
    func fetchUserBooks(firebaseUserID: String, completion: @escaping (Result<[CloudBook], Error>) -> Void) {
        // 檢查 userID 字段是否可查詢
        let predicate = NSPredicate(format: "userID == %@", firebaseUserID)
        let query = CKQuery(recordType: "Book", predicate: predicate)
        
        // 完全移除排序描述符，在客戶端排序
        // query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        
        privateDatabase.fetch(withQuery: query) { result in
            switch result {
            case .success(let result):
                let books = result.matchResults.compactMap { (_, recordResult) -> CloudBook? in
                    switch recordResult {
                    case .success(let record):
                        return self.cloudBookFromRecord(record)
                    case .failure(let error):
                        print("Error fetching book record: \(error.localizedDescription)")
                        return nil
                    }
                }
                
                // 在客戶端進行排序 - 按書名排序
                let sortedBooks = books.sorted { book1, book2 in
                    return book1.name.localizedCaseInsensitiveCompare(book2.name) == .orderedAscending
                }
                
                completion(.success(sortedBooks))
                
            case .failure(let error):
                print("Error fetching user books: \(error.localizedDescription)")
                
                // 如果是字段不可查詢的錯誤，提供詳細指導
                if let ckError = error as? CKError, ckError.code.rawValue == 12 {
                    print("🔧 CloudKit Schema Issue Detected:")
                    if error.localizedDescription.contains("userID") {
                        print("   The 'userID' field is not marked as 'Queryable' in CloudKit Dashboard")
                        print("   Please follow the schema setup instructions to fix this")
                    } else {
                        print("   Field is not marked as queryable or sortable in CloudKit Dashboard")
                        print("   Please check your CloudKit Record Type configuration")
                    }
                }
                
                // Fallback to mock data
                DataAPIManager.shared.fetchUserBooks(firebaseUserID: firebaseUserID, completion: completion)
            }
        }
    }
    
    func saveUserBook(_ book: CloudBook, firebaseUserID: String, completion: @escaping (Result<String, Error>) -> Void) {
        let record = recordFromCloudBook(book, recordType: "Book")
        record["userID"] = firebaseUserID // 添加用戶ID字段
        
        privateDatabase.save(record) { savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else if let savedRecord = savedRecord {
                    NotificationCenter.default.post(name: Self.booksDidChangeNotification, object: nil)
                    completion(.success(savedRecord.recordID.recordName))
                }
            }
        }
    }
    
    func updateUserBook(_ book: CloudBook, firebaseUserID: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let recordID = book.recordID else {
            // 如果沒有 recordID，創建新書籍
            saveUserBook(book, firebaseUserID: firebaseUserID, completion: completion)
            return
        }
        
        privateDatabase.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = record else {
                completion(.failure(NSError(domain: "com.cliffchan.manwareader", code: 404, userInfo: [NSLocalizedDescriptionKey: "Book not found"])))
                return
            }
            
            // 更新記錄 - 移除 currentPage 的更新
            record["name"] = book.name
            record["introduction"] = book.introduction
            record["author"] = book.author
            record["content"] = book.content
            record["bookmarkedPages"] = book.bookmarkedPages.map { Int64($0) }
            
            // 保存 coverURL 字段
            if let coverURL = book.coverURL {
                record["coverURL"] = coverURL
            }
            
            // Handle cover image if exists
            if let coverImage = book.coverImage {
                if let imageData = coverImage.jpegData(compressionQuality: 0.8) {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                    do {
                        try imageData.write(to: tempURL)
                        let asset = CKAsset(fileURL: tempURL)
                        record["coverImage"] = asset
                    } catch {
                        print("Error saving image to temp file: \(error)")
                    }
                }
            }
            
            self.privateDatabase.save(record) { savedRecord, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                    } else if let savedRecord = savedRecord {
                        NotificationCenter.default.post(name: Self.booksDidChangeNotification, object: nil)
                        completion(.success(savedRecord.recordID.recordName))
                    }
                }
            }
        }
    }
    
    func deleteUserBook(bookID: String, firebaseUserID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: bookID)
        
        privateDatabase.delete(withRecordID: recordID) { deletedRecordID, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    NotificationCenter.default.post(name: Self.booksDidChangeNotification, object: nil)
                    completion(.success(()))
                }
            }
        }
    }
    
    // MARK: - 移除舊的公開/私人書籍方法，統一使用用戶書籍
    
    @available(*, deprecated, message: "Use fetchUserBooks instead")
    func fetchPublicBooks(completion: @escaping (Result<[CloudBook], Error>) -> Void) {
        // 如果有當前用戶，返回用戶的書籍；否則返回空數組
        if let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() {
            fetchUserBooks(firebaseUserID: currentUser.uid, completion: completion)
        } else {
            completion(.success([]))
        }
    }
    
    @available(*, deprecated, message: "Use fetchUserBooks instead")
    func fetchPrivateBooks(completion: @escaping (Result<[CloudBook], Error>) -> Void) {
        // 重定向到 fetchUserBooks
        if let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() {
            fetchUserBooks(firebaseUserID: currentUser.uid, completion: completion)
        } else {
            completion(.success([]))
        }
    }
    
    @available(*, deprecated, message: "Use saveUserBook instead")
    func saveBookToPublicDatabase(_ book: CloudBook, completion: @escaping (Result<String, Error>) -> Void) {
        if let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() {
            saveUserBook(book, firebaseUserID: currentUser.uid, completion: completion)
        } else {
            completion(.failure(NSError(domain: "com.cliffchan.manwareader", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
        }
    }
    
    @available(*, deprecated, message: "Use saveUserBook instead")
    func saveBookToPrivateDatabase(_ book: CloudBook, completion: @escaping (Result<String, Error>) -> Void) {
        if let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() {
            saveUserBook(book, firebaseUserID: currentUser.uid, completion: completion)
        } else {
            completion(.failure(NSError(domain: "com.cliffchan.manwareader", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
        }
    }

    // MARK: - Helper Methods (更新)
    
    private func cloudBookFromRecord(_ record: CKRecord) -> CloudBook {
        return CloudBook(
            recordID: record.recordID,
            name: record["name"] as? String ?? "",
            introduction: record["introduction"] as? String ?? "",
            coverURL: record["coverURL"] as? String, // 從 CloudKit 讀取 coverURL
            author: record["author"] as? String ?? "",
            content: record["content"] as? [String] ?? [],
            firebaseBookID: record["firebaseBookID"] as? String,
            coverImage: nil, // Will be loaded separately from Asset
            currentPage: 0, // 改為默認值 0，不從 CloudKit 讀取
            bookmarkedPages: (record["bookmarkedPages"] as? [Int64])?.map { Int($0) } ?? []
        )
    }
    
    private func recordFromCloudBook(_ book: CloudBook, recordType: String) -> CKRecord {
        let record: CKRecord
        if let recordID = book.recordID {
            record = CKRecord(recordType: recordType, recordID: recordID)
        } else {
            record = CKRecord(recordType: recordType)
        }
        
        record["name"] = book.name
        record["introduction"] = book.introduction
        record["author"] = book.author
        record["content"] = book.content
        // 移除 currentPage 的保存
        record["bookmarkedPages"] = book.bookmarkedPages.map { Int64($0) }
        
        if let firebaseBookID = book.firebaseBookID {
            record["firebaseBookID"] = firebaseBookID
        }
        
        // 保存 coverURL 字段
        if let coverURL = book.coverURL {
            record["coverURL"] = coverURL
        }
        
        // Handle cover image if exists - 保存為 Asset
        if let coverImage = book.coverImage {
            if let imageData = coverImage.jpegData(compressionQuality: 0.8) {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                do {
                    try imageData.write(to: tempURL)
                    let asset = CKAsset(fileURL: tempURL)
                    record["coverImage"] = asset
                } catch {
                    print("Error saving image to temp file: \(error)")
                }
            }
        }
        
        return record
    }

    // MARK: - User Status Check
    
    func checkUserStatus(completion: @escaping (Result<CKUserIdentity?, Error>) -> Void) {
        container.fetchUserRecordID { userRecordID, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
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
            
            let recordName = "UserLink-\(userRecordID.recordName)"
            let userRecord = CKRecord(recordType: "UserLink", recordID: CKRecord.ID(recordName: recordName))
            userRecord["firebaseUserID"] = firebaseUserID
            userRecord["cloudKitUserID"] = userRecordID.recordName
            
            self.privateDatabase.save(userRecord) { _, error in
                if let error = error {
                    // 檢查是否是重複記錄錯誤
                    if let ckError = error as? CKError, ckError.code == .serverRecordChanged {
                        print("⚠️ UserLink record already exists, this is normal")
                        completion(.success(())) // 已存在算成功
                    } else {
                        print("❌ Failed to link Firebase user to CloudKit: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: - Image Operations (添加缺失的方法)
    
    func loadCoverImage(recordName: String, isPublic: Bool, completion: @escaping (Result<UIImage, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: recordName)
        let database = privateDatabase
        
        database.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                // Fallback to local images
                DispatchQueue.main.async {
                    if let image = UIImage(named: recordName) {
                        completion(.success(image))
                    } else {
                        let defaultImages = ["cover_image_1", "cover_image_2", "cover_image_3"]
                        let randomImage = defaultImages.randomElement() ?? "cover_image_1"
                        if let image = UIImage(named: randomImage) {
                            completion(.success(image))
                        } else {
                            completion(.failure(error))
                        }
                    }
                }
                return
            }
            
            guard let record = record else {
                DispatchQueue.main.async {
                    let error = NSError(domain: "com.cliffchan.manwareader", code: 404, userInfo: [NSLocalizedDescriptionKey: "Record not found"])
                    completion(.failure(error))
                }
                return
            }
            
            // 優先使用 coverImage Asset
            if let asset = record["coverImage"] as? CKAsset,
               let fileURL = asset.fileURL {
                DispatchQueue.global(qos: .userInitiated).async {
                    if let imageData = try? Data(contentsOf: fileURL),
                       let image = UIImage(data: imageData) {
                        DispatchQueue.main.async {
                            completion(.success(image))
                        }
                    } else {
                        self.loadImageFromCoverURL(record: record, completion: completion)
                    }
                }
            }
            // 如果沒有 Asset，嘗試使用 coverURL
            else if let coverURL = record["coverURL"] as? String {
                self.loadImageFromURL(coverURL, completion: completion)
            }
            // 最後使用 fallback
            else {
                DispatchQueue.main.async {
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
    
    // 新增輔助方法：從 coverURL 載入圖片
    private func loadImageFromCoverURL(record: CKRecord, completion: @escaping (Result<UIImage, Error>) -> Void) {
        if let coverURL = record["coverURL"] as? String {
            loadImageFromURL(coverURL, completion: completion)
        } else {
            // 使用 fallback
            DispatchQueue.main.async {
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
    
    // 新增輔助方法：從 URL 載入圖片
    private func loadImageFromURL(_ urlString: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        // 如果是本地圖片名稱，直接載入
        if let image = UIImage(named: urlString) {
            DispatchQueue.main.async {
                completion(.success(image))
            }
            return
        }
        
        // 如果是 URL，從網絡載入
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                let error = NSError(domain: "com.cliffchan.manwareader", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
                completion(.failure(error))
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else if let data = data, let image = UIImage(data: data) {
                    completion(.success(image))
                } else {
                    let error = NSError(domain: "com.cliffchan.manwareader", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to load image from URL"])
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    // MARK: - Reading Progress Methods (添加缺失的方法)
    
    func fetchReadingProgress(bookID: String, firebaseUserID: String, completion: @escaping (Result<(currentPage: Int, bookmarkedPages: [Int]), Error>) -> Void) {
        // 修正查詢條件 - 使用正確的記錄ID查詢方式
        let recordID = CKRecord.ID(recordName: bookID)
        
        privateDatabase.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                print("Error fetching reading progress: \(error.localizedDescription)")
                // Fallback to mock data
                DataAPIManager.shared.fetchReadingProgress(bookID: bookID, firebaseUserID: firebaseUserID, completion: completion)
                return
            }
            
            guard let record = record else {
                completion(.success((currentPage: 0, bookmarkedPages: [])))
                return
            }
            
            // 驗證這是用戶的書籍
            guard record["userID"] as? String == firebaseUserID else {
                completion(.failure(NSError(domain: "com.cliffchan.manwareader", code: 403, userInfo: [NSLocalizedDescriptionKey: "Access denied"])))
                return
            }
            
            // currentPage 改為返回 0，因為不從雲端讀取
            let currentPage = 0
            let bookmarkedPages = (record["bookmarkedPages"] as? [Int64])?.map { Int($0) } ?? []
            completion(.success((currentPage: currentPage, bookmarkedPages: bookmarkedPages)))
        }
    }
    
    func updateUserBookProgress(bookID: String, firebaseUserID: String, currentPage: Int, bookmarkedPages: [Int], completion: @escaping (Result<UserBook, Error>) -> Void) {
        // 在簡化架構中，直接更新 Book record
        let recordID = CKRecord.ID(recordName: bookID)
        
        privateDatabase.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = record else {
                completion(.failure(NSError(domain: "com.cliffchan.manwareader", code: 404, userInfo: [NSLocalizedDescriptionKey: "Book not found"])))
                return
            }
            
            // 確保這是用戶自己的書籍
            guard record["userID"] as? String == firebaseUserID else {
                completion(.failure(NSError(domain: "com.cliffchan.manwareader", code: 403, userInfo: [NSLocalizedDescriptionKey: "Access denied"])))
                return
            }
            
            // 只更新書簽，不更新 currentPage
            record["bookmarkedPages"] = bookmarkedPages.map { Int64($0) }
            
            self.privateDatabase.save(record) { savedRecord, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                    } else if let savedRecord = savedRecord {
                        // 創建一個 UserBook 對象來保持 API 兼容性
                        let userBook = UserBook(
                            recordID: savedRecord.recordID,
                            bookID: savedRecord.recordID.recordName,
                            userID: firebaseUserID,
                            currentPage: currentPage, // 使用傳入的本地值
                            bookmarkedPages: bookmarkedPages,
                            dateAdded: Date(),
                            lastRead: Date(),
                            book: self.cloudBookFromRecord(savedRecord)
                        )
                        completion(.success(userBook))
                    }
                }
            }
        }
    }
}
