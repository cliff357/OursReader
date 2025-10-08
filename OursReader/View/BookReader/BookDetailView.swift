import SwiftUI

struct BookDetailView: View {
    @State var book: Ebook // 改為 @State 以便更新進度
    @State private var showingReader = false
    @State private var isLoadingProgress = false
    @State private var cloudProgress: (currentPage: Int, bookmarkedPages: [Int])? = nil
    
    // 新增刪除相關狀態
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
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
                    if isDeleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.7)
                            .frame(width: 20, height: 20)
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
    
    // MARK: - 刪除書籍功能
    
    private func deleteBook() {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            print("No user logged in, cannot delete book")
            return
        }
        
        isDeleting = true
        
        // 給用戶觸覺反饋
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 🔧 修改：首先需要找到對應的 CloudBook 來獲取正確的 recordID
        print("🔍 Looking for book to delete: \(book.title) (ID: \(book.id))")
        
        // 先獲取用戶的所有書籍，找到對應的 CloudBook
        CloudKitManager.shared.fetchUserBooks(firebaseUserID: currentUser.uid) { result in
            switch result {
            case .success(let cloudBooks):
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
                
                DispatchQueue.main.async {
                    if let cloudBook = targetCloudBook {
                        // 使用找到的 CloudBook 的 recordID 進行刪除
                        self.deleteCloudBook(cloudBook, userID: currentUser.uid)
                    } else {
                        print("❌ Could not find matching CloudBook for: \(self.book.title)")
                        print("📋 Available books:")
                        for (index, cb) in cloudBooks.enumerated() {
                            print("   \(index + 1). '\(cb.name)' by \(cb.author) (ID: \(cb.id))")
                        }
                        
                        self.isDeleting = false
                        
                        // 錯誤觸覺反饋
                        let errorFeedback = UINotificationFeedbackGenerator()
                        errorFeedback.notificationOccurred(.error)
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    print("❌ Failed to fetch books for deletion: \(error.localizedDescription)")
                    self.isDeleting = false
                    
                    // 錯誤觸覺反饋
                    let errorFeedback = UINotificationFeedbackGenerator()
                    errorFeedback.notificationOccurred(.error)
                }
            }
        }
    }
    
    // 新增輔助方法：使用 CloudBook 的 recordID 進行刪除
    private func deleteCloudBook(_ cloudBook: CloudBook, userID: String) {
        guard let recordID = cloudBook.recordID else {
            print("❌ CloudBook has no recordID, cannot delete")
            self.isDeleting = false
            return
        }
        
        print("🗑️ Deleting book with recordID: \(recordID.recordName)")
        
        CloudKitManager.shared.deleteUserBook(
            bookID: recordID.recordName, // 使用正確的 recordID
            firebaseUserID: userID
        ) { result in
            DispatchQueue.main.async {
                self.isDeleting = false
                
                switch result {
                case .success():
                    print("✅ Book deleted successfully from CloudKit: \(self.book.title)")
                    
                    // 成功觸覺反饋
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                    
                    // 返回上一頁
                    self.dismiss()
                    
                case .failure(let error):
                    print("❌ Failed to delete book from CloudKit: \(error.localizedDescription)")
                    
                    // 錯誤觸覺反饋
                    let errorFeedback = UINotificationFeedbackGenerator()
                    errorFeedback.notificationOccurred(.error)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        BookDetailView(book: ebookList[0])
    }
}
