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
    var content: [String] // 改為 var，允許修改
    
    // Optional link to a Firebase book ID if this represents a book from Firebase
    let firebaseBookID: String?
    
    // Transient property - not stored directly in CloudKit
    var coverImage: UIImage?
    
    // Reading progress - these are stored separately but can be loaded into this model
    var currentPage: Int = 0
    var bookmarkedPages: [Int] = []
}

// Extension to convert between Ebook and CloudBook
extension CloudBook {
    // Convert to Ebook
    func toEbook() -> Ebook {
        return Ebook(
            id: firebaseBookID ?? id,
            name: name,
            title: name,
            instruction: introduction,
            author: author,
            coverImage: coverURL ?? "cover_image_1", // Default placeholder if no cover URL
            content: content,
            currentPage: currentPage,
            bookmarkedPages: bookmarkedPages
        )
    }
    
    // Create from Ebook
    static func fromEbook(_ ebook: Ebook) -> CloudBook {
        return CloudBook(
            recordID: nil, // Will be assigned when saved
            name: ebook.name,
            introduction: ebook.instruction,
            coverURL: nil, // Will be set when image is saved
            author: ebook.author,
            content: ebook.content,
            firebaseBookID: ebook.id,
            coverImage: UIImage(named: ebook.coverImage), // Try to load the image
            currentPage: ebook.currentPage,
            bookmarkedPages: ebook.bookmarkedPages
        )
    }
}
