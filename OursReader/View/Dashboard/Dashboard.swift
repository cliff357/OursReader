//
//  Dashboard.swift
//  OursReader
//
//  Created by Cliff Chan on 7/5/2024.
//

import SwiftUI

struct Dashboard: View {
    @StateObject private var pushNotificationViewModel = PushSettingListViewModel()
    @StateObject private var bookCacheManager = BookCacheManager.shared
    @State private var tabProgress: CGFloat = 0
    @State private var selectedTab: Tab? = .push
    @State private var selectedButtonListType: ButtonListType = .push_notification
    
    @State private var publicBooks: [CloudBook] = []
    @State private var isLoadingBooks = false
    @State private var isInsertingTestBooks = false
    @State private var showingImport = false
    @State private var isImportButtonPressed = false
    @State private var lockTabSelection = false
    
    // 🔧 新增：用戶名稱輸入相關狀態
    @State private var showingUserNameInput = false
    @State private var userName = ""
    @State private var hasCheckedUserName = false
    
    var body: some View {
        ZStack {
            ColorManager.shared.background.ignoresSafeArea()
            
            VStack(spacing: 15) {
                Spacer().frame(height: 15)
                CustomTabBar()
                
                GeometryReader { geometry in
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 0) {
                            PushSettingListView(viewModel: pushNotificationViewModel)
                                .id(Tab.push)
                                .containerRelativeFrame(.horizontal)

                            BooklistView(type: .widget)
                                .id(Tab.widget)
                                .containerRelativeFrame(.horizontal)

                            BooklistView(type: .ebook)
                                .id(Tab.ebook)
                                .containerRelativeFrame(.horizontal)
                        }
                        .scrollTargetLayout()
                        .offsetX { value in
                            if !lockTabSelection {
                                updateTabProgress(value, geometrySize: geometry.size)
                            }
                        }
                    }
                    .scrollPosition(id: $selectedTab)
                    .scrollIndicators(.hidden)
                    .scrollTargetBehavior(.paging)
                    .scrollClipDisabled()
                    .scrollDisabled(lockTabSelection)
                }
            }
        }
        .onAppear {
            // 🔧 新增：首次進入時檢查用戶名稱
            if !hasCheckedUserName {
                checkUserName()
                hasCheckedUserName = true
            }
            
            bookCacheManager.syncDownloadStatusFromLocalFiles()
            loadBooksData()
            
            NotificationCenter.default.addObserver(
                forName: CloudKitManager.booksDidChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                self.loadBooksData()
            }
        }
        .sheet(isPresented: $showingImport) {
            BookImportView {
                loadBooksData()
                isImportButtonPressed = false
                lockTabSelection = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = .ebook
                        selectedButtonListType = .ebook
                    }
                }
            }
        }
        // 🔧 新增：用戶名稱輸入 sheet
        .fullScreenCover(isPresented: $showingUserNameInput) {
            UserNameInputView(userName: $userName) {
                UserAuthModel.shared.nickName = userName
                Storage.save(Storage.Key.nickName, userName)
                showingUserNameInput = false
            }
        }
        .onChange(of: showingImport) { oldValue, newValue in
            if !newValue {
                isImportButtonPressed = false
                lockTabSelection = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = .ebook
                        selectedButtonListType = .ebook
                    }
                }
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if lockTabSelection && newValue != .ebook {
                DispatchQueue.main.async {
                    selectedTab = .ebook
                    selectedButtonListType = .ebook
                }
            }
        }
    }
    
    // 🔧 新增：檢查用戶名稱
    private func checkUserName() {
        let currentName = Storage.getString(Storage.Key.nickName) ?? ""
        if currentName.isEmpty {
            // 延遲一點顯示，讓 Dashboard 先完全載入
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                userName = ""
                showingUserNameInput = true
            }
        }
    }
    
    // 載入書籍數據 - 改為載入用戶書籍
    private func loadBooksData() {
        guard !isLoadingBooks else { return }
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            isLoadingBooks = false
            return
        }
        
        isLoadingBooks = true
        
        CloudKitManager.shared.fetchUserBooks(firebaseUserID: currentUser.uid) { result in
            DispatchQueue.main.async {
                self.isLoadingBooks = false
                switch result {
                case .success(let books):
                    self.publicBooks = books // 重用變量名，但現在是用戶書籍
                case .failure(let error):
                    print("❌ Failed to load books: \(error.localizedDescription)")
                    self.setupFallbackData()
                }
            }
        }
    }
    
    // 更新 fallback 數據說明
    private func setupFallbackData() {
        publicBooks = [] // 用戶沒有書籍時顯示空狀態
    }

    private func updateTabProgress(_ value: CGFloat, geometrySize: CGSize) {
        // 🔧 新增：當鎖定時直接返回
        guard !lockTabSelection else { return }
        
        let progress = -value / (geometrySize.width * CGFloat(Tab.allCases.count - 1))
        tabProgress = max(min(progress, 1), 0)

        let currentPage = Int(round(-value / geometrySize.width))
        switch currentPage {
        case 0:
            selectedButtonListType = .push_notification
        case 1:
            selectedButtonListType = .widget
        case 2:
            selectedButtonListType = .ebook
        default:
            break
        }
    }

    @ViewBuilder
    func CustomTabBar() -> some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                HStack(spacing: 10) {
                    Image(systemName: tab.systemImage)
                    Text(tab.name).font(.callout)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .contentShape(.capsule)
                .onTapGesture {
                    // 🔧 修正：當導入在進行中時，防止標籤切換
                    guard !lockTabSelection && !isImportButtonPressed else {
                        print("🔒 Tab switching locked during import")
                        return
                    }
                    
                    withAnimation(.snappy) {
                        selectedTab = tab
                        updateSelectedButtonListType(for: tab)
                    }
                }
            }
        }
        .background {
            GeometryReader { geometry in
                let capsuleWidth = geometry.size.width / CGFloat(Tab.allCases.count)
                Capsule()
                    .fill(ColorManager.shared.green1)
                    .frame(width: capsuleWidth)
                    .offset(x: tabProgress * (geometry.size.width - capsuleWidth))
            }
        }
        .background(Color.gray.opacity(0.1), in: .capsule)
        .padding(.horizontal, 15)
    }
    
    @ViewBuilder
    func BooklistView(type: ButtonListType) -> some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: GridItem(), count: 2), spacing: 10) { // 🔧 調整：增加垂直間距
                switch type {
                case .push_notification, .widget:
                    ForEach(widgetList, id: \.id) { widget in
                        RoundedRectangle(cornerRadius: 15)
                            .fill(type.color)
                            .frame(height: 100)
                            .overlay {
                                VStack(alignment: .leading) {
                                    Text(widget.name)
                                        .font(.headline)
                                        .foregroundColor(Color(hex: "FFFFFF"))
                                    Text(widget.actionCode)
                                        .font(.subheadline)
                                        .foregroundColor(Color(hex: "FFD741"))
                                }
                                .padding(15)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                    }

                case .ebook:
                    if isLoadingBooks {
                        // 顯示載入指示器
                        ForEach(0..<4, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 15)
                                .fill(type.color.opacity(0.3))
                                .frame(height: 150)
                                .overlay {
                                    VStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                        Text(LocalizedStringKey("general_loading"))
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.top, 4)
                                    }
                                }
                        }
                    } else {
                        if publicBooks.isEmpty {
                            // 🔧 移除加書按鈕，只保留導入按鈕
                            DashboardImportBookItem(color: type.color) {
                                isImportButtonPressed = true
                                lockTabSelection = true
                                
                                selectedTab = .ebook
                                selectedButtonListType = .ebook
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showingImport = true
                                }
                            }
                            
                            // 顯示空狀態
                            RoundedRectangle(cornerRadius: 15)
                                .fill(type.color.opacity(0.5))
                                .frame(height: 150)
                                .overlay {
                                    VStack {
                                        Image(systemName: "book.closed")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white.opacity(0.7))
                                        Text(String(localized: "dashboard_no_books_yet"))
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                        Text(String(localized: "dashboard_tap_import_to_start"))
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.5))
                                            .padding(.top, 2)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 150)
                                .overlay {
                                    VStack(spacing: 8) {
                                        Image(systemName: "arrow.down.doc.fill")
                                            .font(.system(size: 25))
                                            .foregroundColor(.gray)
                                        Text(String(localized: "book_import_title"))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.gray)
                                        Text(String(localized: "book_import_python_description"))
                                            .font(.caption2)
                                            .foregroundColor(.gray.opacity(0.8))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                        } else {
                            // 先顯示用戶書籍數據
                            ForEach(publicBooks, id: \.id) { userBook in
                                CloudBookGridItemWithCache(
                                    book: userBook, 
                                    color: type.color,
                                    cacheManager: bookCacheManager
                                )
                            }
                            
                            DashboardImportBookItem(color: type.color) {
                                isImportButtonPressed = true
                                lockTabSelection = true
                                
                                selectedTab = .ebook
                                selectedButtonListType = .ebook
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showingImport = true
                                }
                            }
                            .gridCellColumns(2)
                        }
                    }
                }
            }
            .padding(15)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }

    private func updateSelectedButtonListType(for tab: Tab) {
        switch tab {
        case .push:
            selectedButtonListType = .push_notification
        case .widget:
            selectedButtonListType = .widget
        case .ebook:
            selectedButtonListType = .ebook
        }
    }
}

