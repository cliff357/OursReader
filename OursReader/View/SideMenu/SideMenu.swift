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
    
    var version: String {
            // 從專案的 Info.plist 中取得版本號
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                return "v\(version) (\(build))" // 格式：v1.0.0 (1)
            }
            return "版本資訊無法取得"
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
                                    isShowing = false
                                } label: {
                                    SideMenuRowView(option: option, selectedOption: $selectedOption)
                                }
                            }
                        }
                        Spacer()
                        Button {
                            isShowing = false
                            UserAuthModel.shared.signOut()
                        } label: {
                            HStack {
                                Text(LM.Key.logout())
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.green1)
                                    .cornerRadius(10)
                            }
                        }
                        Text(version)
                            .foregroundColor(Color.black)
                    }
                    .padding()
                    .frame(width: 270, alignment: .leading)
                    .background(Color.flesh1)
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
