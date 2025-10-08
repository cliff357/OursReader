import SwiftUI
import UniformTypeIdentifiers

struct BookImportView: View {
    @StateObject private var importManager = BookImportManager()
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingAddBook = false
    @Environment(\.dismiss) private var dismiss
    
    let onBooksImported: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 標題
                VStack(spacing: 10) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 60))
                        .foregroundColor(ColorManager.shared.red1)
                    
                    Text("導入書籍")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("選擇一種方式來導入你的書籍")
                        .font(.body)
                        .foregroundColor(.black.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                // 導入選項
                VStack(spacing: 15) {
                    // 文件選擇器
                    Button(action: {
                        showingFilePicker = true
                    }) {
                        ImportOptionView(
                            icon: "folder.fill",
                            title: "從文件選擇",
                            subtitle: "選擇 JSON 文件導入",
                            color: .blue
                        )
                    }
                    .disabled(importManager.isImporting)
                    
                    // iCloud Drive 掃描
                    Button(action: {
                        importManager.scanICloudDrive()
                    }) {
                        ImportOptionView(
                            icon: "icloud.fill",
                            title: "掃描 iCloud Drive",
                            subtitle: "自動尋找 JSON 書籍文件",
                            color: ColorManager.shared.green1
                        )
                    }
                    .disabled(importManager.isImporting)
                    
                    // 手動添加
                    Button(action: {
                        showingAddBook = true
                    }) {
                        ImportOptionView(
                            icon: "plus.circle.fill",
                            title: "手動添加",
                            subtitle: "逐本輸入書籍內容",
                            color: .orange
                        )
                    }
                    .disabled(importManager.isImporting)
                }
                
                // 導入進度
                if importManager.isImporting {
                    VStack(spacing: 10) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: ColorManager.shared.red1))
                        Text(importManager.importStatus)
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.7))
                    }
                    .padding()
                    .background(ColorManager.shared.background.opacity(0.5))
                    .cornerRadius(10)
                }
                
                // 最近導入的文件
                if !importManager.recentFiles.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("最近的文件")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(importManager.recentFiles, id: \.self) { fileName in
                                    RecentFileView(fileName: fileName) {
                                        importManager.importRecentFile(fileName)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(ColorManager.shared.background)
            .navigationTitle("導入書籍")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                importManager.importFromURLs(urls)
            case .failure(let error):
                alertMessage = "文件選擇失敗：\(error.localizedDescription)"
                showingAlert = true
            }
        }
        .sheet(isPresented: $showingAddBook) {
            AddBookView { newBook in
                // 書籍添加成功後通知父視圖
                onBooksImported()
            }
        }
        .alert("導入結果", isPresented: $showingAlert) {
            Button("確定") { 
                if alertMessage.contains("成功") {
                    onBooksImported()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .onReceive(importManager.$alertMessage) { message in
            if !message.isEmpty {
                alertMessage = message
                showingAlert = true
            }
        }
    }
}

struct ImportOptionView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.black.opacity(0.5))
        }
        .padding()
        .background(ColorManager.shared.background.opacity(0.8))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

struct RecentFileView: View {
    let fileName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundColor(ColorManager.shared.red1)
                
                Text(fileName)
                    .font(.caption2)
                    .foregroundColor(.black)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 60)
            .padding(8)
            .background(ColorManager.shared.background.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BookImportView {
        print("Books imported")
    }
}
