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

