import SwiftUI

struct BookDetailView: View {
    @State var book: Ebook // 改為 @State 以便更新進度
    @State private var showingReader = false
    @State private var isLoadingProgress = false
    @State private var cloudProgress: (currentPage: Int, bookmarkedPages: [Int])? = nil
    
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
                
                // Action buttons
                HStack {
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
                }
                .padding(.horizontal, 20) // 兩邊20px邊距
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
}

#Preview {
    NavigationView {
        BookDetailView(book: ebookList[0])
    }
}
