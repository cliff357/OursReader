//
//  DividerWithText.swift
//  OursReader
//
//  Created by Cliff Chan on 2/4/2024.
//

import SwiftUI

struct DividerWithText: View {
    let label: String
    let padding: CGFloat
    let color: Color
    let isVertical: Bool
    init(label: String, padding: CGFloat = 20, color: Color = .gray, isVertical: Bool = false) {
        self.label = label
        self.padding = padding
        self.color = color
        self.isVertical = isVertical
    }
    var body: some View {
        let layout = isVertical ?
        AnyLayout(VStackLayout()) : AnyLayout(HStackLayout())
        
        layout {
            dividerLine
            Text(label).foregroundColor(color)
            dividerLine
        }
    }
    private var dividerLine: some View {
        let layout = isVertical ?
        AnyLayout(HStackLayout()) : AnyLayout(VStackLayout())
        
        return layout { Divider().background(color) }.padding(padding)
    }
}


#Preview {
    DividerWithText(label: "hello")
}
