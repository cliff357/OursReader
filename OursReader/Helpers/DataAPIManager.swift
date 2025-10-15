import Foundation
import UIKit

class DataAPIManager {
    static let shared = DataAPIManager()
    
    private init() {}
    
    // MARK: - Mock Data (簡化)
    private var mockUserBooks: [UserBook] = []
    private var mockReadingProgress: [String: (currentPage: Int, bookmarkedPages: [Int])] = [:]
    
    // MARK: - Initialization
    func initializeMockData() {
        setupMockUserBooks()
    }
    
    private func setupMockUserBooks() {
        // 簡化的 mock 用戶書籍數據（如果需要的話）
        mockUserBooks = []
    }
    
    // MARK: - Public API Methods (簡化)
    
    // 🔧 簡化：直接重定向到用戶書籍
    func fetchPublicBooks(completion: @escaping (Result<[CloudBook], Error>) -> Void) {
        if let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() {
            fetchUserBooks(firebaseUserID: currentUser.uid, completion: completion)
        } else {
            completion(.success([]))
        }
    }
    
    // 🔧 簡化：直接重定向到用戶書籍
    func fetchPrivateBooks(completion: @escaping (Result<[CloudBook], Error>) -> Void) {
        if let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() {
            fetchUserBooks(firebaseUserID: currentUser.uid, completion: completion)
        } else {
            completion(.success([]))
        }
    }
    
    // 主要方法：獲取用戶書籍
    func fetchUserBooks(firebaseUserID: String, completion: @escaping (Result<[CloudBook], Error>) -> Void) {
        // 返回空數組，實際數據由 CloudKitManager 處理
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion(.success([]))
        }
    }
    
    // Add Book to User Bookshelf
    func addBookToUserBookshelf(_ bookID: String, firebaseUserID: String, completion: @escaping (Result<UserBook, Error>) -> Void) {
        // Check if book already exists
        if let existingBook = mockUserBooks.first(where: { $0.bookID == bookID && $0.userID == firebaseUserID }) {
            completion(.success(existingBook))
            return
        }
        
        // Create new UserBook
        let newUserBook = UserBook(
            recordID: nil,
            bookID: bookID,
            userID: firebaseUserID,
            currentPage: 0,
            bookmarkedPages: [], // 空的 Int 數組，不是 [Any]
            dateAdded: Date(),
            lastRead: nil,
            book: nil
        )
        
        // Add to mock data
        mockUserBooks.append(newUserBook)
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            completion(.success(newUserBook))
        }
    }
    
    // Remove Book from User Bookshelf
    func removeBookFromUserBookshelf(bookID: String, firebaseUserID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        mockUserBooks.removeAll { $0.bookID == bookID && $0.userID == firebaseUserID }
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            completion(.success(()))
        }
    }
    
    // Update Reading Progress
    func updateUserBookProgress(bookID: String, firebaseUserID: String, currentPage: Int, bookmarkedPages: [Int], completion: @escaping (Result<UserBook, Error>) -> Void) {
        // Find existing UserBook or create new one
        if let index = mockUserBooks.firstIndex(where: { $0.bookID == bookID && $0.userID == firebaseUserID }) {
            // Update existing
            mockUserBooks[index].currentPage = currentPage
            mockUserBooks[index].bookmarkedPages = bookmarkedPages
            mockUserBooks[index].lastRead = Date()
            
            completion(.success(mockUserBooks[index]))
        } else {
            // Create new UserBook
            addBookToUserBookshelf(bookID, firebaseUserID: firebaseUserID) { result in
                switch result {
                case .success(var userBook):
                    userBook.currentPage = currentPage
                    userBook.bookmarkedPages = bookmarkedPages
                    userBook.lastRead = Date()
                    completion(.success(userBook))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Fetch Reading Progress
    func fetchReadingProgress(bookID: String, firebaseUserID: String, completion: @escaping (Result<(currentPage: Int, bookmarkedPages: [Int]), Error>) -> Void) {
        // Find progress in UserBooks
        if let userBook = mockUserBooks.first(where: { $0.bookID == bookID && $0.userID == firebaseUserID }) {
            // currentPage 改為返回 0，因為只存本地
            completion(.success((currentPage: 0, bookmarkedPages: userBook.bookmarkedPages)))
        } else {
            // No progress found, return default
            completion(.success((currentPage: 0, bookmarkedPages: [])))
        }
    }
    
    // Save Book (for adding new books) - 更新為兼容新架構
    func saveBookToPublicDatabase(_ book: CloudBook, completion: @escaping (Result<String, Error>) -> Void) {
        // 重定向到用戶書籍保存
        if let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() {
            saveUserBook(book, firebaseUserID: currentUser.uid, completion: completion)
        } else {
            completion(.failure(NSError(domain: "com.cliffchan.manwareader", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
        }
    }
    
    func saveBookToPrivateDatabase(_ book: CloudBook, completion: @escaping (Result<String, Error>) -> Void) {
        // 重定向到用戶書籍保存
        if let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() {
            saveUserBook(book, firebaseUserID: currentUser.uid, completion: completion)
        } else {
            completion(.failure(NSError(domain: "com.cliffchan.manwareader", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
        }
    }
    
    // 🔧 簡化：用戶書籍保存
    func saveUserBook(_ book: CloudBook, firebaseUserID: String, completion: @escaping (Result<String, Error>) -> Void) {
        // 模擬保存成功
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            completion(.success(UUID().uuidString))
        }
    }
}