// 新的 CloudBook 網格項目視圖
struct CloudBookGridItem: View {
    let book: CloudBook
    let color: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(color)
            .frame(height: 150)
            .overlay {
                VStack(alignment: .leading, spacing: 8) {
                    // 書籍封面圖片和標題區域 - 水平排列
                    HStack(alignment: .top, spacing: 8) {
                        // 🔧 修改：使用新的預設封面視圖
                        DummyBookCoverView()
                        
                        // 書籍標題 - 放在圖片右邊，可以顯示2行
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.name)
                                .font(.headline)
                                .foregroundColor(ColorManager.shared.red1)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                    
                    // 作者名 - 和簡介一樣的寬度和排版
                    Text(String(format: NSLocalizedString("book_by_author", comment: "Author name"), book.author))
                        .font(.caption)
                        .foregroundColor(ColorManager.shared.red1.opacity(0.8))
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                    
                    // 簡介放在下方
                    Text(book.introduction)
                        .font(.caption)
                        .foregroundColor(ColorManager.shared.red1.opacity(0.7))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
    }
}

// 🔧 修改：CloudBookGridItemWithCache，點擊未下載書籍時自動開始下載
struct CloudBookGridItemWithCache: View {
    let book: CloudBook
    let color: Color
    @ObservedObject var cacheManager: BookCacheManager
    @State private var navigateToDetail = false
    
