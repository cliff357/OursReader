//
//  SideMenuHeaderView.swift
//  OursReader
//
//  Created by Cliff Chan on 20/3/2024.
//

import SwiftUI

struct SideMenuHeaderView: View {
    @StateObject var user = UserAuthModel.shared
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .imageScale(.large)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.orange1)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(user.nickName)
                    .font(.subheadline)
                    .foregroundStyle(Color.green1)
                Text("Hello~")
                    .font(.footnote)
                    .foregroundStyle(Color.green1)
            }
        }
    }
}

#Preview {
    SideMenuHeaderView()
}
