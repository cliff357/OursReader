//
//  SideMenu.swift
//  OursReader
//
//  Created by Autotoll Developer on 20/3/2024.
//

import SwiftUI

struct SideMenu: View {
    @Binding var isShowing: Bool
    @State private var selectedOption: SideMenuOptionModel?
    
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
                                } label: {
                                    SideMenuRowView(option: option, selectedOption: $selectedOption)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .frame(width: 270, alignment: .leading)
                    .background(.white) //TODO get background color
                    
                    Spacer()
                    
                    
                }
                
            }
        }
        .transition(.move(edge: .leading))
        .animation(.bouncy,value: isShowing)
    }
}


#Preview {
    SideMenu(isShowing: .constant(true))
}
