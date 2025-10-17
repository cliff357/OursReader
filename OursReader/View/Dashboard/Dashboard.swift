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
    @StateObject private var goldFingerManager = GoldFingerManager.shared
    @State private var tabProgress: CGFloat = 0
    @State private var selectedTab: Tab? = .push
    @State private var selectedButtonListType: ButtonListType = .push_notification
    
    @State private var publicBooks: [CloudBook] = []
    @State private var isLoadingBooks = false
    @State private var isInsertingTestBooks = false
    @State private var showingImport = false
    @State private var isImportButtonPressed = false
    @State private var lockTabSelection = false
    
    @State private var showingUserNameInput = false
    @State private var userName = ""
    @State private var hasCheckedUserName = false
    
    @State private var showComingSoon = false
    @State private var comingSoonMessage = ""
    
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
            
            if showComingSoon {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showComingSoon = false
                        }
                    }
                
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("Coming Soon")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(comingSoonMessage)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.9))
                )
                .padding(40)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
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
    
    private func checkUserName() {
        let currentName = Storage.getString(Storage.Key.nickName) ?? ""
        if currentName.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                userName = ""
                showingUserNameInput = true
            }
        }
    }
    
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
                    self.publicBooks = books
                case .failure(let error):
                    print("❌ Failed to load books: \(error.localizedDescription)")
                    self.setupFallbackData()
                }
            }
        }
    }
    
    private func setupFallbackData() {
        publicBooks = []
    }

    private func updateTabProgress(_ value: CGFloat, geometrySize: CGSize) {
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
                    guard !lockTabSelection && !isImportButtonPressed else {
                        print("🔒 Tab switching locked during import")
                        return
                    }
                    
                    if tab == .widget && !goldFingerManager.isWidgetUnlocked {
                        showComingSoonAlert(for: .widget)
                        return
                    }
                    
                    if tab == .ebook && !goldFingerManager.isEbookUnlocked {
                        showComingSoonAlert(for: .ebook)
                        return
                    }
                    
                    withAnimation(.snappy) {
                        selectedTab = tab
                        updateSelectedButtonListType(for: tab)
                    }
                }
                .onLongPressGesture(minimumDuration: 5.0) {
                    handleLongPress(for: tab)
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
            LazyVGrid(columns: Array(repeating: GridItem(), count: 2), spacing: 10) {
                switch type {
                case .push_notification:
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

                case .widget:
                    if goldFingerManager.isWidgetUnlocked {
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
                    } else {
                        EmptyLockedView(type: .widget)
                    }

                case .ebook:
                    if goldFingerManager.isEbookUnlocked {
                        if isLoadingBooks {
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
                                DashboardImportBookItem(color: type.color) {
                                    isImportButtonPressed = true
                                    lockTabSelection = true
                                    selectedTab = .ebook
                                    selectedButtonListType = .ebook
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        showingImport = true
                                    }
                                }
                                
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
                    } else {
                        EmptyLockedView(type: .ebook)
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
    
    private func showComingSoonAlert(for tab: Tab) {
        comingSoonMessage = tab == .widget ? 
            "Widget 功能即將推出\n敬請期待！" : 
            "電子書功能即將推出\n敬請期待！"
        
        withAnimation(.spring()) {
            showComingSoon = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showComingSoon = false
            }
        }
    }
    
    private func handleLongPress(for tab: Tab) {
        switch tab {
        case .ebook:
            if !goldFingerManager.isEbookUnlocked {
                goldFingerManager.unlockEbook()
                
                comingSoonMessage = "🎉 電子書功能已解鎖！"
                withAnimation(.spring()) {
                    showComingSoon = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showComingSoon = false
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.snappy) {
                            selectedTab = .ebook
                            updateSelectedButtonListType(for: .ebook)
                        }
                    }
                }
            }
            
        case .widget:
            if !goldFingerManager.isWidgetUnlocked {
                goldFingerManager.unlockWidget()
                
                comingSoonMessage = "🎉 Widget 功能已解鎖！"
                withAnimation(.spring()) {
                    showComingSoon = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showComingSoon = false
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.snappy) {
                            selectedTab = .widget
                            updateSelectedButtonListType(for: .widget)
                        }
                    }
                }
            }
            
        case .push:
            break
        }
    }
}

struct CloudBookGridItem: View {
    let book: CloudBook
    let color: Color
    
    var body: some View {
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
}

struct CloudBookGridItemWithCache: View {
    let book: CloudBook
    let color: Color
    @ObservedObject var cacheManager: BookCacheManager
    
    @State private var showingBookDetail = false
    
    var body: some View {
        Button(action: handleTap) {
            bookCardView(showDownloadIcon: true)
                .contentShape(Rectangle())
        }
        .buttonStyle(CardButtonStyle())
        .sheet(isPresented: $showingBookDetail) {
            if let localBook = cacheManager.getLocalBook(book.id) {
                NavigationView {
                    BookDetailView(book: localBook)
                }
            }
        }
        .onAppear {
            print("📖 Book: \(book.name)")
            print("   Downloaded: \(cacheManager.isBookDownloaded(book.id))")
            if let localBook = cacheManager.getLocalBook(book.id) {
                print("   ✅ Local book available with \(localBook.pages.count) pages")
            }
        }
    }
    
    private func handleTap() {
        if cacheManager.isBookDownloaded(book.id) {
            print("📚 Opening book detail: \(book.name)")
            showingBookDetail = true
        } else if cacheManager.isBookDownloading(book.id) {
            print("⏳ Already downloading...")
        } else {
            handleDownload()
        }
    }
    
    private func bookCardView(showDownloadIcon: Bool) -> some View {
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
                        
                        if showDownloadIcon {
                            downloadStatusView()
                        }
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
    
    @ViewBuilder
    private func downloadStatusView() -> some View {
        if cacheManager.isBookDownloaded(book.id) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(ColorManager.shared.green1)
        } else if cacheManager.isBookDownloading(book.id) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(0.8)
        } else {
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 20))
                .foregroundColor(.blue)
        }
    }
    
    private func handleDownload() {
        if cacheManager.isBookDownloading(book.id) {
            print("⏳ Already downloading...")
            return
        }
        
        print("⬇️ Start download: \(book.name)")
        cacheManager.downloadBook(book) { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    print("✅ Download completed: \(book.name)")
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(.success)
                    
                case .failure(let error):
                    print("❌ Download failed: \(error.localizedDescription)")
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(.error)
                }
            }
        }
    }
}

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DownloadStatusIcon: View {
    let book: CloudBook
    @ObservedObject var cacheManager: BookCacheManager
    @State private var downloadProgress: Double = 0.0
    
    var body: some View {
        Button(action: handleDownloadAction) {
            ZStack {
                if cacheManager.isBookDownloaded(book.id) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ColorManager.shared.green1)
                } else if cacheManager.isBookDownloading(book.id) {
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

struct DummyBookCoverView: View {
    var body: some View {
        DefaultBookCoverView(width: 40, height: 50)
    }
}

struct DashboardImportBookItem: View {
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
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

struct EmptyLockedView: View {
    let type: ButtonListType
    
    var body: some View {
        VStack {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 150)
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("Coming Soon")
                                .font(.headline)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                    }
            }
        }
    }
}

#Preview {
    Dashboard()
}
