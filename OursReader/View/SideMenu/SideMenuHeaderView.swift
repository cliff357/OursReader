//
//  SideMenuHeaderView.swift
//  OursReader
//
//  Created by Cliff Chan on 20/3/2024.
//

import SwiftUI

struct SideMenuHeaderView: View {
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
//                Text(UserAuthModel.shared.givenName)
//                    .onAppear(perform: {
//                        print(UserAuthModel.shared.givenName)
//                    })
//                    .foregroundStyle(.black)
                Text("cliffchan1993@hotmail.com")
                    .font(.subheadline)
                    .foregroundStyle(.red)
                Text("Hello~")
                    .font(.footnote)
                    .foregroundStyle(.black)
            }
        }
    }
}

#Preview {
    SideMenuHeaderView()
}
