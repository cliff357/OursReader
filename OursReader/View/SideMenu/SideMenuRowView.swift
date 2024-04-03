//
//  SideMenuRowView.swift
//  OursReader
//
//  Created by Cliff Chan on 22/3/2024.
//

import SwiftUI

struct SideMenuRowView: View {
    let option: SideMenuOptionModel
    @Binding var selectedOption: SideMenuOptionModel?
    
    private var isSelected: Bool {
        return selectedOption == option
    }
    
    var body: some View {
        HStack {
            Image(systemName: option.systemImageName)
                .imageScale(.small)
            Text(option.title)
                .font(.subheadline)
            Spacer()
        }
        .padding(.leading)
        .foregroundStyle(isSelected ? .white : .white)
        .frame(width: 216, height: 44)
        .background(isSelected ? Color.button_selected : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        
    }
}

#Preview {
    SideMenuRowView(option: .dashboard, selectedOption: .constant(.dashboard))
}
