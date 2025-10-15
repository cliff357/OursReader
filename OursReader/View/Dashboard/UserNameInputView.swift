//
//  UserNameInputView.swift
//  OursReader
//
//  Created by Cliff Chan on 15/10/2025.
//

import SwiftUI

struct UserNameInputView: View {
    @Binding var userName: String
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            ColorManager.shared.background.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // 標題
                VStack(spacing: 10) {
                    // 🔧 修改：使用 App Icon
                    Image("AppIcon") // 使用 Assets 中的 AppIcon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22.5)) // iOS App Icon 圓角
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    Text(LocalizedStringKey("welcome_page_title"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text(LocalizedStringKey("welcome_page_nickname_prompt"))
                        .font(.body)
                        .foregroundColor(.black.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                // 輸入框
                VStack(spacing: 15) {
                    TextField(String(localized: "welcome_page_nickname_placeholder"), text: $userName)
                        .font(.title3)
                        .foregroundColor(.black) // 🔧 修改：輸入文字改為黑色
                        .accentColor(ColorManager.shared.red1) // 光標顏色
                        .padding()
                        .background(ColorManager.shared.rice_white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ColorManager.shared.red1.opacity(0.3), lineWidth: 1)
                        )
                    
                    // 確認按鈕
                    Button(action: {
                        if !userName.isEmpty {
                            onComplete()
                        }
                    }) {
                        Text(LocalizedStringKey("general_done"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(userName.isEmpty ? Color.gray : ColorManager.shared.red1)
                            .cornerRadius(12)
                    }
                    .disabled(userName.isEmpty)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .interactiveDismissDisabled() // 防止手勢關閉
    }
}
