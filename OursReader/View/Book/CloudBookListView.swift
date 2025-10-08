import SwiftUI

struct CloudBookListView: View {
    @State private var books: [CloudBook] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAddBook = false // 新增狀態
    @State private var showingImport = false // 新增導入狀態
    
    var onAddBookTapped: (() -> Void)? 
    
    var body: some View {
        ZStack {
            ColorManager.shared.background.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else if let errorMessage = errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                        .padding()
                    
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Retry") {
                        loadBooks()
                    }
                    .padding()
                    .background(ColorManager.shared.red1)
                    .foregroundColor(ColorManager.shared.rice_white)
                    .cornerRadius(10)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 20) {
                        // 先顯示現有書籍
                        ForEach(books) { book in
                            NavigationLink(destination: BookDetailView(book: book.toEbook())
                                .accentColor(.black)) {
                                BookItemView(book: book)
                            }
                        }
                        
                        // 將「加書」按鈕移到最底部
                        AddBookItemView {
                            showingAddBook = true
                        }
                        
                        // 新增「導入」按鈕
                        ImportBookItemView {
                            showingImport = true
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("My Books")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingImport = true
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.black)
                }
            }
        }
        .onAppear {
            loadBooks()
        }
        .refreshable {
            loadBooks()
        }
        .onReceive(NotificationCenter.default.publisher(for: CloudKitManager.booksDidChangeNotification)) { _ in
            loadBooks()
        }
        .sheet(isPresented: $showingAddBook) {
            AddBookView { newBook in
                // 書籍添加成功後重新載入列表
                loadBooks()
            }
        }
        .sheet(isPresented: $showingImport) {
            BookImportView {
                // 書籍導入成功後重新載入列表
                loadBooks()
            }
        }
    }
    
    private func loadBooks() {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            errorMessage = "Please log in to view your books"
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        CloudKitManager.shared.fetchUserBooks(firebaseUserID: currentUser.uid) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let fetchedBooks):
                    self.books = fetchedBooks
                    
                case .failure(let error):
                    self.errorMessage = "Failed to load books: \(error.localizedDescription)"
                }
            }
        }
    }
}

// Book item view for grid display
struct BookItemView: View {
    let book: CloudBook
    @State private var coverImage: UIImage?
    @State private var isLoadingImage = true
    
    var body: some View {
        VStack {
            if let image = coverImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 200)
                    .cornerRadius(8)
                    .shadow(radius: 3)
            } else if isLoadingImage {
                Rectangle()
                    .fill(ColorManager.shared.dark_brown.opacity(0.1))
                    .frame(width: 140, height: 200)
                    .cornerRadius(8)
                    .overlay(ProgressView())
            } else {
                Rectangle()
                    .fill(ColorManager.shared.dark_brown.opacity(0.2))
                    .frame(width: 140, height: 200)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(ColorManager.shared.dark_brown.opacity(0.7))
                    )
            }
            
            Text(book.name)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(ColorManager.shared.dark_brown)
                .frame(width: 140)
                .padding(.top, 4)
            
            Text(book.author)
                .font(.caption)
                .foregroundColor(ColorManager.shared.dark_brown2)
        }
        .onAppear {
            loadCoverImage()
        }
    }
    
    private func loadCoverImage() {
        if coverImage != nil {
            isLoadingImage = false
            return
        }
        
        // 先嘗試從 book 的 coverImage 屬性載入
        if let existingImage = book.coverImage {
            self.coverImage = existingImage
            isLoadingImage = false
            return
        }
        
        // 嘗試從 coverURL 載入
        if let coverURL = book.coverURL {
            CloudKitManager.shared.loadCoverImage(
                recordName: coverURL,
                isPublic: true
            ) { result in
                DispatchQueue.main.async {
                    self.isLoadingImage = false
                    
                    switch result {
                    case .success(let image):
                        self.coverImage = image
                    case .failure(let error):
                        print("Failed to load cover image: \(error.localizedDescription)")
                        self.loadFallbackImage()
                    }
                }
            }
        } else {
            // 沒有 coverURL，直接載入 fallback 圖片
            isLoadingImage = false
            loadFallbackImage()
        }
    }
    
    private func loadFallbackImage() {
        // 嘗試從 firebaseBookID 找到對應的本地書籍圖片
        if let firebaseBookID = book.firebaseBookID,
           let localBook = ebookList.first(where: { $0.id == firebaseBookID }),
           let localImage = UIImage(named: localBook.coverImage) {
            self.coverImage = localImage
        } else {
            // 使用預設封面圖片
            let defaultImages = ["cover_image_1", "cover_image_2", "cover_image_3"]
            let randomImage = defaultImages.randomElement() ?? "cover_image_1"
            self.coverImage = UIImage(named: randomImage)
        }
    }
}

// 新增「加書」按鈕視圖
struct AddBookItemView: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ColorManager.shared.green1.opacity(0.1)) // 背景色改為 green1
                    .frame(width: 140, height: 200)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(ColorManager.shared.green1) // 改為 green1
                            
                            Text("Add Book")
                                .font(.headline)
                                .foregroundColor(ColorManager.shared.green1) // 改為 green1
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ColorManager.shared.green1, style: StrokeStyle(lineWidth: 2, dash: [8, 4])) // 邊框改為 green1
                    )
                
                Text("Create New Book")
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorManager.shared.green1) // 改為 green1
                    .frame(width: 140)
                    .padding(.top, 4)
                
                Text("Tap to add")
                    .font(.caption)
                    .foregroundColor(ColorManager.shared.green1.opacity(0.7)) // 改為 green1，保持透明度
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 新增「導入書籍」按鈕視圖
struct ImportBookItemView: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ColorManager.shared.red1.opacity(0.1))
                    .frame(width: 140, height: 200)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.system(size: 40))
                                .foregroundColor(ColorManager.shared.red1)
                            
                            Text("Import Books")
                                .font(.headline)
                                .foregroundColor(ColorManager.shared.red1)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ColorManager.shared.red1, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    )
                
                Text("Import from Files")
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorManager.shared.red1)
                    .frame(width: 140)
                    .padding(.top, 4)
                
                Text("JSON format")
                    .font(.caption)
                    .foregroundColor(ColorManager.shared.red1.opacity(0.7))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CloudBookListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CloudBookListView()
        }
    }
}
