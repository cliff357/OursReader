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
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(user.givenName)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Text("Hello~")
                    .font(.footnote)
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview {
    SideMenuHeaderView()
}
