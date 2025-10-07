import Foundation
import CloudKit
import UIKit

class CloudKitTestHelper {
    static let shared = CloudKitTestHelper()
    
    private init() {}
    
    // MARK: - 插入測試書籍到 iCloud
    
    func insertTestBooksToCloud() {
        print("🔍 === Starting to insert test books to CloudKit ===")
        
        // 創建測試書籍數據
        let testBooks = createTestBooks()
        
        // 統一插入到資料庫（簡化版）
        insertBooksToDatabase(testBooks)
    }
    
    // MARK: - 創建測試書籍數據
    
    private func createTestBooks() -> [CloudBook] {
        return [
            CloudBook(
                recordID: nil,
                name: "Swift Programming Mastery",
                introduction: "Complete guide to mastering Swift programming language from basics to advanced concepts. Learn iOS development, data structures, algorithms, and best practices.",
                coverURL: nil,
                author: "Apple Developer Team",
                content: [
                    "Chapter 1: Swift Fundamentals\n\nSwift is a powerful and intuitive programming language for iOS, iPadOS, macOS, tvOS, and watchOS. Writing Swift code is interactive and fun, the syntax is concise yet expressive, and Swift includes modern features developers love.\n\nSwift code is safe by design, yet also produces software that runs lightning-fast. Swift is the result of the latest research on programming languages, combined with decades of experience building Apple platforms.",
                    "Chapter 2: Variables and Constants\n\nIn Swift, you declare constants with let and variables with var. Constants are values that cannot be changed once set, while variables can be modified throughout your program.\n\nlet maximumNumberOfLoginAttempts = 10\nvar currentLoginAttempt = 0\n\nType annotations can be provided to be clear about what kind of values a constant or variable can store.",
                    "Chapter 3: Control Flow\n\nSwift provides a variety of control flow statements including if statements, switch statements, and loops like for-in, while, and repeat-while.\n\nThe switch statement in Swift is particularly powerful, supporting pattern matching and providing a much more flexible alternative to switch statements in C-like languages."
                ],
                firebaseBookID: "swift_mastery_001",
                coverImage: UIImage(named: "cover_image_1")
            ),
            
            CloudBook(
                recordID: nil,
                name: "iOS App Development Guide",
                introduction: "Learn to build beautiful and functional iOS applications using SwiftUI and UIKit. From basic UI components to advanced networking and data persistence.",
                coverURL: nil,
                author: "iOS Expert",
                content: [
                    "Chapter 1: Getting Started with Xcode\n\nXcode is Apple's integrated development environment (IDE) for creating apps for iOS, iPadOS, macOS, tvOS, and watchOS. In this chapter, you'll learn how to navigate Xcode's interface and create your first project.\n\nXcode includes everything you need to create amazing apps: a world-class code editor, powerful debugging tools, and comprehensive testing frameworks.",
                    "Chapter 2: Introduction to SwiftUI\n\nSwiftUI is Apple's modern framework for building user interfaces across all Apple platforms with the power of Swift. SwiftUI makes it easy to build great-looking apps with minimal code.\n\nWith SwiftUI, you describe your user interface using declarative Swift syntax. SwiftUI automatically translates your declarations into efficient user interface code.",
                    "Chapter 3: Building Your First App\n\nIn this chapter, you'll create a simple but complete iOS app. You'll learn about views, modifiers, state management, and how to handle user interactions.\n\nWe'll build a reading tracker app that demonstrates the core concepts of iOS development."
                ],
                firebaseBookID: "ios_dev_guide_001",
                coverImage: UIImage(named: "cover_image_2")
            ),
            
            CloudBook(
                recordID: nil,
                name: "Data Structures & Algorithms",
                introduction: "Master fundamental computer science concepts including arrays, linked lists, trees, graphs, sorting algorithms, and dynamic programming with Swift implementations.",
                coverURL: nil,
                author: "CS Professor",
                content: [
                    "Chapter 1: Introduction to Data Structures\n\nData structures are ways of organizing and storing data so that it can be accessed and worked with efficiently. They define the relationship between the data, and the operations that can be performed on the data.\n\nThe choice of data structure often begins from the choice of an abstract data type (ADT). A well-designed data structure allows a variety of critical operations to be performed using as few resources (both execution time and memory space) as possible.",
                    "Chapter 2: Arrays and Strings\n\nArrays are among the oldest and most important data structures. They consist of a collection of elements (values or variables), each identified by at least one array index or key.\n\nIn Swift, arrays are type-safe collections that store ordered lists of values of the same type. Swift's Array type is bridged to Foundation's NSArray class.",
                    "Chapter 3: Linked Lists\n\nA linked list is a linear collection of data elements, in which linear order is not given by their physical placement in memory. Instead, each element points to the next.\n\nLinked lists are useful when you need to insert or remove items frequently, especially at the beginning of the collection."
                ],
                firebaseBookID: "dsa_swift_001",
                coverImage: UIImage(named: "cover_image_3")
            ),
            
            CloudBook(
                recordID: nil,
                name: "Machine Learning with Swift",
                introduction: "Explore machine learning concepts and implementations using Swift for TensorFlow. Build intelligent applications with neural networks and deep learning.",
                coverURL: nil,
                author: "ML Researcher",
                content: [
                    "Chapter 1: Introduction to Machine Learning\n\nMachine Learning is a subset of artificial intelligence (AI) that provides systems the ability to automatically learn and improve from experience without being explicitly programmed.\n\nSwift for TensorFlow provides a next-generation platform for machine learning, combining the performance of TensorFlow with the ease and expressiveness of Swift.",
                    "Chapter 2: Neural Networks Basics\n\nNeural networks are computing systems inspired by biological neural networks. They consist of layers of interconnected nodes (neurons) that process information using connectionist approaches.\n\nIn this chapter, you'll learn to implement basic neural networks using Swift and understand concepts like forward propagation, backpropagation, and gradient descent.",
                    "Chapter 3: Building Your First ML Model\n\nLet's create a simple image classification model using Swift for TensorFlow. You'll learn to preprocess data, design network architectures, train models, and evaluate their performance.\n\nWe'll build a model that can classify different types of books based on their cover images."
                ],
                firebaseBookID: "ml_swift_001",
                coverImage: UIImage(named: "cover_image_1")
            ),
            
            CloudBook(
                recordID: nil,
                name: "Web Development Essentials",
                introduction: "Learn modern web development with HTML5, CSS3, JavaScript ES6+, and popular frameworks. Build responsive and interactive web applications.",
                coverURL: nil,
                author: "Web Developer",
                content: [
                    "Chapter 1: HTML5 Fundamentals\n\nHTML5 is the latest evolution of the standard that defines HTML. It includes new elements, attributes, and APIs that make it easier to build modern web applications.\n\nSemantic HTML5 elements like <header>, <nav>, <main>, <article>, and <footer> provide better document structure and accessibility.",
                    "Chapter 2: CSS3 and Responsive Design\n\nCSS3 introduces powerful new features like flexbox, grid layout, animations, and media queries that enable responsive design.\n\nResponsive design ensures that web applications work well on all devices, from desktop computers to tablets and smartphones.",
                    "Chapter 3: JavaScript Modern Features\n\nES6+ brings many powerful features to JavaScript including arrow functions, template literals, destructuring, modules, and async/await for handling asynchronous operations.\n\nThese features make JavaScript code more readable, maintainable, and powerful for building complex web applications."
                ],
                firebaseBookID: "web_dev_001",
                coverImage: UIImage(named: "cover_image_2")
            )
        ]
    }
    
