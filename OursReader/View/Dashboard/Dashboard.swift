//
//  Dashboard.swift
//  OursReader
//
//  Created by Cliff Chan on 7/5/2024.
//

import SwiftUI

struct Dashboard: View {
    @StateObject private var pushNotificationViewModel = PushSettingListViewModel()
    @State private var tabProgress: CGFloat = 0
    @State private var selectedTab: Tab? = .push  // 設置默認值
    @State private var selectedButtonListType: ButtonListType = .push_notification
    
    // 新增用於存儲 CloudBook 數據的狀態
    @State private var publicBooks: [CloudBook] = []
    @State private var isLoadingBooks = false

    // 新增狀態變量
    @State private var isInsertingTestBooks = false
    
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
                            updateTabProgress(value, geometrySize: geometry.size)
                        }
                    }
                    .scrollPosition(id: $selectedTab)
                    .scrollIndicators(.hidden)
                    .scrollTargetBehavior(.paging)
                    .scrollClipDisabled()
                }
            }
        }
        .onAppear {
            loadBooksData()
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
                    withAnimation(.snappy) {
                        selectedTab = tab
                        updateSelectedButtonListType(for: tab)
                    }
                }
                // 添加長按手勢，只在 E-Book tab 上有效
                .onLongPressGesture(minimumDuration: 1.0) {
                    if tab == .ebook {
                        insertTestBooks()
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
        // 添加載入覆蓋層
        .overlay {
            if isInsertingTestBooks {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                    Text("正在添加測試書籍...")
                        .font(.caption)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(20)
                .transition(.opacity.combined(with: .scale))
            }
        }
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
                            // 如果沒有書籍，顯示「加書」按鈕和空狀態
                            DashboardAddBookItemWithSheet(color: type.color) {
                                // 重新載入書籍數據
                                loadBooksData()
                            }
                            
                            // 顯示空狀態（除了加書按鈕）
                            RoundedRectangle(cornerRadius: 15)
                                .fill(type.color.opacity(0.5))
                                .frame(height: 150)
                                .overlay {
                                    VStack {
                                        Image(systemName: "book.closed")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white.opacity(0.7))
                                        Text("No books yet")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                        Text("Long press E-Book tab to add test books!")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.5))
                                            .padding(.top, 2)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                        } else {
                            // 先顯示用戶書籍數據 - 移除數量限制
                            ForEach(publicBooks, id: \.id) { userBook in // 移除 .prefix(5) 限制，顯示所有書籍
                                NavigationLink(destination: BookDetailView(book: userBook.toEbook())
                                    .accentColor(.black)) {
                                    CloudBookGridItem(book: userBook, color: type.color)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // 將「加書」按鈕放在最後
                            DashboardAddBookItemWithSheet(color: type.color) {
                                // 重新載入書籍數據
                                loadBooksData()
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

    // 新增插入測試書籍的方法
    private func insertTestBooks() {
        guard !isInsertingTestBooks else { return }
        
        print("📚 User triggered test books insertion via long press")
        
        // 檢查是否有登入用戶
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            print("⚠️ No user logged in, cannot insert test books")
            return
        }
        
        isInsertingTestBooks = true
        
        // 給用戶觸覺反饋
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 插入測試書籍
        CloudKitTestHelper.shared.insertTestBooksToCloud()
        
        // 2秒後停止載入狀態並重新載入書籍
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isInsertingTestBooks = false
            
            // 重新載入書籍數據
            self.loadBooksData()
            
            // 成功觸覺反饋
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
            print("✅ Test books insertion completed!")
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
                        // 封面圖片
                        if let coverImage = book.coverImage {
                            Image(uiImage: coverImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 50)
                                .cornerRadius(4)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(ColorManager.shared.red1.opacity(0.3))
                                .frame(width: 40, height: 50)
                                .cornerRadius(4)
                                .overlay(
                                    Image(systemName: "book.closed")
                                        .foregroundColor(ColorManager.shared.red1)
                                        .font(.system(size: 16))
                                )
                        }
                        
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
                    Text("by \(book.author)")
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

// 新增 Dashboard 的「加書」按鈕視圖
struct DashboardAddBookItem: View {
    let color: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(color.opacity(0.8))
            .frame(height: 150)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    
                    Text("Add Book")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Create your own book")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
            )
    }
}

// 新增帶有 Sheet 的「加書」按鈕視圖
struct DashboardAddBookItemWithSheet: View {
    let color: Color
    let onBookAdded: () -> Void
    @State private var showingAddBook = false
    
    var body: some View {
        Button(action: {
            showingAddBook = true
        }) {
            RoundedRectangle(cornerRadius: 15)
                .fill(color.opacity(0.8))
                .frame(height: 150)
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(ColorManager.shared.green1) // 改為 green1
                        
                        Text("Add Book")
                            .font(.headline)
                            .foregroundColor(ColorManager.shared.green1) // 改為 green1
                        
                        Text("Create your own book")
                            .font(.caption)
                            .foregroundColor(ColorManager.shared.green1.opacity(0.8)) // 改為 green1，保持透明度
                            .multilineTextAlignment(.center)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(ColorManager.shared.green1.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [10, 5])) // 邊框也改為 green1
                )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingAddBook) {
            AddBookView { newBook in
                // 書籍添加成功後通知父視圖
                onBookAdded()
            }
        }
    }
}

#Preview {
    Dashboard()
}
