import SwiftUI

struct CloudBookListView: View {
    enum BookSource {
        case publicBooks
        case privateBooks
    }
    
    @State private var books: [CloudBook] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    let source: BookSource
    var onAddBookTapped: (() -> Void)? // 新增回調
    
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
            } else if books.isEmpty {
                VStack {
                    Image(systemName: "book.closed")
                        .font(.system(size: 50))
                        .padding()
                    
                    Text(source == .publicBooks ? 
                         "No public books available yet" : 
                         "You don't have any books yet")
                        .multilineTextAlignment(.center)
                }
                .foregroundColor(ColorManager.shared.dark_brown)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 20) {
                        ForEach(books) { book in
                            NavigationLink(destination: BookDetailView(book: book.toEbook())) {
                                BookItemView(book: book)
                            }
                        }
                    }
                    .padding()
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
    }
    
    private func loadBooks() {
        isLoading = true
        errorMessage = nil
        
        let completion: (Result<[CloudBook], Error>) -> Void = { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let fetchedBooks):
                    self.books = fetchedBooks
                    self.loadReadingProgress()
                    
                case .failure(let error):
                    self.errorMessage = "Failed to load books: \(error.localizedDescription)"
                }
            }
        }
        
        if source == .publicBooks {
            CloudKitManager.shared.fetchPublicBooks(completion: completion)
        } else {
            CloudKitManager.shared.fetchPrivateBooks(completion: completion)
        }
    }
    
    private func loadReadingProgress() {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            return
        }
        
        for (index, book) in books.enumerated() {
            CloudKitManager.shared.fetchReadingProgress(
                bookID: book.id,
                firebaseUserID: currentUser.uid
            ) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let progress):
                        self.books[index].currentPage = progress.currentPage
                        self.books[index].bookmarkedPages = progress.bookmarkedPages
                        
                    case .failure(let error):
                        print("Failed to load reading progress: \(error.localizedDescription)")
                    }
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

struct CloudBookListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CloudBookListView(source: .publicBooks)
        }
    }
}
