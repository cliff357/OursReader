import SwiftUI
import UniformTypeIdentifiers

struct BookImportView: View {
    @StateObject private var importManager = BookImportManager()
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingInstructions = false
    @Environment(\.dismiss) private var dismiss
    
    let onBooksImported: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 30) {
                        // 標題
                        VStack(spacing: 10) {
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 60))
                                .foregroundColor(ColorManager.shared.red1)
                            
                            Text(LocalizedStringKey("book_import_title"))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Text(LocalizedStringKey("book_import_subtitle"))
                                .font(.body)
                                .foregroundColor(.black.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        
                        // 使用說明按鈕（現在包含腳本下載功能）
                        Button(action: {
                            showingInstructions = true
                        }) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(ColorManager.shared.green1)
                                Text(LocalizedStringKey("book_import_guide_with_script"))
                                    .font(.headline)
                                    .foregroundColor(ColorManager.shared.green1)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(ColorManager.shared.green1.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ColorManager.shared.green1, lineWidth: 2)
                            )
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 導入選項 - 🔧 移除手動添加選項
                        VStack(spacing: 15) {
                            // 文件選擇器
                            Button(action: {
                                showingFilePicker = true
                            }) {
                                ImportOptionView(
                                    icon: "folder.fill",
                                    title: NSLocalizedString("book_import_from_files", comment: ""),
                                    subtitle: NSLocalizedString("book_import_select_json", comment: ""),
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
                                    title: NSLocalizedString("book_import_scan_icloud", comment: ""),
                                    subtitle: NSLocalizedString("book_import_auto_find_json", comment: ""),
                                    color: ColorManager.shared.green1
                                )
                            }
                            .disabled(importManager.isImporting)
                            
                            // 🔧 移除手動添加選項
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
                                Text(LocalizedStringKey("book_import_recent_files"))
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
                    }
                    .padding()
                }
                .background(ColorManager.shared.background)
                
                // Upload Progress Overlay
                if importManager.showUploadProgress {
                    UploadProgressOverlay(
                        fileName: importManager.currentFileName,
                        progress: importManager.uploadProgress,
                        status: importManager.importStatus
                    )
                }
            }
            .navigationTitle(LocalizedStringKey("book_import_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStringKey("general_cancel")) {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey("general_done")) {
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
                alertMessage = String(format: NSLocalizedString("book_import_file_error", comment: ""), error.localizedDescription)
                showingAlert = true
            }
        }
        .sheet(isPresented: $showingInstructions) {
            BookImportInstructionsView()
        }
        .alert(LocalizedStringKey("book_import_result"), isPresented: $showingAlert) {
            Button(LocalizedStringKey("general_ok")) { 
                if alertMessage.contains("成功") {
                    onBooksImported()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .onReceive(importManager.$alertMessage) { message in
            if (!message.isEmpty) {
                alertMessage = message
                showingAlert = true
            }
        }
    }
}

// 新增詳細使用說明視圖
struct BookImportInstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingScriptShare = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // 標題
                    VStack(spacing: 10) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 50))
                            .foregroundColor(ColorManager.shared.red1)
                        
                        Text(LocalizedStringKey("book_import_complete_guide"))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 10)
                    
                    // Step 1
                    InstructionStepView(
                        stepNumber: "1",
                        title: String(localized: "book_import_step1_title"),
                        subtitle: String(localized: "book_import_step1_subtitle"),
                        color: ColorManager.shared.red1
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            ImportantNoteView(
                                text: String(localized: "book_import_legal_reminder")
                            )
                            
                            // 整合腳本功能到步驟 1.1
                            InstructionSubStepView(
                                number: "1.1",
                                title: String(localized: "book_import_step1_1_title"),
                                content: String(localized: "book_import_step1_1_content")
                            ) {
                                // 腳本功能說明和下載按鈕
                                VStack(alignment: .leading, spacing: 12) {
                                    // 腳本功能特色
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(LocalizedStringKey("book_import_script_features_title"))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.black)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            ScriptFeatureItem(icon: "🔄", feature: String(localized: "book_import_feature_retry"))
                                            ScriptFeatureItem(icon: "🛡️", feature: String(localized: "book_import_feature_recovery"))
                                            ScriptFeatureItem(icon: "📂", feature: String(localized: "book_import_feature_resume"))
                                            ScriptFeatureItem(icon: "🎯", feature: String(localized: "book_import_feature_extract"))
                                            ScriptFeatureItem(icon: "📊", feature: String(localized: "book_import_feature_stats"))
                                        }
                                        .padding(.leading, 8)
                                    }
                                    
                                    // 腳本下載按鈕
                                    Button(action: {
                                        showingScriptShare = true
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.down.circle.fill")
                                                .foregroundColor(.white)
                                            Text(LocalizedStringKey("book_import_download_script"))
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(ColorManager.shared.red1)
                                        .cornerRadius(8)
                                    }
                                    
                                    // 使用步驟
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(LocalizedStringKey("book_import_usage_steps"))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.black)
                                        
                                        Text(LocalizedStringKey("book_import_step1_1_1"))
                                        Text(LocalizedStringKey("book_import_step1_1_2"))
                                        Text(LocalizedStringKey("book_import_step1_1_3"))
                                        Text(LocalizedStringKey("book_import_step1_1_4"))
                                        Text(LocalizedStringKey("book_import_step1_1_5"))
                                    }
                                    .font(.caption2)
                                    .foregroundColor(.black.opacity(0.8))
                                    .padding(.leading, 8)
                                }
                                .padding(12)
                                .background(ColorManager.shared.red1.opacity(0.05))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(ColorManager.shared.red1.opacity(0.2), lineWidth: 1)
                                )
                            }
                            
                            InstructionSubStepView(
                                number: "1.2",
                                title: String(localized: "book_import_step1_2_title"),
                                content: String(localized: "book_import_step1_2_content")
                            )
                        }
                    }
                    
                    // Step 2
                    InstructionStepView(
                        stepNumber: "2",
                        title: String(localized: "book_import_step2_title"),
                        subtitle: String(localized: "book_import_step2_subtitle"),
                        color: ColorManager.shared.green1
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            InstructionSubStepView(
                                number: "2.1",
                                title: String(localized: "book_import_step2_1_title"),
                                content: String(localized: "book_import_step2_1_content")
                            )
                            
                            InstructionSubStepView(
                                number: "2.2",
                                title: String(localized: "book_import_step2_2_title"),
                                content: String(localized: "book_import_step2_2_content")
                            )
                        }
                    }
                    
                    // 其他方式
                    VStack(alignment: .leading, spacing: 15) {
                        Text(LocalizedStringKey("book_import_other_methods_title"))
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey("book_import_method_icloud"))
                            Text(LocalizedStringKey("book_import_method_manual"))
                            Text(LocalizedStringKey("book_import_method_recent"))
                        }
                        .font(.body)
                        .foregroundColor(.black.opacity(0.8))
                    }
                    .padding()
                    .background(ColorManager.shared.background.opacity(0.5))
                    .cornerRadius(12)
                    
                    // 技術說明
                    VStack(alignment: .leading, spacing: 10) {
                        Text(LocalizedStringKey("book_import_tech_notes_title"))
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Text(LocalizedStringKey("book_import_tech_note_format"))
                        Text(LocalizedStringKey("book_import_tech_note_chunking"))
                        Text(LocalizedStringKey("book_import_tech_note_icloud"))
                        Text(LocalizedStringKey("book_import_tech_note_resume"))
                    }
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.7))
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(ColorManager.shared.background)
            .navigationTitle(LocalizedStringKey("book_import_instructions"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey("general_done")) {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
        }
        .sheet(isPresented: $showingScriptShare) {
            ScriptShareView()
        }
    }
    
    // 新增腳本功能項目組件
    struct ScriptFeatureItem: View {
        let icon: String
        let feature: String
        
        var body: some View {
            HStack(spacing: 6) {
                Text(icon)
                    .font(.caption2)
                
                Text(feature)
                    .font(.caption2)
                    .foregroundColor(.black.opacity(0.8))
            }
        }
    }
    
    // 增強版本的 InstructionSubStepView，支援額外內容
    struct InstructionSubStepView<Content: View>: View {
        let number: String
        let title: String
        let content: String
        let extraContent: Content?
        
        init(number: String, title: String, content: String) where Content == EmptyView {
            self.number = number
            self.title = title
            self.content = content
            self.extraContent = nil
        }
        
        init(number: String, title: String, content: String, @ViewBuilder extraContent: () -> Content) {
            self.number = number
            self.title = title
            self.content = content
            self.extraContent = extraContent()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Text(number)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.gray)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                        
                        Text(content)
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // 額外內容（如果有）
                if let extraContent = extraContent {
                    extraContent
                        .padding(.leading, 34) // 對齊文字內容
                }
            }
        }
    }
    
    // 步驟視圖組件
    struct InstructionStepView<Content: View>: View {
        let stepNumber: String
        let title: String
        let subtitle: String
        let color: Color
        let content: Content
        
        init(stepNumber: String, title: String, subtitle: String, color: Color, @ViewBuilder content: () -> Content) {
            self.stepNumber = stepNumber
            self.title = title
            self.subtitle = subtitle
            self.color = color
            self.content = content()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 15) {
                // 步驟標題
                HStack(spacing: 12) {
                    Text(stepNumber)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(color)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.7))
                    }
                    
                    Spacer()
                }
                
                // 步驟內容
                content
            }
            .padding()
            .background(color.opacity(0.05))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // 重要提醒視圖組件
    struct ImportantNoteView: View {
        let text: String
        
        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text(text)
                    .font(.caption)
                    .foregroundColor(.black)
                    .fontWeight(.medium)
            }
            .padding(8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// 新增腳本分享視圖
struct ScriptShareView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 標題說明
                    VStack(spacing: 10) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 50))
                            .foregroundColor(ColorManager.shared.red1)
                        
                        Text(LocalizedStringKey("book_import_python_script"))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Text("universal_book_scraper.py")
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 腳本功能說明
                    VStack(alignment: .leading, spacing: 15) {
                        Text(LocalizedStringKey("book_import_script_functions"))
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "🔄", title: String(localized: "book_import_feature_retry_full"), description: String(localized: "book_import_feature_retry_desc"))
                            FeatureRow(icon: "🛡️", title: String(localized: "book_import_feature_recovery_full"), description: String(localized: "book_import_feature_recovery_desc"))
                            FeatureRow(icon: "📂", title: String(localized: "book_import_feature_resume_full"), description: String(localized: "book_import_feature_resume_desc"))
                            FeatureRow(icon: "📊", title: String(localized: "book_import_feature_stats_full"), description: String(localized: "book_import_feature_stats_desc"))
                            FeatureRow(icon: "🎯", title: String(localized: "book_import_feature_extract_full"), description: String(localized: "book_import_feature_extract_desc"))
                        }
                    }
                    .padding()
                    .background(ColorManager.shared.background.opacity(0.5))
                    .cornerRadius(12)
                    
                    // 使用說明
                    VStack(alignment: .leading, spacing: 15) {
                        Text(LocalizedStringKey("book_import_usage_instructions"))
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey("book_import_usage_step1"))
                            Text(LocalizedStringKey("book_import_usage_step2"))
                            Text(LocalizedStringKey("book_import_usage_step3"))
                            Text(LocalizedStringKey("book_import_usage_step4"))
                            Text(LocalizedStringKey("book_import_usage_step5"))
                        }
                        .font(.body)
                        .foregroundColor(.black.opacity(0.8))
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // 分享按鈕
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                            Text(LocalizedStringKey("book_import_share_script"))
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(ColorManager.shared.red1)
                        .cornerRadius(12)
                    }
                    
                    // 重要提醒
                    VStack(alignment: .leading, spacing: 10) {
                        Text(LocalizedStringKey("book_import_important_reminder"))
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text(LocalizedStringKey("book_import_reminder_legal"))
                        Text(LocalizedStringKey("book_import_reminder_personal"))
                        Text(LocalizedStringKey("book_import_reminder_robots"))
                        Text(LocalizedStringKey("book_import_reminder_commercial"))
                    }
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.8))
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding()
            }
            .background(ColorManager.shared.background)
            .navigationTitle(LocalizedStringKey("book_import_share_script_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey("general_done")) {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let scriptContent = generateScriptContent() {
                ShareSheet(activityItems: [scriptContent])
            }
        }
    }
    
    private func generateScriptContent() -> URL? {
        let scriptContent = getLatestScriptContent()
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let scriptURL = tempDirectory.appendingPathComponent("universal_book_scraper.py")
        
        do {
            try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
            return scriptURL
        } catch {
            print("無法創建腳本文件：\(error)")
            return nil
        }
    }
}

