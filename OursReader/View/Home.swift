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
    @State private var selectedSideMenu: SideMenuOptionModel? = .friendList
    @Environment(\.colorScheme) private var scheme
    
    @State private var showMenu = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                NavBar()
                
                TabView(selection: $selectedSideMenu) {
                    Dashboard()
                        .tag(Optional.some(SideMenuOptionModel.dashboard))
                    Profile()
                        .tag(Optional.some(SideMenuOptionModel.profile))
                    Text("Widget")
                        .tag(Optional.some(SideMenuOptionModel.widget))
                    FriendList()
                        .tag(Optional.some(SideMenuOptionModel.friendList))
                    Text("Settings")
                        .tag(Optional.some(SideMenuOptionModel.settings))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.gray.opacity(0.1))
            .onAppear() {
                Auth.auth().signInAnonymously { user, error in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                }
                let ref = Database.database().reference(withPath: "name")
                ref.observe(.value) { snapshot in
                    if let output = snapshot.value {
                        //Todo: data exchange with push token
                    }
                }
            }
            
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
        .background(Color.background)
        .foregroundStyle(Color.black)
    }
    
}

#Preview {
    ContentView()
}
