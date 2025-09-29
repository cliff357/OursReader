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
    
    // 載入書籍數據 - 添加錯誤處理
    private func loadBooksData() {
        guard !isLoadingBooks else { return } // 防止重複載入
        
        isLoadingBooks = true
        print("Loading books data...")
        
        CloudKitManager.shared.fetchPublicBooks { result in
            DispatchQueue.main.async {
                self.isLoadingBooks = false
                switch result {
                case .success(let books):
                    print("Successfully loaded \(books.count) books")
                    self.publicBooks = books
                case .failure(let error):
                    print("Failed to load books: \(error.localizedDescription)")
                    // 設置一些預設數據以便測試
                    self.setupFallbackData()
                }
            }
        }
    }
    
    // 添加 fallback 數據
    private func setupFallbackData() {
        publicBooks = [
            CloudBook(
                recordID: nil,
                name: "Fallback Book 1",
                introduction: "This is a fallback book for testing",
                coverURL: nil,
                author: "Test Author",
                content: ["Chapter 1: Test content"],
                firebaseBookID: nil,
                coverImage: nil
            ),
            CloudBook(
                recordID: nil,
                name: "Fallback Book 2", 
                introduction: "Another fallback book",
                coverURL: nil,
                author: "Test Author 2",
                content: ["Chapter 1: More test content"],
                firebaseBookID: nil,
                coverImage: nil
            )
        ]
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
                    } else if publicBooks.isEmpty {
                        // 顯示空狀態
                        ForEach(0..<2, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 15)
                                .fill(type.color.opacity(0.5))
                                .frame(height: 150)
                                .overlay {
                                    VStack {
                                        Image(systemName: "book.closed")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white.opacity(0.7))
                                        Text("No books available")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                            .padding(.top, 4)
                                    }
                                }
                        }
                    } else {
                        // 使用 CloudBook 數據 - 恢復 NavigationLink
                        ForEach(publicBooks, id: \.id) { cloudBook in
                            NavigationLink(destination: BookDetailView(book: cloudBook.toEbook())) {
                                CloudBookGridItem(book: cloudBook, color: type.color)
                            }
                            .buttonStyle(PlainButtonStyle())
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
                    // 書籍封面圖片區域
                    HStack {
                        if let coverImage = book.coverImage {
                            Image(uiImage: coverImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 50)
                                .cornerRadius(4)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 40, height: 50)
                                .cornerRadius(4)
                                .overlay(
                                    Image(systemName: "book.closed")
                                        .foregroundColor(.white)
                                        .font(.system(size: 16))
                                )
                        }
                        Spacer()
                    }
                    
                    // 書籍信息
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text("by \(book.author)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(book.introduction)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
    }
}

#Preview {
    Dashboard()
}