// 腳本內容獲取函數 - 修正為正確讀取項目文件
private func getLatestScriptContent() -> String {
    // 🔧 修正：先嘗試從 Bundle 讀取（你用 "Add as Reference" 添加的文件）
    if let scriptPath = Bundle.main.path(forResource: "universal_book_scraper", ofType: "py"),
       let content = try? String(contentsOfFile: scriptPath, encoding: .utf8) {
        print("✅ 成功從 Bundle 讀取腳本文件")
        return content
    }
    
    // 如果 Bundle 中找不到，嘗試直接路徑
    let directPath = "/Users/dinglo/Library/Mobile Documents/com~apple~CloudDocs/Project/OurReader/script/universal_book_scraper.py"
    if FileManager.default.fileExists(atPath: directPath),
       let content = try? String(contentsOfFile: directPath, encoding: .utf8) {
        print("✅ 成功從直接路徑讀取腳本文件")
        return content
    }
    
    // 🔧 新增：嘗試在項目的其他可能位置查找
    let possiblePaths = [
        Bundle.main.path(forResource: "universal_book_scraper", ofType: "py", inDirectory: "script"),
        Bundle.main.bundlePath + "/universal_book_scraper.py",
        Bundle.main.bundlePath + "/script/universal_book_scraper.py"
    ]
    
    for possiblePath in possiblePaths.compactMap({ $0 }) {
        if FileManager.default.fileExists(atPath: possiblePath),
           let content = try? String(contentsOfFile: possiblePath, encoding: .utf8) {
            print("✅ 成功從路徑讀取腳本文件：\(possiblePath)")
            return content
        }
    }
    
    // 🔧 如果還是找不到，輸出調試信息
    print("❌ 無法找到腳本文件，調試信息：")
    print("   Bundle 路徑：\(Bundle.main.bundlePath)")
    print("   尋找的資源：universal_book_scraper.py")
    
    // 列出 Bundle 中的所有文件進行調試
    if let bundleContents = try? FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath) {
        print("   Bundle 內容（前10個文件）：")
        for (index, file) in bundleContents.prefix(10).enumerated() {
            print("     \(index + 1). \(file)")
        }
        
        // 查找 .py 文件
        let pyFiles = bundleContents.filter { $0.hasSuffix(".py") }
        if !pyFiles.isEmpty {
            print("   找到的 Python 文件：\(pyFiles)")
        }
    }
    
    // 最後的 fallback - 返回提示信息
    return """
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
\"\"\"
🔧 腳本文件讀取失敗 - 調試信息

原因可能是：
1. 文件未正確添加到 Xcode 項目的 Bundle 中
2. 文件名稱不匹配（檢查是否為 universal_book_scraper.py）
3. 文件添加方式有問題

解決方案：
1. 在 Xcode 中確認文件已添加到項目
2. 檢查 "Add to target" 是否選中了 OursReader
3. 嘗試重新添加文件：
   - 右鍵項目 → Add Files to 'OursReader'
   - 選擇 universal_book_scraper.py
   - 確保 "Add to target" 勾選 OursReader
   - 選擇 "Create groups"（不是 "Create folder references"）

如果問題持續，請使用以下完整腳本內容：
\"\"\"

import requests
from bs4 import BeautifulSoup
import json
import time
import re
from urllib.parse import urljoin, urlparse
import os
from http.client import RemoteDisconnected

class UniversalBookScraper:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        })
        self.delay = 2
        self.max_retries = 3
        self.retry_delay = 5
        # ... 其他初始化代碼 ...

    def extract_content_with_paragraphs(self, content_element):
        \"\"\"專門處理 <p> 標籤，保留段落分行\"\"\"
        paragraphs = content_element.find_all('p')
        
        if paragraphs:
            paragraph_texts = []
            for p in paragraphs:
                text = p.get_text().strip()
                if text:
                    paragraph_texts.append(text)
            
            # 用雙換行分隔段落
            return '\\n\\n'.join(paragraph_texts)
        else:
            return content_element.get_text()

    # ... 其他方法請參考完整版本 ...

if __name__ == "__main__":
    print("📚 Universal Book Scraper v2.4 - Fixed Paragraph Handling")
    print("⚠️ 這是簡化版本，請使用完整版本獲得所有功能")
    
    # 基本使用方法
    scraper = UniversalBookScraper()
    # scraper.scrape_from_url("你的URL", max_chapters=999)
"""
}

