import Foundation
import CloudKit

struct UserBook: Identifiable {
    var id: String {
        return recordID?.recordName ?? UUID().uuidString
    }
    
    let recordID: CKRecord.ID?
    let bookID: String
    let userID: String // Firebase user ID
    var currentPage: Int
    var bookmarkedPages: [Int]
    let dateAdded: Date
    var lastRead: Date?
    
    // The actual book details (loaded separately)
    var book: CloudBook?
    
    static func create(for bookID: String, userID: String) -> UserBook {
        return UserBook(
            recordID: nil,
            bookID: bookID,
            userID: userID,
            currentPage: 0,
            bookmarkedPages: [],
            dateAdded: Date(),
            lastRead: nil,
            book: nil
        )
    }
    
    func withBookDetails(_ book: CloudBook) -> UserBook {
        var updated = self
        updated.book = book
        return updated
    }
}
