//
//  MainView.swift
//  OursReader
//
//  Created by Cliff Chan on 25/5/2024.
//

import SwiftUI

struct MainView: View {
    @StateObject var userAuth: UserAuthModel =  UserAuthModel()
    @StateObject var homeRouter: HomeRouter = HomeRouter.shared
    @StateObject var loginRouter: LoginRouter = LoginRouter.shared
    
//    @StateObject var reminderManager = ReminderManager.shared
//    @StateObject var errorReminderManager = ErrorReminderManager.shared
    
    var body: some View {
        VStack {
            Group {
                if userAuth.nickName.isEmpty {
                    WelcomePage()
                        .environmentObject(userAuth)
                } else {
                    if userAuth.isLoggedIn {
                        NavigationStack(path: $homeRouter.path ) {
                            Home()
                                .environmentObject(userAuth)
                                .navigationDestination(for: HomeRoute.self, destination: { $0 })
                        }
                        .accentColor(.black) // 設置 NavigationStack 的強調色
                    } else {
                        NavigationStack(path: $homeRouter.path ) {
                            Login()
                                .environmentObject(userAuth)
                                .navigationDestination(for: HomeRoute.self, destination: { $0 })
                        }
                        .accentColor(.black) // 設置 NavigationStack 的強調色
                    }
                }
            }
            
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(.stack)
        }
        .accentColor(.black) // 設置整體強調色
        .onAppear {
            // 確保數據 API 被初始化
            DataAPIManager.shared.initializeMockData()
            
            // 設置全局導航欄外觀
            setupNavigationAppearance()
            
            // 🚀 測試 iCloud 連接
            testCloudKitConnection()
        }
    }
    
    // 設置導航欄外觀
    private func setupNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(ColorManager.shared.background)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        
        // 設置返回按鈕顏色為黑色
        UINavigationBar.appearance().tintColor = UIColor.black
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    // 測試 CloudKit 連接
    private func testCloudKitConnection() {
        print("🔍 === CloudKit Connection Test Started ===")
        
        // 🚀 首先驗證 Container 設置
        print("🔧 Verifying CloudKit Container...")
        CloudKitManager.shared.verifyContainerSetup()
        
        // 延遲1秒後檢查 Schema
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🔧 Checking CloudKit Schema setup...")
            print("📋 Please check the detailed instructions below for setting up Record Types...")
            CloudKitTestHelper.shared.checkCloudKitSchema()
            
            // 延遲8秒讓用戶查看 Schema 檢查結果和詳細指導
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                print("")
                print("⏭️ Continuing with other CloudKit tests...")
                print("   (If you just set up the Record Types, please wait 5-10 minutes for CloudKit to sync)")
                print("")
                
                // 繼續其他測試...
                self.continueCloudKitTests()
            }
        }
        
        print("🔍 === CloudKit Connection Test Completed ===")
    }
    
    private func continueCloudKitTests() {
        // 移除自動插入測試書籍的邏輯
        // CloudKitTestHelper.shared.insertTestBooksToCloud()
        
        // 1. 測試用戶狀態
        CloudKitManager.shared.checkUserStatus { result in
            switch result {
            case .success(let userIdentity):
                if let userIdentity = userIdentity {
                    print("✅ User Identity: \(userIdentity.nameComponents?.givenName ?? "Unknown") \(userIdentity.nameComponents?.familyName ?? "")")
                } else {
                    print("⚠️ No user identity found")
                }
            case .failure(let error):
                print("❌ User Status Error: \(error.localizedDescription)")
            }
        }
        
        // 2. 測試獲取用戶書籍
        if let currentUser = userAuth.getCurrentFirebaseUser() {
            print("🔍 Testing fetchUserBooks...")
            CloudKitManager.shared.fetchUserBooks(firebaseUserID: currentUser.uid) { result in
                switch result {
                case .success(let books):
                    print("✅ Fetched \(books.count) books from CloudKit:")
                    for (index, book) in books.enumerated() {
                        print("   📖 \(index + 1). \(book.name) by \(book.author)")
                    }
                case .failure(let error):
                    print("❌ Fetch Books Error: \(error.localizedDescription)")
                    if error.localizedDescription.contains("not marked indexable") {
                        print("🔧 This error means CloudKit Record Types are not set up yet.")
                        print("   Please follow the schema setup instructions above.")
                    }
                }
            }
        } else {
            print("⚠️ No Firebase user logged in, skipping user books test")
        }
        
        print("💡 Tip: Long press on the E-Book tab in Dashboard to insert test books!")
    }
}

#Preview {
    MainView()
}

