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
    @State private var selectedTab: Tab?
    @State private var selectedSideMenu: SideMenuOptionModel? = .dashboard
    @Environment(\.colorScheme) private var scheme
    /// Tab Progress
    @State private var tabProgress: CGFloat = 0
    @State private var showMenu = false
    
    var body: some View {
        ZStack {
            VStack() {
                NavBar()
                
                TabView(selection: $selectedSideMenu) {
                    VStack(spacing: 15) {
                        
                        
                        CustomTabBar()
                        
                        //Paging View using new iOS 17 APIS
                        GeometryReader {
                            let size = $0.size
                            
                            ScrollView(.horizontal) {
                                LazyHStack(spacing: 0 ) {
                                    SampleView(.red)
                                        .id(Tab.fav)
                                        .containerRelativeFrame(.horizontal)
                                    
                                    SampleView(.blue)
                                        .id(Tab.new)
                                        .containerRelativeFrame(.horizontal)
                                    
                                    SampleView(.purple)
                                        .id(Tab.all)
                                        .containerRelativeFrame(.horizontal)
                                }
                                .scrollTargetLayout()
                                .offsetX { value in
                                    /// Converting offset into progress
                                    let progress = -value / (size.width * CGFloat(Tab.allCases.count - 1))
                                    /// Capping Progress BTW 0-1
                                    tabProgress = max(min(progress, 1),0)
                                }
                            }
                            .scrollPosition(id: $selectedTab)
                            .scrollIndicators(.hidden)
                            .scrollTargetBehavior(.paging)
                            .scrollClipDisabled()
                        }
                    }
                        .tag(Optional.some(SideMenuOptionModel.dashboard))
                    Profile()
                        .tag(Optional.some(SideMenuOptionModel.profile))
                    Text("Widget")
                        .tag(Optional.some(SideMenuOptionModel.widget))
                    Text("Friend List")
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
        .foregroundStyle(.primary)
        .padding(15)
    }
    
    @ViewBuilder
    func CustomTabBar() -> some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                HStack(spacing: 10) {
                    Image(systemName: tab.systemImage)
                    
                    Text(tab.name)
                        .font(.callout)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .contentShape(.capsule)
                .onTapGesture {
                    withAnimation(.snappy) {
                        selectedTab = tab
                    }
                }
            }
        }
        
        /// Scrollable Active Tab Indicator
        .background() {
            GeometryReader {
                let size = $0.size
                let capsuleWidth = size.width / CGFloat(Tab.allCases.count)
                
                Capsule()
                    .fill(scheme == .dark ? .black : .white)
                    .frame(width: capsuleWidth)
                    .offset(x: tabProgress * (size.width - capsuleWidth))
            }
        }
        .background(.gray.opacity(0.1), in: .capsule)
        .padding(.horizontal, 15)
    }
    
    // Sample View for Demonstrating Scrollabel Tab Bar Indicator
    @ViewBuilder
    func SampleView(_ color: Color) -> some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: GridItem(), count: 2), content: {
                ForEach(1...2,id: \.self) { _ in
                //ForEach(1...10,id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 15)
                        .fill(color.gradient)
                        .frame(height: 150)
                        .overlay {
                            VStack(alignment: .leading) {
                                Circle()
                                    .fill(.white.opacity(0.25))
                                    .frame(width:50, height: 50)
                                
                                VStack(alignment: .leading, spacing: 6 ) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.white.opacity(0.25))
                                        .frame(width: 80, height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.white.opacity(0.25))
                                        .frame(width: 60, height: 8)
                                    
                                    Spacer()
                                    
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.white.opacity(0.25))
                                        .frame(width: 40, height: 8)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                            }
                            .padding(15)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                }
                
            })
            .padding(15)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .mask {
                Rectangle()
                    .padding(.bottom, -100)
            }
        }
    }
}

#Preview {
    ContentView()
}
