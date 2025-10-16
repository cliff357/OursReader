import Foundation

class DashboardBooksManager: ObservableObject {
    static let shared = DashboardBooksManager()
    
    @Published var featuredBooks: [CloudBook] = []
    @Published var recentBooks: [CloudBook] = []
    @Published var isLoading = false
    
    private init() {}
    
    // 載入 Dashboard 顯示的書籍
    func loadDashboardBooks() {
        isLoading = true
        
        // 在簡化架構中，直接載入用戶書籍
        if let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() {
            CloudKitManager.shared.fetchUserBooks(firebaseUserID: currentUser.uid) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let books):
                        self.processBooksData(userBooks: books)
                    case .failure(let error):
                        print("Failed to load user books: \(error)")
                        self.processBooksData(userBooks: [])
                    }
                    self.isLoading = false
                }
            }
        } else {
            // 沒有用戶時返回空數據
            DispatchQueue.main.async {
                self.processBooksData(userBooks: [])
                self.isLoading = false
            }
        }
    }
    
    private func processBooksData(userBooks: [CloudBook]) {
        // 設置精選書籍（取前6本用戶書籍）
        featuredBooks = Array(userBooks.prefix(6))
        
        // 設置最近閱讀的書籍（根據 currentPage 排序，顯示有進度的書）
        recentBooks = userBooks
            .filter { $0.currentPage > 0 } // 只顯示有閱讀進度的書
            .sorted { $0.currentPage > $1.currentPage } // 按進度排序
            .prefix(4)
            .map { $0 }
        
        // 如果沒有有進度的書，就取最前面的幾本
        if recentBooks.isEmpty {
            recentBooks = Array(userBooks.prefix(4))
        }
    }
    
    // 獲取要在 Dashboard 中顯示的書籍
    func getBooksForDisplay() -> [CloudBook] {
        // 優先顯示最近閱讀的書籍，然後是精選書籍
        var displayBooks: [CloudBook] = []
        
        // 添加最近閱讀的書籍
        displayBooks.append(contentsOf: recentBooks.prefix(2))
        
        // 添加精選書籍，但避免重複
        let recentBookIDs = Set(recentBooks.map { $0.id })
        let additionalFeatured = featuredBooks.filter { !recentBookIDs.contains($0.id) }
        displayBooks.append(contentsOf: additionalFeatured.prefix(4))
        
        return displayBooks
    }
}