    var body: some View {
        // 🔧 修正：使用 NavigationLink + isActive 來控制導航
        ZStack {
            NavigationLink(
                destination: destinationView,
                isActive: $navigateToDetail
            ) {
                EmptyView()
            }
            .hidden()
            
            Button(action: {
                handleBookTap()
            }) {
                bookCardView
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onAppear {
            print("📖 Book: \(book.name)")
            print("   ID: \(book.id)")
            print("   Downloaded: \(cacheManager.isBookDownloaded(book.id))")
            print("   Downloading: \(cacheManager.isBookDownloading(book.id))")
            print("   Content pages: \(book.content.count)")
        }
    }
    
    private var bookCardView: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(color)
            .frame(height: 150)
            .overlay {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        DummyBookCoverView()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.name)
                                .font(.headline)
                                .foregroundColor(ColorManager.shared.red1)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        
                        Spacer()
                        
                        DownloadStatusIcon(
                            book: book,
                            cacheManager: cacheManager
                        )
                    }
                    
                    Text(String(format: NSLocalizedString("book_by_author", comment: "Author name"), book.author))
                        .font(.caption)
                        .foregroundColor(ColorManager.shared.red1.opacity(0.8))
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                    
                    Text(book.introduction)
                        .font(.caption)
                        .foregroundColor(ColorManager.shared.red1.opacity(0.7))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
    }
    
    // 🔧 修正：處理點擊書籍卡片的邏輯
    private func handleBookTap() {
        if cacheManager.isBookDownloaded(book.id) {
            // 已下載：直接導航到詳情頁
            print("📚 Opening downloaded book: \(book.name)")
            navigateToDetail = true
        } else if cacheManager.isBookDownloading(book.id) {
            // 下載中：顯示提示
            print("⏳ Book is downloading, please wait...")
        } else {
            // 未下載：開始下載
            print("⬇️ Starting download for: \(book.name)")
            startDownload()
        }
    }
    
