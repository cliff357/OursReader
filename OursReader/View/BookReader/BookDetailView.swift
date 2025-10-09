import SwiftUI

struct BookDetailView: View {
    @State var book: Ebook // 改為 @State 以便更新進度
    @State private var showingReader = false
    @State private var isLoadingProgress = false
    @State private var cloudProgress: (currentPage: Int, bookmarkedPages: [Int])? = nil
    
    // 新增刪除相關狀態
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @State private var deleteProgress = "正在刪除..." // 新增：刪除進度文字
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Book cover image and title
                HStack(alignment: .top, spacing: 20) {
                    Image(book.coverImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 180)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black) // 改為黑色，確保高對比度
                        
                        Text("by \(book.author)")
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.7)) // 改為深灰色，保持清晰可讀
                        
                        // Add reading progress indicator
                        if book.totalPages > 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Reading Progress")
                                        .font(.caption)
                                        .foregroundColor(.black.opacity(0.8)) // 改為較深的顏色
                                    
                                    if isLoadingProgress {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(0.6)
                                    }
                                }
                                
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.black.opacity(0.2)) // 改為較深的背景
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(ColorManager.shared.red1)
                                        .frame(width: calculateProgressWidth(totalWidth: 120), height: 6)
                                }
                                
                                Text("\(book.currentPage + 1) of \(book.totalPages) pages")
                                    .font(.caption2)
                                    .foregroundColor(.black.opacity(0.8)) // 改為較深的顏色
                                
                                // 移除雲端同步狀態顯示
                            }
                            .padding(.top, 6)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .background(ColorManager.shared.dark_brown.opacity(0.3))
                
                // Action buttons - 只保留閱讀按鈕
                Button(action: {
                    showingReader = true
                }) {
                    Label("Read Now", systemImage: "book.fill")
                        .font(.headline)
                        .foregroundColor(ColorManager.shared.rice_white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(ColorManager.shared.red1)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.vertical)
                
                Divider()
                    .background(Color.secondary.opacity(0.3)) // 使用系統顏色
                
                // Book description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .foregroundColor(.black) // 改為黑色
                    
                    Text(book.instruction)
                        .font(.body)
                        .foregroundColor(.black.opacity(0.8)) // 改為深灰色，確保易讀
                }
                .padding(.horizontal)
                
                Divider()
                    .background(Color.black.opacity(0.2)) // 改為較深的分隔線
                
                // Book information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Information")
                        .font(.headline)
                        .foregroundColor(.black) // 改為黑色
                    
                    HStack {
                        Text("Pages:")
                            .fontWeight(.medium)
                            .foregroundColor(.black) // 改為黑色
                        Text("\(book.totalPages)")
                            .foregroundColor(.black.opacity(0.7)) // 改為深灰色
                        Spacer()
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(ColorManager.shared.background)
        .navigationTitle("") // 空字符串移除標題，但保留導航欄
        .navigationBarTitleDisplayMode(.inline) // 確保導航欄存在
        .toolbarBackground(ColorManager.shared.background, for: .navigationBar) // 設置導航欄背景色
        .accentColor(.black) // 確保此頁面的強調色為黑色
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    // 🔧 修正：顯示載入狀態或刪除圖標
                    if isDeleting {
                        HStack(spacing: 6) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                .scaleEffect(0.8)
                                .frame(width: 16, height: 16)
                            
                            Text("刪除中...")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    } else {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.system(size: 16))
                    }
                }
                .disabled(isDeleting)
            }
        }
        .alert("Remove Book", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                deleteBook()
            }
        } message: {
            Text("Are you sure you want to remove '\(book.title)' from your library? This action cannot be undone.")
        }
        // 🔧 新增：全屏載入覆蓋層
        .overlay {
            if isDeleting {
                ZStack {
                    // 半透明背景
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    // 載入提示卡片
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: ColorManager.shared.red1))
                            .scaleEffect(1.5)
                        
                        Text(deleteProgress)
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Text("請稍候，正在從雲端移除書籍...")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .background(ColorManager.shared.background)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 40)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .onAppear {
            // 設置導航欄外觀
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(ColorManager.shared.background)
            appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
            
            // 設置返回按鈕顏色
            UINavigationBar.appearance().tintColor = UIColor.black
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
        }
        .fullScreenCover(isPresented: $showingReader) {
            BookReaderView(book: $book) // 使用 binding 傳遞
        }
        .onAppear {
            loadCloudProgress()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // 當應用回到前台時重新載入進度
            loadCloudProgress()
        }
        // 監聽書籍進度變化並更新進度條
        .onChange(of: book.currentPage) { oldValue, newValue in
            // 當書籍進度改變時，重新計算進度條
            print("Book progress updated: \(newValue)")
        }
    }
    
    private func loadCloudProgress() {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            return
        }
        
        isLoadingProgress = true
        
        CloudKitManager.shared.fetchReadingProgress(
            bookID: book.id,
            firebaseUserID: currentUser.uid
        ) { result in
            DispatchQueue.main.async {
                self.isLoadingProgress = false
                
                switch result {
                case .success(let progress):
                    self.cloudProgress = progress
                    
                    // 如果雲端進度比本地進度新，更新本地進度
                    if progress.currentPage != self.book.currentPage {
                        self.book.currentPage = progress.currentPage
                    }
                    
                    // 合併書簽
                    let mergedBookmarks = Array(Set(self.book.bookmarkedPages + progress.bookmarkedPages)).sorted()
                    self.book.bookmarkedPages = mergedBookmarks
                    
                case .failure(let error):
                    print("Failed to load cloud progress: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Calculate the width of the progress bar
    private func calculateProgressWidth(totalWidth: CGFloat) -> CGFloat {
        guard book.totalPages > 0 else { return 0 }
        let progress = CGFloat(book.currentPage + 1) / CGFloat(book.totalPages)
        return totalWidth * progress
    }
    
    // MARK: - 刪除書籍功能（增強版本）
    
    private func deleteBook() {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            print("No user logged in, cannot delete book")
            return
        }
        
        // 🔧 開始刪除流程，顯示載入狀態
        withAnimation(.easeInOut(duration: 0.3)) {
            isDeleting = true
            deleteProgress = "正在準備刪除..."
        }
        
        // 給用戶觸覺反饋
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 🔧 分階段顯示進度
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.deleteProgress = "正在查找書籍記錄..."
        }
        
        print("🔍 Looking for book to delete: \(book.title) (ID: \(book.id))")
        
        // 先獲取用戶的所有書籍，找到對應的 CloudBook
        CloudKitManager.shared.fetchUserBooks(firebaseUserID: currentUser.uid) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cloudBooks):
                    self.deleteProgress = "正在定位目標書籍..."
                    
                    // 延遲一點讓用戶看到進度更新
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.findAndDeleteCloudBook(cloudBooks: cloudBooks, userID: currentUser.uid)
                    }
                    
                case .failure(let error):
                    self.handleDeleteError("獲取書籍列表失敗: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 🔧 新增：尋找並刪除 CloudBook 的輔助方法
    private func findAndDeleteCloudBook(cloudBooks: [CloudBook], userID: String) {
        // 嘗試通過不同方式找到對應的書籍
        var targetCloudBook: CloudBook?
        
        // 1. 優先通過 firebaseBookID 匹配
        if let foundBook = cloudBooks.first(where: { $0.firebaseBookID == book.id }) {
            targetCloudBook = foundBook
            print("✅ Found book by firebaseBookID: \(book.id)")
        }
        // 2. 如果沒找到，嘗試通過書名和作者匹配
        else if let foundBook = cloudBooks.first(where: { 
            $0.name == book.title && $0.author == book.author 
        }) {
            targetCloudBook = foundBook
            print("✅ Found book by title and author: \(book.title)")
        }
        // 3. 最後嘗試只通過書名匹配
        else if let foundBook = cloudBooks.first(where: { $0.name == book.title }) {
            targetCloudBook = foundBook
            print("✅ Found book by title only: \(book.title)")
        }
        
        if let cloudBook = targetCloudBook {
            deleteProgress = "找到目標書籍，正在從雲端刪除..."
            
            // 延遲一點後執行實際刪除
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.executeCloudBookDeletion(cloudBook, userID: userID)
            }
        } else {
            handleDeleteError("找不到對應的書籍記錄")
        }
    }
    
    // 🔧 新增：執行實際刪除的方法
    private func executeCloudBookDeletion(_ cloudBook: CloudBook, userID: String) {
        guard let recordID = cloudBook.recordID else {
            handleDeleteError("書籍記錄ID無效，無法刪除")
            return
        }
        
        deleteProgress = "正在從 CloudKit 刪除..."
        print("🗑️ Deleting book with recordID: \(recordID.recordName)")
        
        CloudKitManager.shared.deleteUserBook(
            bookID: recordID.recordName,
            firebaseUserID: userID
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    self.handleDeleteSuccess()
                    
                case .failure(let error):
                    self.handleDeleteError("刪除失敗: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 🔧 新增：處理刪除成功
    private func handleDeleteSuccess() {
        deleteProgress = "刪除完成！"
        
        print("✅ Book deleted successfully from CloudKit: \(book.title)")
        
        // 成功觸覺反饋
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
        
        // 顯示成功狀態 1 秒後自動返回
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.isDeleting = false
            }
            
            // 延遲一點後返回上一頁
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.dismiss()
            }
        }
    }
    
    // 🔧 新增：處理刪除錯誤
    private func handleDeleteError(_ errorMessage: String) {
        print("❌ Delete error: \(errorMessage)")
        
        // 錯誤觸覺反饋
        let errorFeedback = UINotificationFeedbackGenerator()
        errorFeedback.notificationOccurred(.error)
        
        deleteProgress = "刪除失敗"
        
        // 顯示錯誤狀態 2 秒後隱藏載入覆蓋層
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.isDeleting = false
            }
        }
    }
}

#Preview {
    NavigationView {
        BookDetailView(book: ebookList[0])
    }
}
