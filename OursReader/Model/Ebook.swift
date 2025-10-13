struct Ebook: Identifiable, Codable {
    let id: String
    let title: String
    let author: String
    let coverImage: String
    let instruction: String
    let pages: [String]
    let totalPages: Int
    var currentPage: Int
    var bookmarkedPages: [Int]
    
    // 🔧 確保有正確的初始化器
    init(id: String, title: String, author: String, coverImage: String, instruction: String, pages: [String], totalPages: Int, currentPage: Int, bookmarkedPages: [Int]) {
        self.id = id
        self.title = title
        self.author = author
        self.coverImage = coverImage
        self.instruction = instruction
        self.pages = pages
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.bookmarkedPages = bookmarkedPages
    }
    
    // 🔧 為了與 CloudBook 兼容的計算屬性
    var name: String {
        return title
    }
    
    var content: [String] {
        return pages
    }
    
    var introduction: String {
        return instruction
    }
    
    // 🔧 進度百分比
    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage) / Double(totalPages)
    }
}
