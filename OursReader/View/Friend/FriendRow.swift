//
//  FriendRow.swift
//  OursReader
//
//  Created by Cliff Chan on 18/5/2024.
//

import SwiftUI

struct FriendRow: View {
    let friend: UserObject
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image or placeholder
            ZStack {
                Circle()
                    .fill(ColorManager.shared.rice_white)
                    .overlay(
                        Circle()
                            .strokeBorder(ColorManager.shared.red1, lineWidth: 2)
                    )
                    .frame(width: 50, height: 50)
                
                Text(friend.name?.prefix(1).uppercased() ?? "?")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(ColorManager.shared.red1)
            }
            
            VStack(alignment: .leading) {
                Text(friend.name ?? String(localized:"friend_default_name"))
                    .font(.headline)
                    .foregroundColor(ColorManager.shared.red1)
                
                if let email = friend.email, !email.isEmpty {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(ColorManager.shared.red1.opacity(0.7))
                }
            }
            
            Spacer()
        }
        .padding()
        .background(ColorManager.shared.rice_white)
        .cornerRadius(10)
    }
}
