//
//  Home.swift
//  OursReader
//
//  Created by Cliff Chan on 15/11/2023.
//

import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct Home: View {
    @State private var selectedSideMenu: SideMenuOptionModel? = .dashboard
    @Environment(\.colorScheme) private var scheme
    
    @State private var showMenu = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                NavBar()
                
                // 🔧 修正：移除 TabView，使用 ZStack 切換頁面
                ZStack {
                    if selectedSideMenu == .dashboard {
                        Dashboard()
                    } else if selectedSideMenu == .friendList {
                        FriendList()
                    } else if selectedSideMenu == .settings {
                        SettingsView()
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedSideMenu)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            SideMenu(isShowing: $showMenu, selectedTab: $selectedSideMenu)
        }
    }
    
    @ViewBuilder
    func NavBar() -> some View {
        HStack {
            Button(action: {
                showMenu.toggle()
            }, label: {
                Image(systemName: "line.3.horizontal.decrease")
            })
            
            Spacer()
            
            Button(action: {}, label: {
                Image(systemName: "bell.badge")
            })
        }
        .font(.title2)
        .overlay {
            Text(selectedSideMenu?.title ?? "")
                .font(.title3.bold())
        }
        .padding(15)
        .background(ColorManager.shared.background)
        .foregroundStyle(Color.black)
        .accentColor(.black)
    }
}

#Preview {
    ContentView()
}
