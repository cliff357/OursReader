//
//  ORTextField.swift
//  OursReader
//
//  Created by Cliff Chan on 21/4/2024.
//

import SwiftUI

struct ORTextField: View {
    @Binding var text: String
    var placeholder: String
    var floatingPrompt: String
    var isSecure: Bool?
    
    var body: some View {
        FloatingPromptTextField(text: $text, isSecure: isSecure ?? false) {
            Text(placeholder)
                .foregroundStyle(ColorManager.shared.red1)
        }
        .floatingPrompt {
            Text(floatingPrompt)
                .foregroundStyle(ColorManager.shared.green1)
        }
        .textFieldForegroundStyle(ColorManager.shared.green1)
        .padding(10)
        .background(
            ColorManager.shared.background,
            in: RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
    }
}


#Preview {
    ORTextField(text: .constant("yooo"), placeholder: "testing", floatingPrompt: "floating")
}
