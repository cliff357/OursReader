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
                Text(friend.name ?? "Friend")
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

//#Preview {
//    FriendRow(friend: UserObject(id: "", name: "aaa", userID: "", fcmToken: "", email: "clifsifld@gmail.com", login_type: LoginType.apple, connections_userID: nil, push_setting: nil))
//}