// 功能說明行組件
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.7))
            }
        }
    }
}

// 系統分享視圖
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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

// MARK: - Upload Progress Overlay
struct UploadProgressOverlay: View {
    let fileName: String
    let progress: Double
    let status: String
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .transition(.opacity)
            
            VStack(spacing: 25) {
                // File Icon with Animation
                ZStack {
                    Circle()
                        .fill(ColorManager.shared.red1.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 50))
                        .foregroundColor(ColorManager.shared.red1)
                }
                .scaleEffect(progress > 0 ? 1.0 : 0.8)
                .animation(.spring(response: 0.3), value: progress)
                
                // File Name
                Text(fileName)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .lineLimit(2)
                
                // Progress Section
                VStack(spacing: 15) {
                    // Progress Bar
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 10)
                            .fill(ColorManager.shared.red1)
                            .frame(width: max(0, progress) * 250, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                    .frame(width: 250)
                    
                    // Percentage
                    Text("\(Int(progress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
                
                // Status Text
                Text(status)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .frame(minHeight: 40)
                
                // Loading Indicator (for indeterminate states)
                if progress < 0.05 || progress > 0.95 {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(white: 0.15),
                                Color(white: 0.25)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(30)
        }
        .transition(.opacity.combined(with: .scale))
        .zIndex(999)
    }
}

#Preview {
    BookImportView {
        print("Books imported")
    }
}
