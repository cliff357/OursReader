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
    
    // 新增用於存儲 CloudBook 數據的狀態
    @State private var publicBooks: [CloudBook] = []
    @State private var isLoadingBooks = false

    // 新增狀態變量
    @State private var isInsertingTestBooks = false
    @State private var showingImport = false
    
    // 🔧 新增：用於防止導入時頁面跳轉的狀態
    @State private var isImportButtonPressed = false
    @State private var lockTabSelection = false
    
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
                            // 🔧 修正：當正在導入時，不更新 tab progress
                            if !lockTabSelection {
                                updateTabProgress(value, geometrySize: geometry.size)
                            }
                        }
                    }
                    .scrollPosition(id: $selectedTab)
                    .scrollIndicators(.hidden)
                    .scrollTargetBehavior(.paging)
                    .scrollClipDisabled()
                    // 🔧 新增：當鎖定時禁用滾動
                    .scrollDisabled(lockTabSelection)
                }
            }
        }
        .onAppear {
            loadBooksData()
        }
        .sheet(isPresented: $showingImport) {
            BookImportView {
                // 🔧 修正：導入完成後的處理
                loadBooksData()
                
                // 重置狀態
                isImportButtonPressed = false
                lockTabSelection = false
                
                // 確保停留在 E-Book 頁面
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = .ebook
                        selectedButtonListType = .ebook
                    }
                }
            }
        }
        // 🔧 修正：監控導入狀態變化
        .onChange(of: showingImport) { oldValue, newValue in
            if !newValue {
                // 當導入 sheet 關閉時
                isImportButtonPressed = false
                lockTabSelection = false
                
                // 碮保回到 E-Book 頁面
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = .ebook
                        selectedButtonListType = .ebook
                    }
                }
            }
        }
        // 🔧 新增：監控 selectedTab 變化，防止意外跳轉
        .onChange(of: selectedTab) { oldValue, newValue in
            if lockTabSelection && newValue != .ebook {
                // 如果正在導入過程中且不是 ebook 標籤，強制回到 ebook
                DispatchQueue.main.async {
                    selectedTab = .ebook
                    selectedButtonListType = .ebook
                }
            }
        }
    }
    
    // 載入書籍數據 - 改為載入用戶書籍
    private func loadBooksData() {
        guard !isLoadingBooks else { return }
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            print("No user logged in, showing empty state")
            isLoadingBooks = false
            return
        }
        
        isLoadingBooks = true
        print("Loading user books for: \(currentUser.uid)")
        
        CloudKitManager.shared.fetchUserBooks(firebaseUserID: currentUser.uid) { result in
            DispatchQueue.main.async {
                self.isLoadingBooks = false
                switch result {
                case .success(let books):
                    print("Successfully loaded \(books.count) user books")
                    self.publicBooks = books // 重用變量名，但現在是用戶書籍
                case .failure(let error):
                    print("Failed to load user books: \(error.localizedDescription)")
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
            LazyVGrid(columns: Array(repeating: GridItem(), count: 2)) {
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
                                        Text("Loading...")
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
                                print("🔥 DashboardImportBookItem onTap called")
                                
                                // 🔧 關鍵修正：立即鎖定標籤切換
                                isImportButtonPressed = true
                                lockTabSelection = true
                                
                                // 確保當前在 E-Book 頁面
                                selectedTab = .ebook
                                selectedButtonListType = .ebook
                                
                                // 延遲顯示導入界面，避免狀態衝突
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    print("🔥 Showing import sheet")
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
                            
                            // 🔧 新增一個額外的空狀態卡片說明
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
                            
                            // 🔧 移除加書按鈕，只保留導入按鈕
                            DashboardImportBookItem(color: type.color) {
                                print("🔥 DashboardImportBookItem onTap called (with books)")
                                
                                // 🔧 關鍵修正：立即鎖定標籤切換
                                isImportButtonPressed = true
                                lockTabSelection = true
                                
                                // 確保當前在 E-Book 頁面
                                selectedTab = .ebook
                                selectedButtonListType = .ebook
                                
                                // 延遲顯示導入界面
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    print("🔥 Showing import sheet (with books)")
                                    showingImport = true
                                }
                            }
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

// 🔧 修改 CloudBookGridItemWithCache，加入下載狀態指示
struct CloudBookGridItemWithCache: View {
    let book: CloudBook
    let color: Color
    @ObservedObject var cacheManager: BookCacheManager
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationLink(destination: destinationView) {
            RoundedRectangle(cornerRadius: 15)
                .fill(color)
                .frame(height: 150)
                .overlay {
                    VStack(alignment: .leading, spacing: 8) {
                        // 書籍封面圖片和標題區域
                        HStack(alignment: .top, spacing: 8) {
                            DummyBookCoverView()
                            
                            // 書籍標題
                            VStack(alignment: .leading, spacing: 4) {
                                Text(book.name)
                                    .font(.headline)
                                    .foregroundColor(ColorManager.shared.red1)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                            
                            Spacer()
                            
                            // 🔧 新增：下載狀態指示器
                            if let bookID = book.firebaseBookID, UserAuthModel.shared.isBookDownloaded(bookID: bookID) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(ColorManager.shared.green1)
                            }
                        }
                        
                        // 作者名
                        Text(String(format: NSLocalizedString("book_by_author", comment: "Author name"), book.author))
                            .font(.caption)
                            .foregroundColor(ColorManager.shared.red1.opacity(0.8))
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                        
                        // 簡介
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
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var destinationView: some View {
        if let localBook = cacheManager.getLocalBook(book.id) {
            BookDetailView(book: localBook)
                .accentColor(.black)
        } else {
            BookDetailView(book: book.toEbook())
                .accentColor(.black)
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
        // 🔧 添加防止重複點擊的 disabled 狀態（可選）
        .disabled(false) // 你可以根據需要添加狀態管理
    }
}

// 下載狀態圖標組件
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
                        .foregroundColor(.green)
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
        if cacheManager.isBookDownloaded(book.id) {
            // 已下載：可選擇刪除本地副本
            showDeleteConfirmation()
        } else if !cacheManager.isBookDownloading(book.id) {
            // 未下載且不在下載中：開始下載
            startDownload()
        }
        // 下載中時不執行任何操作
    }
    
    private func startDownload() {
        print("🔽 開始下載書籍：\(book.name)")
        
        cacheManager.downloadBook(book) { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    print("✅ 書籍下載完成：\(book.name)")
                    // 可以顯示成功提示
                    
                case .failure(let error):
                    print("❌ 書籍下載失敗：\(error.localizedDescription)")
                    // 顯示錯誤提示
                }
            }
        }
    }
    
    private func showDeleteConfirmation() {
        // 實現刪除確認對話框
        // 這裡可以使用 Alert 或 ActionSheet
    }
}

#Preview {
    Dashboard()
}
