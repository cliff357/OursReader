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
                
                TabView(selection: $selectedSideMenu) {
                    Dashboard()
                        .tag(Optional.some(SideMenuOptionModel.dashboard))
                    FriendList()
                        .tag(Optional.some(SideMenuOptionModel.friendList))
                    SettingsView()
                        .tag(Optional.some(SideMenuOptionModel.settings))
                }
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
        .foregroundStyle(Color.black) // 確保所有文字都是黑色
        .accentColor(.black) // 設置強調色為黑色
    }
}

#Preview {
    ContentView()
}
