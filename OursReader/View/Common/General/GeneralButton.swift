//
//  GeneralButton.swift
//  OursReader
//
//  Created by Cliff Chan on 25/5/2024.
//

import SwiftUI

struct GeneralButtonData: Identifiable {
    var id: UUID = UUID()
    var title: String
    var style: GeneralButton.GeneralButtonStyle
    var isEnabled: Bool = true
    var leftImage: UIImage?
    var rightImage: UIImage?
    var closeReminder: Bool = true
    var action: () -> Void
}

struct GeneralButton: View, Identifiable {
    var id: UUID = UUID()
    
    enum GeneralButtonStyle {
        case fill
        case stroke
    }

    var title: String
    var style: GeneralButtonStyle
    var isEnabled: Bool = true
    var leftImage: UIImage?
    var rightImage: UIImage?
    var action: () -> Void
    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Button {
                self.action()
            }label: {
                Text(title)
                    .modifier(GeneralButtonTextModifier(style: style))
                    .modifier(GeneralButtonLeftImageModifier(image: leftImage))
                    .modifier(GeneralButtonRightImageModifier(image: rightImage))
                    .font(FontHelper.shared.workSansMedium16)
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, minHeight: 24)

            }
            
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .modifier(GeneralButtonBackgroundModifier(style: style))
        .cornerRadius(16)
        .disabled(!isEnabled)
    }
}

struct GeneralButton_Previews: PreviewProvider {
    static var previews: some View {
        GeneralButton(title: String(localized:"login"), style: .fill, leftImage: UIImage(named: "Google"), rightImage: UIImage(named: "Google")) {

        }
    }
}

struct GeneralButtonTextModifier: ViewModifier {
    let style: GeneralButton.GeneralButtonStyle
    @ViewBuilder
    func body(content: Content) -> some View {
        switch style {
        case .fill:
            content
                .foregroundColor(.white)
        case .stroke:
            content
                .foregroundColor(.blue)
        }
    }
}

struct GeneralButtonLeftImageModifier: ViewModifier {
    var image: UIImage?
    @ViewBuilder
    func body(content: Content) -> some View {
        if let image = image {
            HStack(spacing: 10) {
                Image(uiImage: image)
                content
            }
        } else {
            content
        }
    }
}

struct GeneralButtonRightImageModifier: ViewModifier {
    var image: UIImage?
    @ViewBuilder
    func body(content: Content) -> some View {
        if let image = image {
            HStack(spacing: 10) {
                content
                Image(uiImage: image)
            }
        } else {
            content
        }
    }
}

struct GeneralButtonBackgroundModifier: ViewModifier {
    let style: GeneralButton.GeneralButtonStyle
    @Environment(\.isEnabled) var isEnabled

    @ViewBuilder
    func body(content: Content) -> some View {
        switch style {
        case .fill:
            content
                .background(isEnabled ? Color.blue : Color.black)
        case .stroke:
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .inset(by: 0.5)
                        .strokeBorder(Color.blue, lineWidth: 1)
                )
        }
    }
}

struct CopyButton: View {
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text("copy")
                .font(FontHelper.shared.workSansMedium14)
                .foregroundColor(.blue)
                .kerning(0.4)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .offset(y: 1)
                        .foregroundColor(.blue)
                    , alignment: .bottom)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