    // 🔧 修正：開始下載方法，下載完成後自動打開
    private func startDownload() {
        cacheManager.downloadBook(book) { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    print("✅ Download completed: \(book.name)")
                    print("   📍 Checking if book is now marked as downloaded...")
                    print("   ✓ Downloaded: \(cacheManager.isBookDownloaded(book.id))")
                    
                    // 觸覺反饋
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(.success)
                    
                    // 🔧 關鍵修正：延遲一下確保狀態更新，然後自動打開書籍
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if cacheManager.isBookDownloaded(book.id) {
                            print("   ✅ Opening book after successful download")
                            navigateToDetail = true
                        } else {
                            print("   ⚠️ Book not marked as downloaded after download completed")
                        }
                    }
                    
                case .failure(let error):
                    print("❌ Download failed: \(error.localizedDescription)")
                    // 錯誤反饋
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(.error)
                }
            }
        }
    }
    
    @ViewBuilder
    private var destinationView: some View {
        if let localBook = cacheManager.getLocalBook(book.id) {
            let _ = print("📚 [BookDetail] Loading from LOCAL cache: \(book.name)")
            let _ = print("   Book ID: \(localBook.id)")
            let _ = print("   Pages: \(localBook.totalPages)")
            BookDetailView(book: localBook)
                .accentColor(.black)
        } else {
            let _ = print("⚠️ [BookDetail] Book not found in cache")
            let _ = print("   Looking for ID: \(book.id)")
            let _ = print("   File exists: \(cacheManager.checkLocalFileExists(book.id))")
            let _ = print("   Marked as downloaded: \(cacheManager.isBookDownloaded(book.id))")
            
            // 🔧 顯示錯誤視圖而不是空視圖
            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text("Book not found")
                    .font(.headline)
                Text("Please try downloading again")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }
}

// 🔧 修改：DownloadStatusIcon - 點擊時阻止事件冒泡
struct DownloadStatusIcon: View {
    let book: CloudBook
    @ObservedObject var cacheManager: BookCacheManager
    @State private var downloadProgress: Double = 0.0
    
    var body: some View {
        Button(action: handleDownloadAction) {
            ZStack {
                if cacheManager.isBookDownloaded(book.id) {
                    // 已下載圖標
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ColorManager.shared.green1)
                } else if cacheManager.isBookDownloading(book.id) {
                    // 下載中圖標
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)
                        
                        Circle()
                            .trim(from: 0, to: downloadProgress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut, value: downloadProgress)
                    }
                } else {
                    // 未下載圖標
                    Image(systemName: "icloud.and.arrow.down")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            if cacheManager.isBookDownloading(book.id) {
                downloadProgress = cacheManager.getDownloadProgress(book.id)
            }
        }
    }
    
    private func handleDownloadAction() {
        // 🔧 修改：只在未下載且未下載中時才處理
        if !cacheManager.isBookDownloaded(book.id) && !cacheManager.isBookDownloading(book.id) {
            startDownload()
        }
    }
    
    private func startDownload() {
        cacheManager.downloadBook(book) { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    print("✅ Download icon triggered download successfully")
                    
                case .failure(let error):
                    print("❌ Download failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

// 🔧 修改：使用新的預設封面視圖
struct DummyBookCoverView: View {
    var body: some View {
        DefaultBookCoverView(width: 40, height: 50)
    }
}

// 新增 Dashboard 的「導入書籍」按鈕視圖
struct DashboardImportBookItem: View {
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            // 🔧 添加觸覺反饋和防重複點擊
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            onTap()
        }) {
            RoundedRectangle(cornerRadius: 15)
                .fill(color.opacity(0.8))
                .frame(height: 150)
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 40))
                            .foregroundColor(ColorManager.shared.red1)
                        Text(String(localized: "book_import_title"))
                            .font(.headline)
                            .foregroundColor(ColorManager.shared.red1)
                        
                        Text(String(localized: "book_import_from_json"))
                            .font(.caption)
                            .foregroundColor(ColorManager.shared.red1.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(ColorManager.shared.red1.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(false)
    }
}

#Preview {
    Dashboard()
}
