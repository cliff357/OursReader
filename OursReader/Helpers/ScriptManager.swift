import Foundation

class ScriptManager {
    static let shared = ScriptManager()
    
    private let scriptFileName = "universal_book_scraper.py"
    private let scriptSourcePath = "/Users/dinglo/Library/Mobile Documents/com~apple~CloudDocs/Project/OurReader/script/universal_book_scraper.py"
    
    private init() {}
    
    func getLatestScriptContent() -> String? {
        // 優先從源文件讀取
        if FileManager.default.fileExists(atPath: scriptSourcePath),
           let content = try? String(contentsOfFile: scriptSourcePath, encoding: .utf8) {
            return content
        }
        
        // Fallback 到 Bundle
        if let bundlePath = Bundle.main.path(forResource: "universal_book_scraper", ofType: "py"),
           let content = try? String(contentsOfFile: bundlePath, encoding: .utf8) {
            return content
        }
        
        return nil
    }
    
    func getScriptVersion() -> String {
        guard let content = getLatestScriptContent() else {
            return "未知版本"
        }
        
        // 從腳本內容中提取版本號
        let versionPattern = #"Universal Book Scraper v([\d\.]+)"#
        if let regex = try? NSRegularExpression(pattern: versionPattern),
           let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
           let versionRange = Range(match.range(at: 1), in: content) {
            return String(content[versionRange])
        }
        
        return "版本檢測失敗"
    }
    
    // 預留給未來的腳本管理功能
    func getScriptContent() -> String {
        // 這裡可以返回 Python 腳本內容
        return "# Python script content will be here"
    }
}
