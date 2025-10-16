//
//  BookCacheManager.swift
//  OursReader
//
//  Created by System on [Date].
//

import Foundation
import SwiftUI
import CloudKit

class BookCacheManager: ObservableObject {
    static let shared = BookCacheManager()
    
    @Published private var downloadedBooks: Set<String> = []
    @Published private var downloadingBooks: Set<String> = []
    
    private let userDefaults = UserDefaults.standard
    private let downloadedBooksKey = "downloaded_books"
    private let documentsURL: URL
    
    init() {
        // 獲取Documents目錄
        documentsURL = FileManager.default.urls(for: .documentDirectory, 
                                              in: .userDomainMask).first!
        loadDownloadedBooks()
        
        // 監聽用戶登出事件
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidLogout),
            name: .userDidLogout,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    /// 檢查書籍是否已下載
    func isBookDownloaded(_ bookId: String) -> Bool {
        return downloadedBooks.contains(bookId)
    }
    
    /// 檢查書籍是否正在下載
    func isBookDownloading(_ bookId: String) -> Bool {
        return downloadingBooks.contains(bookId)
    }
    
    /// 下載書籍
    func downloadBook(_ book: CloudBook, completion: @escaping (Result<Void, Error>) -> Void) {
        print("⬇️ [CacheManager] downloadBook called for: \(book.name)")
        print("   Book ID: \(book.id)")
        print("   Already downloaded: \(isBookDownloaded(book.id))")
        print("   Currently downloading: \(isBookDownloading(book.id))")
        
        guard !isBookDownloaded(book.id) && !isBookDownloading(book.id) else {
            print("   ⏭️ Skipping - already downloaded or downloading")
            completion(.success(()))
            return
        }
        
        // 標記為正在下載
        DispatchQueue.main.async {
            self.downloadingBooks.insert(book.id)
            print("   🔄 Marked as downloading")
            // 🔧 關鍵：觸發 UI 更新顯示下載中圖標
            self.objectWillChange.send()
        }
        
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            print("   ❌ No user logged in")
            DispatchQueue.main.async {
                self.downloadingBooks.remove(book.id)
                completion(.failure(NSError(domain: "BookCacheManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            }
            return
        }
        
        print("   👤 User: \(currentUser.uid)")
        print("   ☁️ Fetching full content from CloudKit...")
        
        // 🔧 新增：使用新的方法載入完整書籍內容
        loadFullBookContent(bookId: book.id, userId: currentUser.uid) { result in
            switch result {
            case .success(let fullBook):
                print("   ✅ Full content loaded")
                print("   Content pages: \(fullBook.content.count)")
                
                // 保存到本地
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let bookURL = self.getBookFileURL(bookId: fullBook.id)
                        print("   💾 Saving to: \(bookURL.path)")
                        
                        let ebookData = fullBook.toEbook()
                        let jsonData = try JSONEncoder().encode([ebookData])
                        print("   📦 JSON size: \(jsonData.count) bytes")
                        
                        try jsonData.write(to: bookURL)
                        print("   ✅ File saved successfully")
                        
                        DispatchQueue.main.async {
                            self.downloadingBooks.remove(fullBook.id)
                            self.downloadedBooks.insert(fullBook.id)
                            self.saveDownloadedBooks()
                            print("   ✅ Download complete: \(fullBook.name)")
                            print("   📊 Total downloaded books: \(self.downloadedBooks.count)")
                            completion(.success(()))
                        }
                    } catch {
                        print("   ❌ Save failed: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.downloadingBooks.remove(fullBook.id)
                            completion(.failure(error))
                        }
                    }
                }
                
            case .failure(let error):
                print("   ❌ Load full content failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.downloadingBooks.remove(book.id)
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 獲取本地書籍數據
    func getLocalBook(_ bookId: String) -> Ebook? {
        // 🔧 新增：詳細日誌
        print("🔍 [CacheManager] getLocalBook called for: \(bookId)")
        print("   isBookDownloaded: \(isBookDownloaded(bookId))")
        
        guard isBookDownloaded(bookId) else {
            print("   ❌ Book NOT marked as downloaded")
            return nil
        }
        
        do {
            let bookURL = getBookFileURL(bookId: bookId)
            print("   📁 File path: \(bookURL.path)")
            
            let fileExists = FileManager.default.fileExists(atPath: bookURL.path)
            print("   File exists: \(fileExists ? "✅" : "❌")")
            
            if !fileExists {
                print("   ⚠️ File marked as downloaded but doesn't exist!")
                return nil
            }
            
            let jsonData = try Data(contentsOf: bookURL)
            print("   📄 File size: \(jsonData.count) bytes")
            
            let books = try JSONDecoder().decode([Ebook].self, from: jsonData)
            if let book = books.first {
                print("   ✅ Successfully loaded from cache")
                print("   Pages: \(book.totalPages)")
                return book
            } else {
                print("   ❌ No book data in file")
                return nil
            }
        } catch {
            print("   ❌ Failed to load from cache: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 刪除本地書籍
    func deleteLocalBook(_ bookId: String) {
        do {
            let bookURL = getBookFileURL(bookId: bookId)
            try FileManager.default.removeItem(at: bookURL)
            
            DispatchQueue.main.async {
                self.downloadedBooks.remove(bookId)
                self.saveDownloadedBooks()
            }
        } catch {
            print("❌ 刪除本地書籍失敗: \(error)")
        }
    }
    
    // 🔧 新增：移除單本書籍的緩存（別名方法，與 deleteLocalBook 相同）
    func removeBookCache(_ bookId: String) {
        deleteLocalBook(bookId)
    }
    
    /// 獲取下載進度（0.0 - 1.0）
    func getDownloadProgress(_ bookId: String) -> Double {
        if (isBookDownloaded(bookId)) {
            return 1.0
        } else if (isBookDownloading(bookId)) {
            // 實際實現中可以返回真實進度
            return 0.5
        } else {
            return 0.0
        }
    }
    
    // 🔧 修正：確保正確保存和載入下載狀態
    func markBookAsDownloaded(_ bookId: String) {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            return
        }
        
        DispatchQueue.main.async {
            guard !self.downloadedBooks.contains(bookId) else {
                return
            }
            
            self.downloadedBooks.insert(bookId)
            
            let userKey = "\(self.downloadedBooksKey)_\(currentUser.uid)"
            self.userDefaults.set(Array(self.downloadedBooks), forKey: userKey)
            
            // 移除詳細 log，只保留簡單確認
            // print("✅ 書籍標記為已下載：\(bookId)")
            
            self.objectWillChange.send()
        }
    }
    
    // 🔧 新增：調試方法，檢查下載狀態
    func debugDownloadStatus() {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            return
        }
        
        let userKey = "\(downloadedBooksKey)_\(currentUser.uid)"
        print("📊 Download Status:")
        print("   Downloaded books: \(downloadedBooks.count)")
        // 移除詳細列表
    }
    
    // 🔧 新增：檢查本地文件是否存在並自動同步下載狀態
    func syncDownloadStatusFromLocalFiles() {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            return
        }
        
        DispatchQueue.global(qos: .utility).async {
            do {
                // 獲取 Documents 目錄中所有的書籍文件
                let contents = try FileManager.default.contentsOfDirectory(
                    at: self.documentsURL,
                    includingPropertiesForKeys: [.fileSizeKey],
                    options: [.skipsHiddenFiles]
                )
                
                // 篩選出所有 book_*.json 文件
                let bookFiles = contents.filter { url in
                    url.lastPathComponent.hasPrefix("book_") && url.pathExtension == "json"
                }
                
                var syncedBooks: Set<String> = []
                
                for bookFile in bookFiles {
                    // 從文件名提取 bookId (例如: book_abc123.json -> abc123)
                    let fileName = bookFile.deletingPathExtension().lastPathComponent
                    if let bookId = fileName.components(separatedBy: "book_").last {
                        // 驗證文件是否有效（可以解碼）
                        if self.validateBookFile(bookFile) {
                            syncedBooks.insert(bookId)
                        } else {
                            // 如果文件損壞，刪除它
                            print("⚠️ Removing corrupted file: \(fileName)")
                            try? FileManager.default.removeItem(at: bookFile)
                        }
                    }
                }
                
                // 更新下載狀態
                DispatchQueue.main.async {
                    let oldCount = self.downloadedBooks.count
                    self.downloadedBooks = syncedBooks
                    self.saveDownloadedBooks()
                    
                    let newCount = self.downloadedBooks.count
                    // 🔧 只在有變化時輸出 log
                    if oldCount != newCount {
                        print("✅ Synced: \(oldCount) → \(newCount) books")
                    }
                    
                    // 觸發 UI 更新
                    self.objectWillChange.send()
                }
                
            } catch {
                print("❌ Sync failed: \(error.localizedDescription)")
            }
        }
    }
    
    // 🔧 新增：驗證書籍文件是否有效
    private func validateBookFile(_ fileURL: URL) -> Bool {
        do {
            let data = try Data(contentsOf: fileURL)
            _ = try JSONDecoder().decode([Ebook].self, from: data)
            return true
        } catch {
            return false
        }
    }
    
    // 🔧 新增：檢查特定書籍的本地文件是否存在
    func checkLocalFileExists(_ bookId: String) -> Bool {
        let bookURL = getBookFileURL(bookId: bookId)
        return FileManager.default.fileExists(atPath: bookURL.path)
    }
    
    // MARK: - Private Methods
    
    private func getBookFileURL(bookId: String) -> URL {
        return documentsURL.appendingPathComponent("book_\(bookId).json")
    }
    
    private func loadDownloadedBooks() {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            downloadedBooks = []
            return
        }
        
        let userKey = "\(downloadedBooksKey)_\(currentUser.uid)"
        if let bookIds = userDefaults.stringArray(forKey: userKey) {
            downloadedBooks = Set(bookIds)
        }
    }
    
    private func saveDownloadedBooks() {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            return
        }
        
        let userKey = "\(downloadedBooksKey)_\(currentUser.uid)"
        userDefaults.set(Array(downloadedBooks), forKey: userKey)
    }
    
    @objc private func userDidLogout() {
        clearAllCache()
    }
    
    func clearAllCache() {
        // 清除下載列表
        downloadedBooks.removeAll()
        downloadingBooks.removeAll()
        
        // 清除UserDefaults
        if let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() {
            let userKey = "\(downloadedBooksKey)_\(currentUser.uid)"
            userDefaults.removeObject(forKey: userKey)
        }
        
        // 清除本地文件
        clearLocalFiles()
        
        print("✅ Successfully cleared all book cache")
    }
    
    private func clearLocalFiles() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: documentsURL, 
                                                                      includingPropertiesForKeys: nil)
            for url in contents {
                if url.lastPathComponent.hasPrefix("book_") && url.pathExtension == "json" {
                    try FileManager.default.removeItem(at: url)
                }
            }
        } catch {
            print("❌ 清除本地文件失敗: \(error)")
        }
    }
    
    // 🔧 新增：專門載入完整書籍內容的方法
    private func loadFullBookContent(bookId: String, userId: String, completion: @escaping (Result<CloudBook, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: bookId)
        
        CloudKitManager.shared.privateDB.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = record else {
                completion(.failure(NSError(domain: "BookCacheManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Book not found"])))
                return
            }
            
            // 驗證權限
            guard record["userID"] as? String == userId else {
                completion(.failure(NSError(domain: "BookCacheManager", code: 403, userInfo: [NSLocalizedDescriptionKey: "Access denied"])))
                return
            }
            
            // 檢查是否為分片書籍
            let isChunkedValue = record["isChunked"] as? Int64 ?? 1
            let isChunked = isChunkedValue == 1
            
            if isChunked {
                // 載入分片內容
                CloudKitManager.shared.loadChunkedBook(record) { result in
                    completion(result)
                }
            } else {
                // 非分片書籍
                let book = CloudKitManager.shared.cloudBookFromRecord(record)
                completion(.success(book))
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
}
