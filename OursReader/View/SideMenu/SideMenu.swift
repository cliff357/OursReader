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
                                    isShowing = false
                                } label: {
                                    SideMenuRowView(option: option, selectedOption: $selectedOption)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .frame(width: 270, alignment: .leading)
                    .background(Color.menu_bkgd)
                    Spacer()
                }
                .transition(.move(edge: .leading))
                
            }
        }
        .animation(.easeIn,value: isShowing)
    }
}


#Preview {
    SideMenu(isShowing: .constant(true), selectedTab: .constant(SideMenuOptionModel.dashboard))
}
