//
//  GeneralBottomSheet.swift
//  OursReader
//
//  Created by Cliff Chan on 25/5/2024.
//

import SwiftUI

struct GeneralBottomSheet<Content: View>: View {
    var content: Content
    var tapBackgroundAction: () -> Void
    var isShowing: Bool
    let contentPadding: EdgeInsets
    
    init(@ViewBuilder content: () -> Content,
         tapBackgroundAction: @escaping () -> Void,
         isShowing: Bool,
         padding: EdgeInsets = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)) {
        self.content = content()
        self.tapBackgroundAction = tapBackgroundAction
        self.isShowing = isShowing
        self.contentPadding = padding
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isShowing {
                    Color.black.opacity(0.75).ignoresSafeArea()
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            withAnimation {
                                tapBackgroundAction()
                            }
                        }
                    VStack(spacing: 0) {
                        Spacer()
                        content
                            .padding(contentPadding)
                            .frame(width: geometry.size.width)
                            .background(.white)
                            .cornerRadius(16, corners: [.topLeft, .topRight])
                        Color.white
                            .frame(height: geometry.safeAreaInsets.bottom)
                    }
                    .padding(.top, UINavigationController().navigationBar.frame.height)
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .transition(.move(edge: .bottom))
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .animation(.easeInOut, value: isShowing)
        }
    }
}

struct GeneralBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        GeneralBottomSheet(content: {
            GeneralErrorReminder(reminderData: ReminderData(title: "title", desc: "desc", buttons: []), isPresent: .constant(true))
        }, tapBackgroundAction: {
            
        }, isShowing: true)
    }
}
