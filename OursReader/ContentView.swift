//
//  ContentView.swift
//  OursReader
//
//  Created by Cliff Chan on 18/10/2023.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userAuthModel: UserAuthModel
    @State private var isCheckingAuth = true
    
    var body: some View {
        ZStack {
            if isCheckingAuth {
                // 載入畫面
                ColorManager.shared.background.ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(ColorManager.shared.red1)
            } else if userAuthModel.isLoggedIn {
                // 已登入：顯示主頁面
                Home()
            } else {
                // 未登入：顯示登入頁面
                NavigationView {
                    Login()
                }
            }
        } 
        .onAppear {
            checkAuthStatus()
        }
    }
    
    private func checkAuthStatus() {
        // 短暫延遲以顯示載入畫面
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                isCheckingAuth = false
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserAuthModel.shared)
}
