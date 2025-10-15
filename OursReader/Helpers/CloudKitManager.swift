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
        let predicate = NSPredicate(format: "userID == %@", firebaseUserID)
        let query = CKQuery(recordType: "Book", predicate: predicate)
        
        privateDatabase.fetch(withQuery: query) { result in
            switch result {
            case .success(let result):
                let dispatchGroup = DispatchGroup()
                var books: [CloudBook] = []
                var hasError: Error?
                
                for (_, recordResult) in result.matchResults {
                    switch recordResult {
                    case .success(let record):
                        dispatchGroup.enter()
                        
                        let isChunkedValue = record["isChunked"] as? Int64 ?? 1
                        let isChunked = isChunkedValue == 1
                        
                        if (isChunked) {
                            // 🔧 修正：只載入元數據，不載入完整內容
                            var book = self.cloudBookFromRecord(record)
                            book.content = [] // 清空內容，強制用戶下載
                            books.append(book)
                            dispatchGroup.leave()
                        } else {
                            let book = self.cloudBookFromRecord(record)
                            books.append(book)
                            dispatchGroup.leave()
                        }
                        
                    case .failure(let error):
                        print("Error fetching book record: \(error.localizedDescription)")
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    if let error = hasError {
                        completion(.failure(error))
                    } else {
                        let sortedBooks = books.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                        
                        // 同步下載狀態
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.syncDownloadStatusForBooks(sortedBooks)
                        }
                        
                        completion(.success(sortedBooks))
                    }
                }
                
            case .failure(let error):
                print("Error fetching user books: \(error.localizedDescription)")
                DataAPIManager.shared.fetchUserBooks(firebaseUserID: firebaseUserID, completion: completion)
            }
        }
    }
    
    // 🔧 修正：移除自動保存書籍到本地的邏輯
    private func saveLoadedBooksToLocal(_ books: [CloudBook]) {
        // 🔧 完全移除自動保存邏輯，只檢查並同步狀態
        // 不再自動保存任何書籍到本地
        print("📚 Books loaded: \(books.count), checking local status only")
    }

    // 🔧 修正：只同步狀態，不自動下載
    private func syncDownloadStatusForBooks(_ books: [CloudBook]) {
        let cacheManager = BookCacheManager.shared
        var syncedCount = 0
        var removedCount = 0
        
        for book in books {
            if cacheManager.checkLocalFileExists(book.id) {
                // 文件存在且未標記 → 標記為已下載
                if !cacheManager.isBookDownloaded(book.id) {
                    cacheManager.markBookAsDownloaded(book.id)
                    syncedCount += 1
                }
            } else {
                // 文件不存在但已標記 → 移除標記
                if cacheManager.isBookDownloaded(book.id) {
                    cacheManager.removeBookCache(book.id)
                    removedCount += 1
                }
            }
        }
        
        if syncedCount > 0 || removedCount > 0 {
            print("✅ Sync complete: +\(syncedCount) marked, -\(removedCount) unmarked")
            NotificationCenter.default.post(name: Self.booksDidChangeNotification, object: nil)
        }
    }
    
    func saveUserBook(_ book: CloudBook, firebaseUserID: String, completion: @escaping (Result<String, Error>) -> Void) {
        saveUserBookWithChunking(book, firebaseUserID: firebaseUserID) { result in
            if case .success(let recordID) = result {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            let fileManager = FileManager.default
                            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                            let bookURL = documentsURL.appendingPathComponent("book_\(book.id).json")
                            
                            let ebookData = book.toEbook()
                            let jsonData = try JSONEncoder().encode([ebookData])
                            try jsonData.write(to: bookURL)
                            
                            DispatchQueue.main.async {
                                BookCacheManager.shared.markBookAsDownloaded(book.id)
                                print("✅ Book uploaded and cached: \(book.name)")
                                
                                NotificationCenter.default.post(name: Self.booksDidChangeNotification, object: nil)
                            }
                        } catch {
                            print("⚠️ Failed to cache uploaded book: \(error.localizedDescription)")
                        }
                    }
                }
            }
            completion(result)
        }
    }
    
    // MARK: - 分片保存（所有書籍）
    private func saveUserBookWithChunking(_ book: CloudBook, firebaseUserID: String, completion: @escaping (Result<String, Error>) -> Void) {
        let mainRecord = CKRecord(recordType: "Book")
        mainRecord["userID"] = firebaseUserID
        mainRecord["name"] = book.name
        mainRecord["introduction"] = book.introduction
        mainRecord["author"] = book.author
        mainRecord["isChunked"] = Int64(1) // 使用 Int64 代替 Boolean，1=true
        mainRecord["totalChunks"] = 0 // 先設為 0，稍後更新
        mainRecord["bookmarkedPages"] = book.bookmarkedPages.map { Int64($0) }
        
        if let firebaseBookID = book.firebaseBookID {
            mainRecord["firebaseBookID"] = firebaseBookID
        }
        
        if let coverURL = book.coverURL {
            mainRecord["coverURL"] = coverURL
        }
        
        // Handle cover image
        if let coverImage = book.coverImage {
            if let imageData = coverImage.jpegData(compressionQuality: 0.8) {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                do {
                    try imageData.write(to: tempURL)
                    let asset = CKAsset(fileURL: tempURL)
                    mainRecord["coverImage"] = asset
                } catch {
                    print("Error saving image to temp file: \(error)")
                }
            }
        }
        
        // 2. 分割內容成小塊
        let chunks = chunkContent(book.content)
        mainRecord["totalChunks"] = Int64(chunks.count)
        
        privateDatabase.save(mainRecord) { savedMainRecord, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let savedMainRecord = savedMainRecord else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "com.cliffchan.manwareader", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to save main record"])))
                }
                return
            }
            
            let mainRecordID = savedMainRecord.recordID.recordName
            
            // 4. 保存內容塊
            self.saveContentChunks(chunks, mainRecordID: mainRecordID, userID: firebaseUserID) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success():
                        NotificationCenter.default.post(name: Self.booksDidChangeNotification, object: nil)
                        completion(.success(mainRecordID))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    // MARK: - 分割內容（調整分塊大小）
    private func chunkContent(_ content: [String]) -> [[String]] {
        var chunks: [[String]] = []
        var currentChunk: [String] = []
        var currentSize = 0
        
        let maxChunkSize = 300 * 1024 // 300KB per chunk，更保守的大小
        
        for page in content {
            let pageSize = page.data(using: .utf8)?.count ?? page.count
            
            if currentSize + pageSize > maxChunkSize && !currentChunk.isEmpty {
                // 當前塊已滿，開始新塊
                chunks.append(currentChunk)
                currentChunk = [page]
                currentSize = pageSize
            } else {
                // 添加到當前塊
                currentChunk.append(page)
                currentSize += pageSize
            }
        }
        
        // 添加最後一塊
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        
        return chunks
    }
    
    // MARK: - 保存內容塊
    private func saveContentChunks(_ chunks: [[String]], mainRecordID: String, userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var hasError: Error?
        
        for (index, chunk) in chunks.enumerated() {
            dispatchGroup.enter()
            
            let chunkRecord = CKRecord(recordType: "BookChunk")
            chunkRecord["userID"] = userID
            chunkRecord["mainBookID"] = mainRecordID
            chunkRecord["chunkIndex"] = Int64(index)
            chunkRecord["content"] = chunk
            
            privateDatabase.save(chunkRecord) { _, error in
                if let error = error {
                    hasError = error
                    print("❌ Failed to save chunk \(index): \(error.localizedDescription)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .global()) {
            if let error = hasError {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - 載入分片書籍
    // 🔧 修正：改為 internal（默認訪問級別），讓 BookCacheManager 可以調用
    func loadChunkedBook(_ mainRecord: CKRecord, completion: @escaping (Result<CloudBook, Error>) -> Void) {
        let mainRecordID = mainRecord.recordID.recordName
        let totalChunks = mainRecord["totalChunks"] as? Int64 ?? 0
        
        let predicate = NSPredicate(format: "mainBookID == %@", mainRecordID)
        let query = CKQuery(recordType: "BookChunk", predicate: predicate)
        
        privateDatabase.fetch(withQuery: query) { result in
            switch result {
            case .success(let result):
                var chunks: [(Int, [String])] = []
                
                for (_, recordResult) in result.matchResults {
                    switch recordResult {
                    case .success(let chunkRecord):
                        let chunkIndex = chunkRecord["chunkIndex"] as? Int64 ?? 0
                        let content = chunkRecord["content"] as? [String] ?? []
                        chunks.append((Int(chunkIndex), content))
                    case .failure(let error):
                        print("Error loading chunk: \(error.localizedDescription)")
                    }
                }
                
                // 按索引排序並合併內容
                chunks.sort { $0.0 < $1.0 }
                let mergedContent = chunks.flatMap { $0.1 }
                
                // 創建 CloudBook
                var book = self.cloudBookFromRecord(mainRecord)
                book.content = mergedContent
                
                completion(.success(book))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func updateUserBook(_ book: CloudBook, firebaseUserID: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let recordID = book.recordID else {
            // 如果沒有 recordID，創建新書籍
            saveUserBook(book, firebaseUserID: firebaseUserID, completion: completion)
            return
        }
        
        // 對於分片書籍的更新，我們需要特殊處理
        privateDatabase.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = record else {
                completion(.failure(NSError(domain: "com.cliffchan.manwareader", code: 404, userInfo: [NSLocalizedDescriptionKey: "Book not found"])))
                return
            }
            
            // 檢查是否為分片書籍（Int64 格式）
            let isChunkedValue = record["isChunked"] as? Int64 ?? 1 // 默認為分片
            let isChunked = isChunkedValue == 1
            
            if isChunked {
                // 分片書籍的更新：只更新主記錄的元數據
                record["name"] = book.name
                record["introduction"] = book.introduction
                record["author"] = book.author
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
                
                // 如果內容有變化，需要重新保存分片
                let chunks = self.chunkContent(book.content)
                record["totalChunks"] = Int64(chunks.count)
                
                self.privateDatabase.save(record) { savedRecord, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                        return
                    }
                    
                    guard let savedRecord = savedRecord else {
                        DispatchQueue.main.async {
                            completion(.failure(NSError(domain: "com.cliffchan.manwareader", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to update main record"])))
                        }
                        return
                    }
                    
                    let mainRecordID = savedRecord.recordID.recordName
                    
                    // 刪除舊的內容塊並保存新的
                    self.updateContentChunks(chunks, mainRecordID: mainRecordID, userID: firebaseUserID) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success():
                                NotificationCenter.default.post(name: Self.booksDidChangeNotification, object: nil)
                                completion(.success(savedRecord.recordID.recordName))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    }
                }
            } else {
                // 這種情況不應該發生，因為我們現在統一使用分片
                print("⚠️ 發現非分片書籍，重新保存為分片格式")
                self.saveUserBook(book, firebaseUserID: firebaseUserID, completion: completion)
            }
        }
    }
    
    // MARK: - 更新內容塊
    private func updateContentChunks(_ chunks: [[String]], mainRecordID: String, userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // 先刪除舊的內容塊
        let predicate = NSPredicate(format: "mainBookID == %@", mainRecordID)
        let query = CKQuery(recordType: "BookChunk", predicate: predicate)
        
        privateDatabase.fetch(withQuery: query) { result in
            switch result {
            case .success(let result):
                let deleteGroup = DispatchGroup()
                
                // 刪除舊的分片
                for (_, recordResult) in result.matchResults {
                    switch recordResult {
                    case .success(let chunkRecord):
                        deleteGroup.enter()
                        self.privateDatabase.delete(withRecordID: chunkRecord.recordID) { _, error in
                            if let error = error {
                                print("⚠️ 刪除舊分片失敗：\(error.localizedDescription)")
                            }
                            deleteGroup.leave()
                        }
                    case .failure(let error):
                        print("獲取分片記錄失敗：\(error.localizedDescription)")
                    }
                }
                
                deleteGroup.notify(queue: .global()) {
                    // 保存新的分片
                    self.saveContentChunks(chunks, mainRecordID: mainRecordID, userID: userID, completion: completion)
                }
                
            case .failure(let error):
                print("查詢舊分片失敗：\(error.localizedDescription)")
                // 即使查詢失敗，也嘗試保存新分片
                self.saveContentChunks(chunks, mainRecordID: mainRecordID, userID: userID, completion: completion)
            }
        }
    }

    // MARK: - Helper Methods (更新)
    
    // 🔧 修正：改為 internal，讓 BookCacheManager 可以調用
    func cloudBookFromRecord(_ record: CKRecord) -> CloudBook {
        return CloudBook(
            recordID: record.recordID,
            name: record["name"] as? String ?? "",
            introduction: record["introduction"] as? String ?? "",
            coverURL: record["coverURL"] as? String,
            author: record["author"] as? String ?? "",
            content: [], // 初始化為空數組，稍後在分片載入時會被填充
            firebaseBookID: record["firebaseBookID"] as? String,
            coverImage: nil,
            currentPage: 0,
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
        record["bookmarkedPages"] = book.bookmarkedPages.map { Int64($0) }
        
        if let firebaseBookID = book.firebaseBookID {
            record["firebaseBookID"] = firebaseBookID
        }
        
        if let coverURL = book.coverURL {
            record["coverURL"] = coverURL
        }
        
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

    // MARK: - User Status Check (重新添加缺失的方法)
    
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

    // MARK: - Image Operations (確保方法存在)
    
    func loadCoverImage(recordName: String, isPublic: Bool, completion: @escaping (Result<UIImage, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: recordName)
        let database = privateDatabase
        
        database.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                // 🔧 修改：直接使用程式化生成的預設封面
                DispatchQueue.main.async {
                    let defaultImage = DefaultBookCoverView.generateUIImage(
                        width: 140, 
                        height: 200, 
                        title: recordName
                    )
                    completion(.success(defaultImage))
                }
                return
            }
            
            guard let record = record else {
                DispatchQueue.main.async {
                    let defaultImage = DefaultBookCoverView.generateUIImage(width: 140, height: 200)
                    completion(.success(defaultImage))
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
            // 🔧 修改：最後使用程式化生成的預設封面
            else {
                DispatchQueue.main.async {
                    let defaultImage = DefaultBookCoverView.generateUIImage(
                        width: 140, 
                        height: 200, 
                        title: record["name"] as? String
                    )
                    completion(.success(defaultImage))
                }
            }
        }
    }
    
    // 新增輔助方法：從 coverURL 載入圖片
    private func loadImageFromCoverURL(record: CKRecord, completion: @escaping (Result<UIImage, Error>) -> Void) {
        if let coverURL = record["coverURL"] as? String {
            loadImageFromURL(coverURL, completion: completion)
        } else {
            // 🔧 修改：使用程式化生成的預設封面
            DispatchQueue.main.async {
                let defaultImage = DefaultBookCoverView.generateUIImage(
                    width: 140, 
                    height: 200, 
                    title: record["name"] as? String
                )
                completion(.success(defaultImage))
            }
        }
    }
    
    // 新增輔助方法：從 URL 載入圖片
    private func loadImageFromURL(_ urlString: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        // 🔧 修改：不再嘗試從本地載入圖片，直接使用程式化生成的預設封面
        DispatchQueue.main.async {
            let defaultImage = DefaultBookCoverView.generateUIImage(width: 140, height: 200)
            completion(.success(defaultImage))
        }
    }
    
    // 🔧 修改：創建統一的 dummy 書本圖片
    private func createDummyBookImage() -> UIImage {
        return DefaultBookCoverView.generateUIImage(width: 140, height: 200, title: "BOOK")
    }

    // MARK: - Reading Progress Methods (確保方法存在)
    
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
    
    func deleteUserBook(bookID: String, firebaseUserID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: bookID)
        
        // 保留關鍵 log
        print("🗑️ Deleting book: \(recordID.recordName)")
        
        // 先驗證記錄是否存在並屬於該用戶
        privateDatabase.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                print("❌ Failed to fetch record for deletion: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let record = record else {
                print("❌ Book not found: \(recordID.recordName)")
                let notFoundError = NSError(domain: "com.cliffchan.manwareader", code: 404, userInfo: [NSLocalizedDescriptionKey: "Record not found"])
                DispatchQueue.main.async {
                    completion(.failure(notFoundError))
                }
                return
            }
            
            // 驗證記錄屬於該用戶
            if let recordUserID = record["userID"] as? String, recordUserID != firebaseUserID {
                print("❌ Access denied: Record belongs to different user")
                let accessError = NSError(domain: "com.cliffchan.manwareader", code: 403, userInfo: [NSLocalizedDescriptionKey: "Access denied"])
                DispatchQueue.main.async {
                    completion(.failure(accessError))
                }
                return
            }
            
            let isChunkedValue = record["isChunked"] as? Int64 ?? 1
            let isChunked = isChunkedValue == 1
            
            if isChunked {
                self.deleteBookChunks(mainBookID: recordID.recordName) { chunkResult in
                    self.privateDatabase.delete(withRecordID: recordID) { deletedRecordID, error in
                        DispatchQueue.main.async {
                            if let error = error {
                                print("❌ Delete failed: \(error.localizedDescription)")
                                completion(.failure(error))
                            } else {
                                print("✅ Book deleted successfully")
                                BookCacheManager.shared.removeBookCache(bookID)
                                NotificationCenter.default.post(name: Self.booksDidChangeNotification, object: nil)
                                completion(.success(()))
                            }
                        }
                    }
                }
            } else {
                self.privateDatabase.delete(withRecordID: recordID) { deletedRecordID, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("❌ CloudKit delete failed: \(error.localizedDescription)")
                            completion(.failure(error))
                        } else if let deletedRecordID = deletedRecordID {
                            print("✅ Successfully deleted record: \(deletedRecordID.recordName)")
                            
                            // 🔧 修改：只移除本地緩存
                            BookCacheManager.shared.removeBookCache(bookID)
                            
                            NotificationCenter.default.post(name: Self.booksDidChangeNotification, object: nil)
                            completion(.success(()))
                        } else {
                            print("⚠️ Delete operation completed but no record ID returned")
                            completion(.success(()))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 刪除書籍分片的輔助方法
    private func deleteBookChunks(mainBookID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let predicate = NSPredicate(format: "mainBookID == %@", mainBookID)
        let query = CKQuery(recordType: "BookChunk", predicate: predicate)
        
        privateDatabase.fetch(withQuery: query) { result in
            switch result {
            case .success(let result):
                let deleteGroup = DispatchGroup()
                var deleteErrors: [Error] = []
                
                for (_, recordResult) in result.matchResults {
                    switch recordResult {
                    case .success(let chunkRecord):
                        deleteGroup.enter()
                        self.privateDatabase.delete(withRecordID: chunkRecord.recordID) { _, error in
                            if let error = error {
                                deleteErrors.append(error)
                            }
                            deleteGroup.leave()
                        }
                    case .failure(let error):
                        print("❌ Failed to fetch chunk: \(error.localizedDescription)")
                    }
                }
                
                deleteGroup.notify(queue: .global()) {
                    if deleteErrors.isEmpty {
                        completion(.success(()))
                    } else {
                        completion(.failure(deleteErrors.first!))
                    }
                }
                
            case .failure(let error):
                print("❌ Failed to query chunks: \(error.localizedDescription)")
                completion(.failure(error))
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
}
