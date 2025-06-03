//
//  GeneralErrorReminder.swift
//  OursReader
//
//  Created by Cliff Chan on 25/5/2024.
//

import SwiftUI

struct GeneralErrorReminder: View {
    let reminderData: ReminderData
    @Binding var isPresent: Bool
    
    var body: some View {
        DynamicHeightReminder(canDismissByGesture: false) {
            VStack {
                Image(systemName: "x.circle")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .padding(.bottom, 16)
                Text(reminderData.title)
                    .font(FontHelper.shared.workSansMedium24)
                    .foregroundColor(.blue)
                    .padding(.bottom, 10)
                Text(reminderData.desc)
                    .font(FontHelper.shared.workSansMedium16)
                    .foregroundColor(.black)
                    .kerning(0.16)
                
                Spacer(minLength: 100)
                
                VStack(spacing: 16) {
                    ForEach(reminderData.buttons) { button in
                        GeneralButton(title: button.title, style: button.style) {
                            if button.closeReminder {
                                isPresent = false
                            }
                            button.action()
                        }
                    }
                }
            }
        }
    }
}

struct DynamicHeightReminder<Content: View>: View {
    @State private var sheetHeight: CGFloat = .zero
    let canDismissByGesture: Bool
    var content: () -> Content
    
    var body: some View {
        content()
        .padding(EdgeInsets(top: 24, leading: 20, bottom: 20, trailing: 20))
        .background(.white)
        .overlay {
            GeometryReader { geometry in
                Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
            }
        }
        .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
            sheetHeight = newHeight
        }
        .fixedSize(horizontal: false, vertical: true)
        .presentationDetents([.height(sheetHeight)])
        .highPriorityGesture(DragGesture())
        .sheetCornerRadius(cornerRadius: 16)
        .interactiveDismissDisabled(!canDismissByGesture)
    }
}

public extension View {
    func reminderBottomSheet(showReminder: Binding<Bool>) -> some View {
        self
            .sheet(isPresented: showReminder) {
                ReminderManager.shared.onDismiss()
            } content: {
                if let reminderData = ReminderManager.shared.reminderData {
                    GeneralReminder(reminderData: reminderData, isPresent: showReminder)
                }
            }
    }
    
    func errorReminderBottomSheet(showReminder: Binding<Bool>) -> some View {
        self
            .sheet(isPresented: showReminder) {
                ErrorReminderManager.shared.onDismiss()
            } content: {
                if let reminderData = ErrorReminderManager.shared.reminderData {
                    GeneralErrorReminder(reminderData: reminderData, isPresent: showReminder)
                }
            }
    }
}

struct GeneralErrorReminder_Previews: PreviewProvider {
    static var previews: some View {
        GeneralErrorReminder(reminderData: ReminderData(title: "aaa", desc: "ccc", buttons: []), isPresent: .constant(true))
    }
}
