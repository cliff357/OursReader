//
//  UnderlineTextField.swift
//  OursReader
//
//  Created by Cliff Chan on 2/4/2024.
//

import SwiftUI

struct UnderlineTextField: View {
    let icon: String
    let placeHolder: String
    let keyboardType: UIKeyboardType
    
    @Binding var text: String
    
    @State private var width = CGFloat.zero
    @State private var labelWidth = CGFloat.zero
    
    var body: some View {
        HStack {
            TextField("", text: $text)
                .foregroundColor(.white)
                .font(GilroyFont(isBold: true, size: 20))
                .keyboardType(keyboardType)
                .padding(EdgeInsets(top: 15, leading: 60, bottom: 15, trailing: 60))
                .overlay {
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            width = geo.size.width
                        }
                    }
                }
        }
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .trim(from: 0, to: 0.55)
                    .stroke(.gray, lineWidth: 1)
                
                RoundedRectangle(cornerRadius: 5)
                    .trim(from: 0.495 + (0.44 * (labelWidth / width)), to: 1)
                    .stroke(.gray, lineWidth: 1)
                
                HStack {
                    Image(systemName: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 34, height: 34)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                
                Text(placeHolder)
                    .overlay {
                        GeometryReader { geo in
                            Color.clear.onAppear {
                                labelWidth = geo.size.width
                            }
                        }
                    }
                    .padding(2)
                    .font(GilroyFont(isBold: true, size: 13))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .offset(x: 20, y: -10)
            }
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
    UnderlineTextField(icon: "lock", placeHolder: "Username",keyboardType: .numberPad, text: .constant(""))
}
