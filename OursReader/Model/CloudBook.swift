import Foundation
import CloudKit
import UIKit

struct CloudBook: Identifiable {
    var id: String {
        return recordID?.recordName ?? UUID().uuidString
    }
    
    let recordID: CKRecord.ID?
    let name: String
    let introduction: String
    let coverURL: String?
    let author: String
    var content: [String]
    
    // Optional link to a Firebase book ID if this represents a book from Firebase
    let firebaseBookID: String?
    
    // Transient property - not stored directly in CloudKit
    var coverImage: UIImage?
    
    // Reading progress - these are stored separately but can be loaded into this model
    var currentPage: Int
    var bookmarkedPages: [Int]
    
    // 🔧 新增：明確的初始化器
    init(recordID: CKRecord.ID?, name: String, introduction: String, coverURL: String?, author: String, content: [String], firebaseBookID: String?, coverImage: UIImage? = nil, currentPage: Int = 0, bookmarkedPages: [Int] = []) {
        self.recordID = recordID
        self.name = name
        self.introduction = introduction
        self.coverURL = coverURL
        self.author = author
        self.content = content
        self.firebaseBookID = firebaseBookID
        self.coverImage = coverImage
        self.currentPage = currentPage
        self.bookmarkedPages = bookmarkedPages
    }
}

// Extension to convert between Ebook and CloudBook
extension CloudBook {
    // Convert to Ebook
    func toEbook() -> Ebook {
        // 🔧 關鍵修正：統一使用 CloudKit Record ID，確保 ID 一致性
        return Ebook(
            id: self.id, // 使用 CloudKit Record ID，不再使用 firebaseBookID
            title: self.name,
            author: self.author,
            coverImage: self.coverURL ?? "default_cover",
            instruction: self.introduction,
            pages: self.content,
            totalPages: self.content.count,
            currentPage: self.currentPage,
            bookmarkedPages: self.bookmarkedPages
        )
    }
    
    // Create from Ebook
    static func fromEbook(_ ebook: Ebook) -> CloudBook {
        return CloudBook(
            recordID: nil,
            name: ebook.title,
            introduction: ebook.instruction,
            coverURL: ebook.coverImage == "default_cover" ? nil : ebook.coverImage,
            author: ebook.author,
            content: ebook.pages,
            firebaseBookID: ebook.id, // 保留 firebaseBookID 作為參考
            coverImage: nil,
            currentPage: ebook.currentPage,
            bookmarkedPages: ebook.bookmarkedPages
        )
    }
}
