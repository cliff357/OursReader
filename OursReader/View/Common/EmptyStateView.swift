//
//  EmptyStateView.swift
//  OursReader
//
//  Created by Cliff Chan on 18/5/2024.
//

import SwiftUI 

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundColor(ColorManager.shared.red1.opacity(0.6))
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorManager.shared.red1)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(ColorManager.shared.red1.opacity(0.8))
                .padding(.horizontal, 40)
            
            Button(action: action) {
                Text(buttonTitle)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(ColorManager.shared.rice_white)
                    .foregroundColor(ColorManager.shared.red1)
                    .cornerRadius(8)
            }
            .padding(.top, 10)
        }
        .padding()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        EmptyStateView(
            icon: "person.2.slash",
            title: "No Friends Yet",
            message: "Add friends to connect and share stories together.",
            buttonTitle: "Add Friend",
            action: {}
        )
    }
}
