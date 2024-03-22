//
//  SideMenuRowView.swift
//  OursReader
//
//  Created by Autotoll Developer on 22/3/2024.
//

import SwiftUI

struct SideMenuRowView: View {
    let option: SideMenuOptionModel
    
    var body: some View {
        HStack {
            Image(systemName: option.systemImageName)
                .imageScale(.small)
                .foregroundStyle(.black)
            Text(option.title)
                .font(.subheadline)
                .foregroundStyle(.black)
            
            Spacer()
        }
        .padding(.leading)
        .frame(height: 44)
        
    }
}

#Preview {
    SideMenuRowView(option: .dashboard)
}
