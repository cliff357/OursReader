import Foundation
import UIKit

class DataAPIManager {
    static let shared = DataAPIManager()
    
    private init() {}
    
    // MARK: - Mock Data
    private var mockPublicBooks: [CloudBook] = []
    private var mockPrivateBooks: [CloudBook] = []
    private var mockUserBooks: [UserBook] = []
    private var mockReadingProgress: [String: (currentPage: Int, bookmarkedPages: [Int])] = [:]
    
    // MARK: - Initialization
    func initializeMockData() {
        setupMockPublicBooks()
        setupMockPrivateBooks()
        setupMockUserBooks()
    }
    
    private func setupMockPublicBooks() {
        mockPublicBooks = [
            CloudBook(
                recordID: nil,
                name: "Swift Programming Guide",
                introduction: "A comprehensive guide to Swift programming language for beginners and advanced developers.",
                coverURL: nil,
                author: "Apple Inc.",
                content: [
                    "Chapter 1: Introduction to Swift\n\nSwift is a powerful and intuitive programming language for iOS, macOS, watchOS, and tvOS.",
                    "Swift code is safe by design and produces software that runs lightning-fast.",
                    "Swift is the result of the latest research on programming languages, combined with decades of experience building Apple platforms."
                ],
                firebaseBookID: nil,
                coverImage: UIImage(named: "cover_image_1")
            ),
            CloudBook(
                recordID: nil,
                name: "iOS Development Fundamentals",
                introduction: "Learn the basics of iOS app development using Swift and UIKit.",
                coverURL: nil,
                author: "John Developer",
                content: [
                    "Chapter 1: Getting Started with iOS Development\n\nThis book will guide you through the fundamentals of iOS development.",
                    "You'll learn about Xcode, Interface Builder, and the iOS SDK.",
                    "By the end of this book, you'll be able to create your own iOS apps."
                ],
                firebaseBookID: nil,
                coverImage: UIImage(named: "cover_image_2")
            ),
            CloudBook(
                recordID: nil,
                name: "SwiftUI Essentials",
                introduction: "Master the declarative UI framework for all Apple platforms.",
                coverURL: nil,
                author: "UI Expert",
                content: [
                    "Chapter 1: Introduction to SwiftUI\n\nSwiftUI is Apple's modern UI framework for building user interfaces.",
                    "It uses a declarative syntax that makes it easy to build complex UIs.",
                    "SwiftUI works seamlessly across all Apple platforms."
                ],
                firebaseBookID: nil,
                coverImage: UIImage(named: "cover_image_3")
            )
        ]
    }
    
    private func setupMockPrivateBooks() {
        mockPrivateBooks = [
            CloudBook(
                recordID: nil,
                name: "My Programming Journey",
                introduction: "Personal notes and experiences from my coding journey.",
                coverURL: nil,
                author: "Me",
                content: [
                    "Day 1: Started Learning Swift\n\nToday I began my journey into Swift programming.",
                    "The syntax is clean and intuitive compared to other languages I've used.",
                    "I'm excited to build my first iOS app!"
                ],
                firebaseBookID: nil,
                coverImage: UIImage(named: "cover_image_1")
            ),
            CloudBook(
                recordID: nil,
                name: "Project Ideas",
                introduction: "Collection of app ideas and concepts.",
                coverURL: nil,
                author: "Me",
                content: [
                    "Idea 1: Reading App\n\nBuild an app that allows users to read and share books.",
                    "Features: Cloud sync, bookmarks, reading progress, social sharing.",
                    "Target audience: Book lovers and students."
                ],
                firebaseBookID: nil,
                coverImage: UIImage(named: "cover_image_2")
            )
        ]
    }
    
    private func setupMockUserBooks() {
        // Mock user bookshelf data
        mockUserBooks = [
            UserBook(
                recordID: nil,
                bookID: mockPublicBooks[0].id,
                userID: "mock_user_123",
                currentPage: 1,
                bookmarkedPages: [0, 2],
                dateAdded: Date().addingTimeInterval(-86400 * 7), // 7 days ago
                lastRead: Date().addingTimeInterval(-86400 * 2), // 2 days ago
                book: mockPublicBooks[0]
            ),
            UserBook(
                recordID: nil,
                bookID: mockPrivateBooks[0].id,
                userID: "mock_user_123",
                currentPage: 0,
                bookmarkedPages: [],
                dateAdded: Date().addingTimeInterval(-86400 * 3), // 3 days ago
                lastRead: Date().addingTimeInterval(-86400), // 1 day ago
                book: mockPrivateBooks[0]
            )
        ]
    }
    
    // MARK: - Public API Methods
    
    // Fetch Public Books
    func fetchPublicBooks(completion: @escaping (Result<[CloudBook], Error>) -> Void) {
        // 如果有當前用戶，返回用戶書籍；否則返回空
        if let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() {
            fetchUserBooks(firebaseUserID: currentUser.uid, completion: completion)
        } else {
            completion(.success([]))
        }
    }
    
    // Fetch Private Books
    func fetchPrivateBooks(completion: @escaping (Result<[CloudBook], Error>) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completion(.success(self.mockPrivateBooks))
        }
    }
    
    // Fetch User Bookshelf
    func fetchUserBookshelf(firebaseUserID: String, completion: @escaping (Result<[UserBook], Error>) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let userBooks = self.mockUserBooks.filter { $0.userID == firebaseUserID }
            completion(.success(userBooks))
        }
    }
    
    // 添加新的用戶書籍 API
    func fetchUserBooks(firebaseUserID: String, completion: @escaping (Result<[CloudBook], Error>) -> Void) {
        // 從 mockPublicBooks 中過濾屬於該用戶的書籍（模擬）
        let userBooks = mockPublicBooks // 重用現有數據作為模擬
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(.success(userBooks))
        }
    }
    
    // Add Book to User Bookshelf
    func addBookToUserBookshelf(_ bookID: String, firebaseUserID: String, completion: @escaping (Result<UserBook, Error>) -> Void) {
        // Check if book already exists
        if let existingBook = mockUserBooks.first(where: { $0.bookID == bookID && $0.userID == firebaseUserID }) {
            completion(.success(existingBook))
            return
        }
        
        // Find the book details
        var book: CloudBook?
        if let publicBook = mockPublicBooks.first(where: { $0.id == bookID }) {
            book = publicBook
        } else if let privateBook = mockPrivateBooks.first(where: { $0.id == bookID }) {
            book = privateBook
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
            book: book
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
    
    // 新增用戶書籍保存方法
    func saveUserBook(_ book: CloudBook, firebaseUserID: String, completion: @escaping (Result<String, Error>) -> Void) {
        var newBook = book
        newBook = CloudBook(
            recordID: nil,
            name: book.name,
            introduction: book.introduction,
            coverURL: book.coverURL,
            author: book.author,
            content: book.content,
            firebaseBookID: book.firebaseBookID,
            coverImage: book.coverImage,
            currentPage: book.currentPage,
            bookmarkedPages: book.bookmarkedPages
        )
        
        mockPublicBooks.append(newBook)
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(.success(newBook.id))
        }
    }
}
