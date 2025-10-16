//
//  SideMenu.swift
//  OursReader
//
//  Created by Cliff Chan on 20/3/2024.
//

import SwiftUI

struct SideMenu: View {
    @Binding var isShowing: Bool
    @Binding var selectedTab: SideMenuOptionModel?
    @State private var selectedOption: SideMenuOptionModel? = .dashboard
    @State private var showSettings = false
    
    var version: String {
        // 從專案的 Info.plist 中取得版本號
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "v\(version) (\(build))" // 格式：v1.0.0 (1)
        }
        return String(localized: "version_unavailable")
    }

    
    var body: some View {
        ZStack {
            if isShowing {
                Rectangle()
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { isShowing.toggle() }
                
                
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        SideMenuHeaderView()
                        
                        VStack {
                            ForEach(SideMenuOptionModel.allCases) { option in
                                Button {
                                    selectedOption = option
                                    selectedTab = option
                                    
                                    // 如果選擇的是設置選項，顯示設置頁面
                                    if option == .settings {
                                        showSettings = true
                                    }
                                    
                                    isShowing = false
                                } label: {
                                    SideMenuRowView(option: option, selectedOption: $selectedOption)
                                }
                            }
                        }
                        Spacer()
                        Button {
                            isShowing = false
                            
                            // 🔧 修正：明確指定使用 NotificationCenter 的 post 方法
                            NotificationCenter.default.post(
                                name: NSNotification.Name("userDidLogout"),
                                object: nil
                            )
                            
                            UserAuthModel.shared.signOut()
                        } label: {
                            HStack {
                                Text(String(localized:"auth_logout_button"))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(ColorManager.shared.green1)
                                    .cornerRadius(10)
                            }
                        }
                        
                        HStack {
                            Text(String(localized:"version_info"))
                                .foregroundColor(Color.black)
                            Text(version.isEmpty ? String(localized:"version_unavailable") : version)
                                .foregroundColor(Color.black)
                        }
                    }
                    .padding()
                    .frame(width: 270, alignment: .leading)
                    .background(ColorManager.shared.flesh1)
                    Spacer()
                }
                .transition(.move(edge: .leading))
                
            }
        }
        .animation(.easeIn,value: isShowing)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}


#Preview {
    SideMenu(isShowing: .constant(true), selectedTab: .constant(SideMenuOptionModel.dashboard))
}
