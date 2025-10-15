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
    
    var body: some View {
        VStack {
            Group {
                // 🔧 移除 WelcomePage 檢查，直接根據登入狀態決定顯示內容
                if userAuth.isLoggedIn {
                    NavigationStack(path: $homeRouter.path ) {
                        Home()
                            .environmentObject(userAuth)
                            .navigationDestination(for: HomeRoute.self, destination: { $0 })
                    }
                    .accentColor(.black)
                } else {
                    NavigationStack(path: $homeRouter.path ) {
                        Login()
                            .environmentObject(userAuth)
                            .navigationDestination(for: HomeRoute.self, destination: { $0 })
                    }
                    .accentColor(.black)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(.stack)
        }
        .accentColor(.black)
        .onAppear {
            // 確保數據 API 被初始化
            DataAPIManager.shared.initializeMockData()
            
            // 設置全局導航欄外觀
            setupNavigationAppearance()
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
}

#Preview {
    MainView()
}

