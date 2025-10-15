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
                        }
                        
                        // Next page (during animation)
                        if let nextIdx = nextPageIndex, nextIdx >= 0, nextIdx < book.content.count {
                            pageView(for: nextIdx)
                                .offset(x: animationDirection == .next ? 
                                       geometry.size.width + pageOffset : 
                                       -geometry.size.width + pageOffset)
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
            }
            .onDisappear {
                // 確保離開時更新 book 的進度
                book.currentPage = currentPageIndex
                saveProgressImmediately()
                saveTimer?.invalidate()
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
    
    // Page view for specific index
    private func pageView(for index: Int) -> some View {
        ScrollView {
            Text(book.content[index])
                .foregroundColor(.black) // 改為黑色文字
                .padding()
                .padding(.bottom, 20)
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
    
    // Bookmarks sheet
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
                                currentPageIndex = page
                                updateProgressPercentage()
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
    
    // Turn page with animation
    private func turnPageWithAnimation(direction: PageTurnDirection) {
        guard !isButtonActionInProgress else { return }
        
        isButtonActionInProgress = true
        animationDirection = direction
        
        switch direction {
        case .next:
            if currentPageIndex < book.content.count - 1 {
                // Set up next page animation
                nextPageIndex = currentPageIndex + 1
                
                // Start the push animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    pageOffset = -UIScreen.main.bounds.width
                }
                
                // After animation completes, update the page
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    currentPageIndex = nextPageIndex!
                    updateProgressPercentage()
                    
                    // Reset for next animation
                    pageOffset = 0
                    nextPageIndex = nil
                    animationDirection = nil
                    isButtonActionInProgress = false
                }
            } else {
                isButtonActionInProgress = false
            }
            
        case .previous:
            if currentPageIndex > 0 {
                // Set up previous page animation
                nextPageIndex = currentPageIndex - 1
                
                // Start the push animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    pageOffset = UIScreen.main.bounds.width
                }
                
                // After animation completes, update the page
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    currentPageIndex = nextPageIndex!
                    updateProgressPercentage()
                    
                    // Reset for next animation
                    pageOffset = 0
                    nextPageIndex = nil
                    animationDirection = nil
                    isButtonActionInProgress = false
                }
            } else {
                isButtonActionInProgress = false
            }
        }
    }
    
    // Go to specific page with animation
    private func turnPageWithAnimation(to targetPage: Int) {
        guard !isButtonActionInProgress, 
              targetPage >= 0,
              targetPage < book.content.count, 
              targetPage != currentPageIndex else { return }
        
        // Determine direction based on target page
        let direction: PageTurnDirection = targetPage > currentPageIndex ? .next : .previous
        animationDirection = direction
        nextPageIndex = targetPage
        isButtonActionInProgress = true
        
        // Start the push animation
        withAnimation(.easeInOut(duration: 0.3)) {
            pageOffset = direction == .next ? -UIScreen.main.bounds.width : UIScreen.main.bounds.width
        }
        
        // After animation completes, update the page
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentPageIndex = targetPage
            updateProgressPercentage()
            
            // Reset for next animation
            pageOffset = 0
            nextPageIndex = nil
            animationDirection = nil
            isButtonActionInProgress = false
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
}

#Preview {
    @State var sampleBook = ebookList[0]
    return BookReaderView(book: $sampleBook)
}
