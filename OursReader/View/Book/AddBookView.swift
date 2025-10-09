import SwiftUI
import PhotosUI

// MARK: - AddBook 內容實現
struct AddBookContent: BaseSheetContent, View {
    @Binding private var bookTitle: String
    @Binding private var bookAuthor: String
    @Binding private var bookIntroduction: String
    @Binding private var bookContent: String
    @Binding private var selectedImage: PhotosPickerItem?
    @Binding private var bookCoverImage: UIImage?
    @Binding private var isUploading: Bool
    @Binding private var showingAlert: Bool
    @Binding private var alertMessage: String
    
    let onBookAdded: (CloudBook) -> Void
    
    init(
        bookTitle: Binding<String>,
        bookAuthor: Binding<String>,
        bookIntroduction: Binding<String>,
        bookContent: Binding<String>,
        selectedImage: Binding<PhotosPickerItem?>,
        bookCoverImage: Binding<UIImage?>,
        isUploading: Binding<Bool>,
        showingAlert: Binding<Bool>,
        alertMessage: Binding<String>,
        onBookAdded: @escaping (CloudBook) -> Void
    ) {
        self._bookTitle = bookTitle
        self._bookAuthor = bookAuthor
        self._bookIntroduction = bookIntroduction
        self._bookContent = bookContent
        self._selectedImage = selectedImage
        self._bookCoverImage = bookCoverImage
        self._isUploading = isUploading
        self._showingAlert = showingAlert
        self._alertMessage = alertMessage
        self.onBookAdded = onBookAdded
    }
    
    var title: String { "Add New Book" }
    var primaryButtonTitle: String { 
        isUploading ? "Uploading..." : "Create Book" 
    }
    var isFormValid: Bool {
        !bookTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !bookAuthor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !bookContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isUploading
    }
    
    var primaryButtonAction: () -> Void { uploadBook }
    
    var content: AnyView {
        AnyView(
            VStack(spacing: 20) {
                // 封面圖片選擇區域
                coverImageSection
                
                // 書籍資訊輸入區域
                SheetInputSection(
                    title: "Book Title",
                    placeholder: "Enter book title",
                    text: $bookTitle,
                    isRequired: true
                )
                
                SheetInputSection(
                    title: "Author",
                    placeholder: "Enter author name",
                    text: $bookAuthor,
                    isRequired: true
                )
                
                SheetInputSection(
                    title: "Introduction",
                    placeholder: "Enter book introduction",
                    text: $bookIntroduction,
                    isMultiline: true
                )
                
                SheetInputSection(
                    title: "Book Content",
                    placeholder: "Enter book content...",
                    text: $bookContent,
                    isRequired: true,
                    isMultiline: true,
                    helperText: "Separate chapters/pages with '---' on a new line"
                )
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                Task {
                    if let newValue = newValue {
                        await loadImage(from: newValue)
                    }
                }
            }
            .alert("Upload Status", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        // 這裡不能直接 dismiss，需要通過其他方式處理
                    }
                }
            } message: {
                Text(alertMessage)
            }
        )
    }
    
    // 需要明確實現 View 協議的 body
    var body: some View {
        content
    }
    
    // MARK: - 封面圖片選擇區域
    private var coverImageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Book Cover")
                .font(.headline)
                .foregroundColor(.black)
            
            HStack {
                // 圖片預覽
                if let image = bookCoverImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 140)
                        .cornerRadius(8)
                        .shadow(radius: 3)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 140)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                                Text("No Image")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                }
                
                // 操作按鈕
                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker(
                        selection: $selectedImage,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text("Choose Cover Image")
                            .foregroundColor(.white)
                            .padding()
                            .background(ColorManager.shared.red1)
                            .cornerRadius(8)
                    }
                    
                    if bookCoverImage != nil {
                        Button("Remove Image") {
                            bookCoverImage = nil
                            selectedImage = nil
                        }
                        .foregroundColor(.red)
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - 輔助方法
    private func loadImage(from item: PhotosPickerItem) async {
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            await MainActor.run {
                self.bookCoverImage = image
            }
        }
    }
    
    private func uploadBook() {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            alertMessage = "Please log in to create books"
            showingAlert = true
            return
        }
        
        isUploading = true
        
        // ...existing upload logic...
        let contentPages = bookContent.components(separatedBy: "---")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let finalContent = contentPages.isEmpty ? [bookContent] : contentPages
        
        let newBook = CloudBook(
            recordID: nil,
            name: bookTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            introduction: bookIntroduction.trimmingCharacters(in: .whitespacesAndNewlines),
            coverURL: nil,
            author: bookAuthor.trimmingCharacters(in: .whitespacesAndNewlines),
            content: finalContent,
            firebaseBookID: nil,
            coverImage: bookCoverImage,
            currentPage: 0,
            bookmarkedPages: []
        )
        
        CloudKitManager.shared.saveUserBook(newBook, firebaseUserID: currentUser.uid) { result in
            DispatchQueue.main.async {
                self.isUploading = false
                
                switch result {
                case .success(let recordName):
                    self.alertMessage = "Book created successfully! ID: \(recordName)"
                    self.showingAlert = true
                    
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                    
                    self.onBookAdded(newBook)
                    
                case .failure(let error):
                    self.alertMessage = "Failed to create book: \(error.localizedDescription)"
                    self.showingAlert = true
                    
                    let errorFeedback = UINotificationFeedbackGenerator()
                    errorFeedback.notificationOccurred(.error)
                }
            }
        }
    }
}

// MARK: - AddBookView 使用基類
struct AddBookView: View {
    @State private var bookTitle = ""
    @State private var bookAuthor = ""
    @State private var bookIntroduction = ""
    @State private var bookContent = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var bookCoverImage: UIImage?
    @State private var isUploading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let onBookAdded: (CloudBook) -> Void
    
    var body: some View {
        BaseSheetView(
            sheetContent: AddBookContent(
                bookTitle: $bookTitle,
                bookAuthor: $bookAuthor,
                bookIntroduction: $bookIntroduction,
                bookContent: $bookContent,
                selectedImage: $selectedImage,
                bookCoverImage: $bookCoverImage,
                isUploading: $isUploading,
                showingAlert: $showingAlert,
                alertMessage: $alertMessage,
                onBookAdded: onBookAdded
            )
        )
    }
}

#Preview {
    AddBookView { _ in
        print("Book added")
    }
}