    // MARK: - 統一插入到資料庫
    
    private func insertBooksToDatabase(_ books: [CloudBook]) {
        print("📚 Inserting \(books.count) books to CloudKit Database...")
        
        // 檢查是否有當前用戶
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            print("⚠️ No user logged in, cannot insert books to private database")
            print("📝 Please log in first to create books")
            return
        }
        
        for (index, book) in books.enumerated() {
            // 使用新的 saveUserBook 方法，為當前用戶保存書籍
            CloudKitManager.shared.saveUserBook(book, firebaseUserID: currentUser.uid) { result in
                switch result {
                case .success(let recordName):
                    print("✅ Book \(index + 1) inserted: \(book.name) (ID: \(recordName))")
                    
                case .failure(let error):
                    print("❌ Failed to insert book \(index + 1): \(book.name)")
                    print("   Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Schema 檢查功能
    
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
        print("   • Field name: 'content', Type: List")
        print("     Select 'String' as the list item type")
        print("   • Field name: 'userID', Type: String")
        print("     🚨 CRITICAL: ✅ Check 'Queryable' ✅ Check 'Sortable'")
        print("     (This field MUST be queryable for user book filtering)")
        print("   • Field name: 'bookmarkedPages', Type: List")
        print("     Select 'Int(64)' as the list item type")
        print("   • Field name: 'firebaseBookID', Type: String (Optional)")
        print("   • Field name: 'coverImage', Type: Asset (Optional)")
        print("   • Field name: 'coverURL', Type: String (Optional)")
        print("7️⃣ Click 'Save' to create the record type")
        print("")
        print("🚨 IMPORTANT FIXES for current errors:")
        print("   1. Make sure 'userID' field has 'Queryable' ✅ checked")
        print("   2. Make sure 'userID' field has 'Sortable' ✅ checked")
        print("   3. After changes, wait 5-10 minutes for CloudKit to update")
        print("")
        print("🎯 Key Point: Make sure you're in 'Private Database' on the left!")
        print("📝 Note: Each user's books are private to them only")
        print("📝 coverImage: For storing actual image files")
        print("📝 coverURL: For storing image URLs or references")
        print("📝 currentPage: NOT stored in CloudKit (local only)")
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
    
    func checkCloudKitSchema() {
        print("🔍 === Checking CloudKit Schema ===")
        print("🌐 CloudKit Dashboard: https://icloud.developer.apple.com/dashboard/")
        print("📦 Container: iCloud.com.cliffchan.manwareader")
        print("🌍 Environment: Development")
        print("")
        print("📖 Simplified Record Types Layout:")
        print("   📂 Private Database:")
        print("      ├── Book (for user's personal books)")
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
    
    // MARK: - 簡化的測試數據插入
    
    func insertTestBooksForUser(userID: String) {
        print("👤 Creating test books for user: \(userID)")
        
        let testBooks = createTestBooks()
        
        for (index, var book) in testBooks.enumerated() {
            // 添加當前頁和書簽的測試數據
            book.currentPage = Int.random(in: 0...2)
            book.bookmarkedPages = Array((0...2).shuffled().prefix(Int.random(in: 0...3)))
            
            CloudKitManager.shared.saveUserBook(book, firebaseUserID: userID) { result in
                switch result {
                case .success(let recordName):
                    print("✅ Book \(index + 1) created for user: \(book.name) (ID: \(recordName))")
                case .failure(let error):
                    print("❌ Failed to create book \(index + 1): \(book.name)")
                    print("   Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func setupCompleteTestEnvironment() {
        print("🚀 === Setting up simplified test environment ===")
        
        // 0. 先檢查 Schema
        checkCloudKitSchema()
        
        // 延遲執行，給用戶時間查看 Schema 指導
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            print("⏳ Continuing with test data insertion...")
            print("   (If you see schema errors above, please set up CloudKit first)")
            
            // 只為當前用戶創建書籍
            if let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() {
                self.insertTestBooksForUser(userID: currentUser.uid)
            } else {
                print("⚠️ No Firebase user logged in, cannot create test books")
                print("📝 Please log in first, then test books will be created for your account")
            }
        }
        
        print("✅ Simplified test environment setup initiated!")
        print("📝 Each user will have their own private book collection")
    }
    
    // MARK: - 清理測試數據 (可選)
    
    func clearAllTestBooks() {
        print("🗑️ === Clearing test books (Note: This only clears from current session, not from CloudKit) ===")
        print("⚠️ To completely clear CloudKit data, use CloudKit Dashboard or implement delete operations")
    }
}
