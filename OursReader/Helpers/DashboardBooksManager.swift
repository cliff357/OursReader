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
        
        // 同時載入公開書籍和用戶書架
        let group = DispatchGroup()
        var publicBooks: [CloudBook] = []
        var userBooks: [UserBook] = []
        
        // 載入公開書籍
        group.enter()
        CloudKitManager.shared.fetchPublicBooks { result in
            switch result {
            case .success(let books):
                publicBooks = books
            case .failure(let error):
                print("Failed to load public books: \(error)")
            }
            group.leave()
        }
        
        // 載入用戶書架（如果有登入用戶）
        if let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() {
            group.enter()
            CloudKitManager.shared.fetchUserBookshelf(firebaseUserID: currentUser.uid) { result in
                switch result {
                case .success(let books):
                    userBooks = books
                case .failure(let error):
                    print("Failed to load user books: \(error)")
                }
                group.leave()
            }
        }
        
        // 所有數據載入完成後處理
        group.notify(queue: .main) {
            self.processBooksData(publicBooks: publicBooks, userBooks: userBooks)
            self.isLoading = false
        }
    }
    
    private func processBooksData(publicBooks: [CloudBook], userBooks: [UserBook]) {
        // 設置精選書籍（取前6本公開書籍）
        featuredBooks = Array(publicBooks.prefix(6))
        
        // 設置最近閱讀的書籍（從用戶書架中取最近讀過的）
        recentBooks = userBooks
            .compactMap { $0.book }
            .sorted { book1, book2 in
                // 這裡可以根據最後閱讀時間排序
                return book1.currentPage > book2.currentPage
            }
            .prefix(4)
            .map { $0 }
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
