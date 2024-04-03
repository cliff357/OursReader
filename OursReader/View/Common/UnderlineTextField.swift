//
//  UnderlineTextField.swift
//  OursReader
//
//  Created by Cliff Chan on 2/4/2024.
//

import SwiftUI

struct UnderlineTextField: View {
    let placeholder: String
    let keyboardType: UIKeyboardType
    
    @Binding var text: String
    
    @State private var width = CGFloat.zero
    @State private var labelWidth = CGFloat.zero
    
    var body: some View {
        TextField(placeholder, text: $text)
                .foregroundColor(.gray)
                .font(.system(size: 20))
                .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .trim(from: 0, to: 0.55)
                            .stroke(.gray, lineWidth: 1)
                        RoundedRectangle(cornerRadius: 5)
                            .trim(from: 0.565 + (0.44 * (labelWidth / width)), to: 1)
                            .stroke(.gray, lineWidth: 1)
                        Text(placeholder)
                            .foregroundColor(.gray)
                            .overlay( GeometryReader { geo in Color.clear.onAppear { labelWidth = geo.size.width }})
                            .padding(2)
                            .font(.caption)
                            .frame(maxWidth: .infinity,
                                   maxHeight: .infinity,
                                   alignment: .topLeading)
                            .offset(x: 20, y: -10)

                    }
                }
                .overlay( GeometryReader { geo in Color.clear.onAppear { width = geo.size.width }})
                .onChange(of: width) { _ in
                    print("Width: ", width)
                }
                .onChange(of: labelWidth) { _ in
                    print("labelWidth: ", labelWidth)
                }
    }
}


func GilroyFont(isBold: Bool = false, size: CGFloat) -> Font {
    if isBold {
        return Font.custom("Gilroy-ExtraBold", size: size)
    }else {
        return Font.custom("Gilroy-Light", size: size)
    }
}

#Preview {
    UnderlineTextField(placeholder: "Username",keyboardType: .numberPad, text: .constant(""))
}
