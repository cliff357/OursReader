import Foundation
import CloudKit

class BookImportManager: ObservableObject {
    @Published var isImporting = false
    @Published var importStatus = ""
    @Published var alertMessage = ""
    @Published var recentFiles: [String] = []
    
    // 新增進度相關屬性
    @Published var uploadProgress: Double = 0.0
    @Published var currentFileName = ""
    @Published var showUploadProgress = false
    
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    init() {
        loadRecentFiles()
    }
    
    func importFromURLs(_ urls: [URL]) {
        isImporting = true
        showUploadProgress = true
        uploadProgress = 0.0
        importStatus = "準備導入..."
        
        var totalBooks = 0
        var successCount = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            for (urlIndex, url) in urls.enumerated() {
                // 獲取安全範圍資源訪問權限
                let accessing = url.startAccessingSecurityScopedResource()
                defer {
                    if accessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                // 更新當前文件名和進度
                DispatchQueue.main.async {
                    self.currentFileName = url.lastPathComponent
                    self.uploadProgress = Double(urlIndex) / Double(urls.count) * 0.2
                    self.importStatus = "正在讀取：\(url.lastPathComponent)"
                }
                
                do {
                    let data = try Data(contentsOf: url)
                    
                    DispatchQueue.main.async {
                        self.uploadProgress = Double(urlIndex) / Double(urls.count) * 0.2 + 0.1
                        self.importStatus = "正在解析 JSON..."
                    }
                    
                    let books = try JSONDecoder().decode([EbookData].self, from: data)
                    totalBooks += books.count
                    
                    for (bookIndex, book) in books.enumerated() {
                        DispatchQueue.main.async {
                            self.importStatus = "正在導入：\(book.title)"
                            // 計算總體進度：20% 讀取 + 80% 導入
                            let baseProgress = Double(urlIndex) / Double(urls.count) * 0.2 + 0.2
                            let bookProgress = (Double(bookIndex) / Double(books.count)) * 0.6 / Double(urls.count)
                            self.uploadProgress = baseProgress + bookProgress
                        }
                        
                        if self.importSingleBook(book) {
                            successCount += 1
                        }
                        
                        DispatchQueue.main.async {
                            self.importStatus = "已導入 \(successCount)/\(totalBooks) 本書..."
                        }
                    }
                    
                    // 記住最近使用的文件
                    DispatchQueue.main.async {
                        self.addToRecentFiles(url.lastPathComponent)
                    }
                    
                } catch {
                    print("導入文件失敗: \(error)")
                    DispatchQueue.main.async {
                        self.importStatus = "文件讀取失敗：\(error.localizedDescription)"
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.uploadProgress = 1.0
                self.importStatus = "導入完成！"
                
                // 1.5秒後隱藏進度
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.isImporting = false
                    self.showUploadProgress = false
                    self.uploadProgress = 0.0
                    self.alertMessage = "導入完成！成功導入 \(successCount)/\(totalBooks) 本書"
                    
                    // 發送通知更新書籍列表
                    NotificationCenter.default.post(name: CloudKitManager.booksDidChangeNotification, object: nil)
                }
            }
        }
    }
    
    func scanICloudDrive() {
        isImporting = true
        importStatus = "掃描 iCloud Drive..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 掃描文檔目錄和 iCloud 目錄
            let paths = [
                self.documentsPath,
                FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
            ].compactMap { $0 }
            
            var foundBooks = 0
            
            for path in paths {
                do {
                    let files = try FileManager.default.contentsOfDirectory(
                        at: path,
                        includingPropertiesForKeys: [.nameKey],
                        options: .skipsHiddenFiles
                    )
                    
                    let jsonFiles = files.filter { $0.pathExtension.lowercased() == "json" }
                    
                    for file in jsonFiles {
                        DispatchQueue.main.async {
                            self.importStatus = "發現文件：\(file.lastPathComponent)"
                        }
                        
                        if self.importFromFile(file) {
                            foundBooks += 1
                        }
                    }
                } catch {
                    print("掃描目錄失敗: \(path) - \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.isImporting = false
                if foundBooks > 0 {
                    self.alertMessage = "掃描完成！發現並導入了 \(foundBooks) 本書"
                    
                    // 發送通知更新書籍列表
                    NotificationCenter.default.post(name: CloudKitManager.booksDidChangeNotification, object: nil)
                } else {
                    self.alertMessage = "未找到任何 JSON 書籍文件"
                }
            }
        }
    }
    
    private func importFromFile(_ url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let books = try JSONDecoder().decode([EbookData].self, from: data)
            
            var successCount = 0
            for book in books {
                if importSingleBook(book) {
                    successCount += 1
                }
            }
            
            if successCount > 0 {
                DispatchQueue.main.async {
                    self.addToRecentFiles(url.lastPathComponent)
                }
                return true
            }
        } catch {
            print("導入文件失敗: \(url) - \(error)")
        }
        
        return false
    }
    
    private func importSingleBook(_ bookData: EbookData) -> Bool {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            return false
        }
        
        // 轉換為 CloudBook 格式
        let cloudBook = CloudBook(
            recordID: nil,
            name: bookData.title,
            introduction: bookData.instruction,
            coverURL: bookData.coverImage, // 將 coverImage 作為 URL 使用
            author: bookData.author,
            content: bookData.pages,
            firebaseBookID: bookData.id,
            coverImage: nil, // 封面圖片留空，後續可以加載
            currentPage: bookData.currentPage,
            bookmarkedPages: bookData.bookmarkedPages
        )
        
        var success = false
        let semaphore = DispatchSemaphore(value: 0)
        
        CloudKitManager.shared.saveUserBook(
            cloudBook,
            firebaseUserID: currentUser.uid
        ) { result in
            switch result {
            case .success:
                success = true
                print("✅ 成功導入書籍：\(bookData.title)")
            case .failure(let error):
                print("❌ 保存書籍失敗: \(bookData.title) - \(error)")
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return success
    }
    
    private func addToRecentFiles(_ fileName: String) {
        if !self.recentFiles.contains(fileName) {
            self.recentFiles.insert(fileName, at: 0)
            if self.recentFiles.count > 5 {
                self.recentFiles.removeLast()
            }
            self.saveRecentFiles()
        }
    }
    
    private func loadRecentFiles() {
        if let data = UserDefaults.standard.data(forKey: "RecentImportFiles"),
           let files = try? JSONDecoder().decode([String].self, from: data) {
            recentFiles = files
        }
    }
    
    private func saveRecentFiles() {
        if let data = try? JSONEncoder().encode(recentFiles) {
            UserDefaults.standard.set(data, forKey: "RecentImportFiles")
        }
    }
    
    func importRecentFile(_ fileName: String) {
        // 在常見位置尋找文件
        let searchPaths = [
            documentsPath.appendingPathComponent(fileName),
            FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents").appendingPathComponent(fileName)
        ].compactMap { $0 }
        
        for path in searchPaths {
            if FileManager.default.fileExists(atPath: path.path) {
                importFromURLs([path])
                return
            }
        }
        
        alertMessage = "找不到文件：\(fileName)"
    }
}

// 用於解碼導入的書籍數據結構
struct EbookData: Codable {
    let id: String
    let title: String
    let author: String
    let coverImage: String
    let instruction: String
    let pages: [String]
    let totalPages: Int
    let currentPage: Int
    let bookmarkedPages: [Int]
}
