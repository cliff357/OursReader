//
//  BookCacheManager.swift
//  OursReader
//
//  Created by System on [Date].
//

import Foundation
import SwiftUI

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
        guard !isBookDownloaded(book.id) && !isBookDownloading(book.id) else {
            completion(.success(()))
            return
        }
        
        // 標記為正在下載
        DispatchQueue.main.async {
            self.downloadingBooks.insert(book.id)
        }
        
        // 模擬下載過程（實際應該從CloudKit獲取完整數據）
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 創建本地文件路徑
                let bookURL = self.getBookFileURL(bookId: book.id)
                
                // 將書籍數據轉換為Ebook格式並保存
                let ebookData = book.toEbook()
                let jsonData = try JSONEncoder().encode([ebookData])
                
                // 保存到本地
                try jsonData.write(to: bookURL)
                
                // 更新下載狀態
                DispatchQueue.main.async {
                    self.downloadingBooks.remove(book.id)
                    self.downloadedBooks.insert(book.id)
                    self.saveDownloadedBooks()
                    completion(.success(()))
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.downloadingBooks.remove(book.id)
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 獲取本地書籍數據
    func getLocalBook(_ bookId: String) -> Ebook? {
        guard isBookDownloaded(bookId) else { return nil }
        
        do {
            let bookURL = getBookFileURL(bookId: bookId)
            let jsonData = try Data(contentsOf: bookURL)
            let books = try JSONDecoder().decode([Ebook].self, from: jsonData)
            return books.first
        } catch {
            print("❌ 讀取本地書籍失敗: \(error)")
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
    
    /// 獲取下載進度（0.0 - 1.0）
    func getDownloadProgress(_ bookId: String) -> Double {
        if isBookDownloaded(bookId) {
            return 1.0
        } else if isBookDownloading(bookId) {
            // 實際實現中可以返回真實進度
            return 0.5
        } else {
            return 0.0
        }
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
    
    private func clearAllCache() {
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
}

// MARK: - Notification Names
extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
}
