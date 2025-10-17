import SwiftUI

struct BookReaderView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    @Binding var book: Ebook // 改為 @Binding 以便與 BookDetailView 同步
    @State private var currentPageIndex = 0
    @State private var showControls = true
    @State private var showBookmarks = false
    @State private var progressPercentage: Double = 0
    @State private var isButtonActionInProgress = false
    
    // 新增進度同步相關狀態
    @State private var lastSavedPage = 0
    @State private var saveTimer: Timer?
    
    // New states for push animation
    @State private var pageOffset: CGFloat = 0
    @State private var nextPageIndex: Int?
    @State private var animationDirection: PageTurnDirection?
    
    // 🔧 新增：字體設置狀態
    @State private var fontSize: Double = 16
    @State private var fontFamily: String = "System"
    
    // 🔧 修改：移除 @Namespace，改用更簡單的狀態追蹤
    @State private var scrollToTop = false
    
    // 🔧 修改：用 UUID 來強制重置 ScrollView 位置
    @State private var scrollViewID = UUID()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                ColorManager.shared.background.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Top navigation bar when controls are visible
                    if showControls {
                        topControlBar()
                    }
                    
                    // Content area with animation - takes remaining space
                    ZStack {
                        // Current page
                        if !book.content.isEmpty && currentPageIndex < book.content.count {
                            pageView(for: currentPageIndex)
                                .offset(x: pageOffset)
                                .id("page_\(currentPageIndex)_\(scrollViewID)")
                        }
                        
                        // Next page (during animation)
                        if let nextIdx = nextPageIndex, nextIdx >= 0, nextIdx < book.content.count {
                            pageView(for: nextIdx)
                                .offset(x: animationDirection == .next ? 
                                       geometry.size.width + pageOffset : 
                                       -geometry.size.width + pageOffset)
                                .id("page_\(nextIdx)_\(scrollViewID)")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Bottom indicator overlay
                VStack {
                    Spacer()
                    if showControls {
                        bottomPageIndicator()
                            .padding(.bottom, 20)
                    }
                }
                
                // Bookmarks sheet
                if showBookmarks {
                    bookmarkSheet()
                        .zIndex(2)
                }
            }
            .onAppear {
                // 🔧 新增：顯示閱讀器載入的書籍資訊
                print("📚 [BookReaderView] onAppear")
                print("   Book: \(book.title)")
                print("   Content pages: \(book.content.count)")
                print("   Can read: \(book.content.isEmpty ? "❌ NO CONTENT" : "✅ YES")")
                
                currentPageIndex = book.currentPage
                lastSavedPage = book.currentPage
                updateProgressPercentage()
                loadReadingProgress()
                
                // 🔧 新增：載入字體設置
                loadFontSettings()
                
                // 🔧 新增：註冊通知監聽
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("FontSizeDidChange"),
                    object: nil,
                    queue: .main
                ) { notification in
                    if let size = notification.userInfo?["fontSize"] as? Double {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.fontSize = size
                        }
                    }
                }
                
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("FontFamilyDidChange"),
                    object: nil,
                    queue: .main
                ) { notification in
                    if let family = notification.userInfo?["fontFamily"] as? String {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.fontFamily = family
                        }
                    }
                }
            }
            .onDisappear {
                // 確保離開時更新 book 的進度
                book.currentPage = currentPageIndex
                saveProgressImmediately()
                saveTimer?.invalidate()
                
                // 🔧 新增：移除通知監聽
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name("FontSizeDidChange"), object: nil)
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name("FontFamilyDidChange"), object: nil)
            }
            .onChange(of: currentPageIndex) { oldValue, newValue in
                // 當頁面改變時，延遲保存進度並立即更新 book 對象
                book.currentPage = newValue
                scheduleProgressSave()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded({ value in
                    if value.translation.width > 0 {
                        // Swipe right (previous page)
                        if currentPageIndex > 0 {
                            turnPageWithAnimation(direction: .previous)
                        }
                    } else if value.translation.width < 0 {
                        // Swipe left (next page)
                        if currentPageIndex < book.content.count - 1 {
                            turnPageWithAnimation(direction: .next)
                        }
                    }
                })
        )
        .navigationBarHidden(true)
        .statusBar(hidden: !showControls)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
        }
    }
    
    // 🔧 簡化：移除 scrollToTop 參數和 ScrollViewReader
    private func pageView(for index: Int) -> some View {
        ScrollView {
            VStack(spacing: 20) {
               Text(book.content[index])
                   .font(.system(size: fontSize))
                   .fontDesign(getFontDesign())
                   .foregroundColor(.black)
                   .padding()
               
               // 🔧 新增：下一頁按鈕
               if index < book.content.count - 1 {
                   Button(action: {
                       turnPageWithAnimation(direction: .next)
                   }) {
                       HStack {
                           Text(LocalizedStringKey("book_next_page"))
                           Image(systemName: "chevron.right")
                       }
                       .font(.system(size: 16, weight: .medium))
                       .foregroundColor(.white)
                       .padding(.horizontal, 24)
                       .padding(.vertical, 12)
                       .background(Color.blue)
                       .cornerRadius(25)
                   }
                   .buttonStyle(BorderlessButtonStyle())
                   .padding(.bottom, 40)
               } else {
                   // 最後一頁顯示「完成」
                   Text(LocalizedStringKey("book_finished"))
                       .font(.system(size: 16, weight: .medium))
                       .foregroundColor(.gray)
                       .padding(.bottom, 40)
               }
           }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorManager.shared.background)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
        }
    }
    
    // Top navigation bar
    private func topControlBar() -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18))
                    .foregroundColor(.black) // 改為黑色圖標
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(BorderlessButtonStyle())
            
            Spacer()
            
            // Bookmark button
            Button {
                toggleBookmark()
            } label: {
                Image(systemName: isCurrentPageBookmarked() ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 18))
                    .foregroundColor(.black) // 改為黑色圖標
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(BorderlessButtonStyle())
            
            // Bookmarks list button
            Button {
                showBookmarks.toggle()
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 18))
                    .foregroundColor(.black) // 改為黑色圖標
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding()
        .background(ColorManager.shared.background.opacity(0.95))
    }
    
    // Bottom page indicator
    private func bottomPageIndicator() -> some View {
        HStack {
            Spacer()
            
            Text(String(format: NSLocalizedString("book_page_info", comment: ""), currentPageIndex + 1, book.totalPages))
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(ColorManager.shared.background.opacity(0.8))
                .foregroundColor(.black) // 改為黑色文字
                .cornerRadius(20)
                .shadow(color: .gray.opacity(0.3), radius: 2, x: 0, y: 1)
            
            Spacer()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // 🔧 修改：bookmarkSheet 中的跳轉也要重置滾動
    private func bookmarkSheet() -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    showBookmarks = false
                }
            
            VStack {
                HStack {
                    Text(LocalizedStringKey("book_bookmarks"))
                        .font(.headline)
                        .foregroundColor(.black) // 改為黑色文字
                    Spacer()
                    Button(LocalizedStringKey("general_done")) {
                        showBookmarks = false
                    }
                    .foregroundColor(.black) // 改為黑色按鈕文字
                }
                .padding()
                
                Divider()
                
                if book.bookmarkedPages.isEmpty {
                    Text(LocalizedStringKey("book_no_bookmarks"))
                        .foregroundColor(.black.opacity(0.7)) // 改為深灰色文字
                        .padding()
                } else {
                    List {
                        ForEach(book.bookmarkedPages, id: \.self) { page in
                            Button(action: {
                                // 🔧 修改：使用動畫跳轉
                                turnPageWithAnimation(to: page)
                                showBookmarks = false
                            }) {
                                HStack {
                                    Text(String(format: NSLocalizedString("book_page_number", comment: ""), page + 1))
                                        .foregroundColor(.black) // 改為黑色文字
                                    Spacer()
                                    Text("→")
                                        .foregroundColor(.black) // 改為黑色箭頭
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden) // 隱藏背景以顯示自訂顏色
                }
            }
            .frame(height: 300)
            .background(ColorManager.shared.background)
            .cornerRadius(15)
            .shadow(radius: 10)
            .padding()
            .transition(.move(edge: .bottom))
        }
    }
    
    // Function to check if current page is bookmarked
    private func isCurrentPageBookmarked() -> Bool {
        return book.bookmarkedPages.contains(currentPageIndex)
    }
    
    // Function to toggle bookmark for current page
    private func toggleBookmark() {
        if let index = book.bookmarkedPages.firstIndex(of: currentPageIndex) {
            book.bookmarkedPages.remove(at: index)
        } else {
            book.bookmarkedPages.append(currentPageIndex)
        }
        
        // 立即保存書簽
        scheduleProgressSave()
    }
    
    // Function to update progress percentage
    private func updateProgressPercentage() {
        if book.totalPages > 0 {
            progressPercentage = Double(currentPageIndex + 1) / Double(book.totalPages)
        } else {
            progressPercentage = 0
        }
    }
    
    // Page turn direction enum
    enum PageTurnDirection {
        case next
        case previous
    }
    
    // 🔧 優化：在動畫開始前重置滾動位置
    private func turnPageWithAnimation(direction: PageTurnDirection) {
        guard !isButtonActionInProgress else { return }
        
        isButtonActionInProgress = true
        animationDirection = direction
        
        switch direction {
        case .next:
            if currentPageIndex < book.content.count - 1 {
                nextPageIndex = currentPageIndex + 1
                
                // 🔧 重置下一頁的滾動位置（在動畫開始前）
                scrollViewID = UUID()
                
                // 短暫延遲讓 ScrollView 重置完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        pageOffset = -UIScreen.main.bounds.width
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        currentPageIndex = nextPageIndex!
                        updateProgressPercentage()
                        
                        pageOffset = 0
                        nextPageIndex = nil
                        animationDirection = nil
                        isButtonActionInProgress = false
                    }
                }
            } else {
                isButtonActionInProgress = false
            }
            
        case .previous:
            if currentPageIndex > 0 {
                nextPageIndex = currentPageIndex - 1
                
                // 🔧 重置下一頁的滾動位置（在動畫開始前）
                scrollViewID = UUID()
                
                // 短暫延遲讓 ScrollView 重置完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        pageOffset = UIScreen.main.bounds.width
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        currentPageIndex = nextPageIndex!
                        updateProgressPercentage()
                        
                        pageOffset = 0
                        nextPageIndex = nil
                        animationDirection = nil
                        isButtonActionInProgress = false
                    }
                }
            } else {
                isButtonActionInProgress = false
            }
        }
    }
    
    // 🔧 優化：書籤跳轉也使用相同邏輯
    private func turnPageWithAnimation(to targetPage: Int) {
        guard !isButtonActionInProgress, 
              targetPage >= 0,
              targetPage < book.content.count, 
              targetPage != currentPageIndex else { return }
        
        let direction: PageTurnDirection = targetPage > currentPageIndex ? .next : .previous
        animationDirection = direction
        nextPageIndex = targetPage
        isButtonActionInProgress = true
        
        // 🔧 重置下一頁的滾動位置（在動畫開始前）
        scrollViewID = UUID()
        
        // 短暫延遲讓 ScrollView 重置完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            withAnimation(.easeInOut(duration: 0.25)) {
                pageOffset = direction == .next ? -UIScreen.main.bounds.width : UIScreen.main.bounds.width
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                currentPageIndex = targetPage
                updateProgressPercentage()
                
                pageOffset = 0
                nextPageIndex = nil
                animationDirection = nil
                isButtonActionInProgress = false
            }
        }
    }
    
    // MARK: - 進度同步功能
    
    private func loadReadingProgress() {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            return
        }
        
        CloudKitManager.shared.fetchReadingProgress(
            bookID: book.id,
            firebaseUserID: currentUser.uid
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let progress):
                    // currentPage 不從雲端載入，保持本地值
                    // if progress.currentPage > self.currentPageIndex {
                    //     self.currentPageIndex = progress.currentPage
                    //     self.book.currentPage = progress.currentPage
                    //     self.updateProgressPercentage()
                    // }
                    
                    // 只合併書簽
                    let mergedBookmarks = Array(Set(self.book.bookmarkedPages + progress.bookmarkedPages)).sorted()
                    self.book.bookmarkedPages = mergedBookmarks
                    
                    self.lastSavedPage = self.currentPageIndex
                    
                case .failure(let error):
                    print("Failed to load reading progress: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func scheduleProgressSave() {
        // 取消之前的計時器
        saveTimer?.invalidate()
        
        // 設置新的計時器，2秒後自動保存書簽（不保存 currentPage）
        saveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            self.saveBookmarksToCloud()
        }
    }
    
    private func saveProgressImmediately() {
        saveTimer?.invalidate()
        saveBookmarksToCloud()
    }
    
    private func saveBookmarksToCloud() {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser(),
              !book.bookmarkedPages.isEmpty else {
            return
        }
        
        CloudKitManager.shared.updateUserBookProgress(
            bookID: book.id,
            firebaseUserID: currentUser.uid,
            currentPage: currentPageIndex, // 傳入但不會被保存到雲端
            bookmarkedPages: book.bookmarkedPages
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    print("Bookmarks saved successfully")
                    
                    // 給用戶一個輕微的觸覺反饋
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                case .failure(let error):
                    print("Failed to save bookmarks: \(error.localizedDescription)")
                    
                    // 錯誤觸覺反饋
                    let errorFeedback = UINotificationFeedbackGenerator()
                    errorFeedback.notificationOccurred(.error)
                }
            }
        }
    }
    
    // MARK: - 🔧 新增：字體設置相關方法
    
    private func loadFontSettings() {
        fontSize = UserDefaults.standard.double(forKey: "fontSize")
        if (fontSize == 0) { fontSize = 16 }
        fontFamily = UserDefaults.standard.string(forKey: "selectedFont") ?? "System"
    }
    
    private func getFontDesign() -> Font.Design {
        switch fontFamily {
        case "Rounded":
            return .rounded
        case "Serif":
            return .serif
        case "Monospaced":
            return .monospaced
        default:
            return .default
        }
    }
}

#Preview {
    @State var sampleBook = ebookList[0]
    return BookReaderView(book: $sampleBook)
}
