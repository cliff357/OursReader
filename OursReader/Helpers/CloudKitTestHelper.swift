import Foundation
import CloudKit
import UIKit

class CloudKitTestHelper {
    static let shared = CloudKitTestHelper()
    
    private init() {}
    
    // MARK: - Schema 檢查功能
    
    func checkCloudKitSchema() {
        print("🔍 === Checking CloudKit Schema ===")
        print("🌐 CloudKit Dashboard: https://icloud.developer.apple.com/dashboard/")
        print("📦 Container: iCloud.com.cliffchan.manwareader")
        print("🌍 Environment: Development")
        print("")
        print("📖 Simplified Record Types Layout:")
        print("   📂 Private Database:")
        print("      ├── Book (for user's personal books)")
        print("      ├── BookChunk (for chunked book content)")
        print("      └── UserLink (for user connections)")
        print("")
        print("💡 每個用戶的書籍都是私人的，只有自己能看到")
        print("")
        
        // 首先驗證 container 設置
        CloudKitManager.shared.verifyContainerSetup()
        
        print("🔍 Checking individual record types...")
        
        // 只檢查 Private Database 中的 Book
        print("🔍 Checking Book in Private Database...")
        checkRecordType("Book", inDatabase: "Private") { exists in
            if exists {
                print("✅ Book found in Private Database (✓ correct location)")
            } else {
                print("❌ Book not found in Private Database")
                self.printBookSchemaInstructions()
            }
        }
        
        // 檢查 BookChunk record type
        print("🔍 Checking BookChunk in Private Database...")
        checkRecordType("BookChunk", inDatabase: "Private") { exists in
            if exists {
                print("✅ BookChunk found in Private Database (✓ correct location)")
            } else {
                print("❌ BookChunk not found in Private Database")
                self.printBookSchemaInstructions()
            }
        }
        
        // 檢查 UserLink record type
        print("🔍 Checking UserLink in Private Database...")
        checkRecordType("UserLink", inDatabase: "Private") { exists in
            if exists {
                print("✅ UserLink found in Private Database (✓ correct location)")
            } else {
                print("❌ UserLink not found in Private Database")
                self.printUserLinkSchemaInstructions()
            }
        }
    }
    
    private func printBookSchemaInstructions() {
        print("")
        print("📚 === BOOK RECORD TYPE SETUP (PRIVATE DATABASE) ===")
        print("1️⃣ Go to: https://icloud.developer.apple.com/dashboard/")
        print("2️⃣ Select your app: iCloud.com.cliffchan.manwareader")
        print("3️⃣ 🔍 IMPORTANT: Select 'Private Database' from the left sidebar")
        print("4️⃣ In Private Database, click 'Record Types' → '+ Add Record Type'")
        print("5️⃣ Enter record type name: 'Book' (case-sensitive)")
        print("6️⃣ Add these fields one by one:")
        print("   • Field name: 'name', Type: String")
        print("     ✅ Check 'Queryable' ✅ Check 'Sortable'")
        print("   • Field name: 'introduction', Type: String")
        print("   • Field name: 'author', Type: String")
        print("     ✅ Check 'Queryable' ✅ Check 'Sortable'")
        print("   • Field name: 'userID', Type: String")
        print("     🚨 CRITICAL: ✅ Check 'Queryable' ✅ Check 'Sortable'")
        print("   • Field name: 'bookmarkedPages', Type: List")
        print("     Select 'Int(64)' as the list item type")
        print("   • Field name: 'firebaseBookID', Type: String (Optional)")
        print("   • Field name: 'coverImage', Type: Asset (Optional)")
        print("   • Field name: 'coverURL', Type: String (Optional)")
        print("   🆕 Field name: 'isChunked', Type: Int(64)")
        print("       💡 在 CloudKit 中用 Int(64) 代替 Boolean：1=true, 0=false")
        print("   🆕 Field name: 'totalChunks', Type: Int(64)")
        print("   ❌ 不要添加 'content' 字段（內容存在 BookChunk 中）")
        print("7️⃣ Click 'Save' to create the record type")
        print("")
        
        // BookChunk Record Type 指導
        print("📦 === BOOKCHUNK RECORD TYPE SETUP ===")
        print("1️⃣ Still in Private Database, create another record type")
        print("2️⃣ Enter record type name: 'BookChunk' (case-sensitive)")
        print("3️⃣ Add these fields:")
        print("   • Field name: 'userID', Type: String")
        print("     ✅ Check 'Queryable'")
        print("   • Field name: 'mainBookID', Type: String")
        print("     ✅ Check 'Queryable' (用於關聯主書籍)")
        print("   • Field name: 'chunkIndex', Type: Int(64)")
        print("     ✅ Check 'Sortable' (用於排序)")
        print("   • Field name: 'content', Type: List")
        print("     Select 'String' as the list item type")
        print("4️⃣ Click 'Save' to create the record type")
        print("")
        print("🎯 統一分片架構:")
        print("   • 所有書籍都使用分片儲存，不管大小")
        print("   • 每個 BookChunk 最大 300KB")
        print("   • Book 記錄只存元數據，BookChunk 存實際內容")
        print("   • 載入時自動合併所有分片")
        print("   • isChunked 用 Int(64)：1=分片書籍, 0=舊格式書籍")
        print("")
    }
    
    private func printUserLinkSchemaInstructions() {
        print("")
        print("🔗 === USERLINK RECORD TYPE SETUP ===")
        print("1️⃣ Go to: https://icloud.developer.apple.com/dashboard/")
        print("2️⃣ Select your app: iCloud.com.cliffchan.manwareader")
        print("3️⃣ 🔍 IMPORTANT: Select 'Private Database' from the left sidebar")
        print("4️⃣ In Private Database, click 'Record Types' → '+ Add Record Type'")
        print("5️⃣ Enter record type name: 'UserLink' (case-sensitive)")
        print("6️⃣ Add these fields one by one:")
        print("   • Field name: 'firebaseUserID', Type: String")
        print("     ✅ Check 'Queryable'")
        print("   • Field name: 'cloudKitUserID', Type: String")
        print("     ✅ Check 'Queryable'")
        print("7️⃣ Click 'Save' to create the record type")
        print("")
        print("🎯 Key Point: Make sure you're in 'Private Database' on the left!")
        print("")
    }
    
    private func checkRecordType(_ recordType: String, inDatabase databaseName: String, completion: @escaping (Bool) -> Void) {
        // 現在只使用 Private Database，因為我們簡化了架構
        let database = CloudKitManager.shared.privateDB
        
        // 使用簡單的查詢，避免排序問題
        let testQuery = CKQuery(recordType: recordType, predicate: NSPredicate(value: false))
        // 移除排序描述符避免錯誤
        // testQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        database.perform(testQuery, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                if let error = error as? CKError {
                    if error.code == .invalidArguments || error.code.rawValue == 12 {
                        print("❌ '\(recordType)' record type NOT FOUND in \(databaseName) Database")
                        print("   Error details: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("⚠️ '\(recordType)' check failed with error: \(error.localizedDescription)")
                        completion(false)
                    }
                } else {
                    print("✅ '\(recordType)' record type exists in \(databaseName) Database")
                    completion(true)
                }
            }
        }
    }
}
