//
//  GeneralReminder.swift
//  OursReader
//
//  Created by Cliff Chan on 25/5/2024.
//

import SwiftUI

struct GeneralReminderRowTitle: View {
    var title: String
    var body: some View {
        Text(title)
            .font(.workSansMedium24)
            .foregroundColor(.blue)
    }
}

struct GeneralReminderRowDescription: View {
    var desc: String
    var body: some View {
        Text(desc)
            .font(.workSansMedium16)
            .foregroundColor(.blue)
            .kerning(0.16)
    }
}

struct GeneralReminderRowButton: View {
    var buttonData: GeneralButtonData
    var body: some View {
        GeneralButton(title: buttonData.title,
                      style: buttonData.style,
                      isEnabled: buttonData.isEnabled,
                      leftImage: buttonData.leftImage,
                      rightImage: buttonData.rightImage,
                      action: buttonData.action)
    }
}

struct GeneralReminder: View {
    let reminderData: ReminderData
    @Binding var isPresent: Bool
    
    var body: some View {
        DynamicHeightReminder(canDismissByGesture: reminderData.canDismissByGesture) {
            VStack {
                GeneralReminderRowTitle(title: reminderData.title)
                    .padding(.bottom, 10)
                    .padding(.top, 24)
                
                GeneralReminderRowDescription(desc: reminderData.desc)
                
                Spacer(minLength: 100)
                
                ForEach(reminderData.buttons) { buttonData in
                    let newButtonData = GeneralButtonData(id: buttonData.id,
                                                          title: buttonData.title,
                                                          style: buttonData.style,
                                                          isEnabled: buttonData.isEnabled,
                                                          leftImage: buttonData.leftImage,
                                                          rightImage: buttonData.rightImage,
                                                          closeReminder: buttonData.closeReminder,
                                                          action: {
                        if buttonData.closeReminder {
                            isPresent = false
                        }
                        buttonData.action()
                    })
                    
                    GeneralReminderRowButton(buttonData: newButtonData)
                }
            }
        }
    }
}

public extension View {
    /// Need to wrap main view in NavigationView to cover navigation bar
    func customReminderBottomSheet<Content>(showReminder: Bool,
                                            padding: EdgeInsets = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
                                            onTapBackgroundAction: (() -> Void)? = nil,
                                            content: @escaping () -> Content) -> some View where Content: View {
        ZStack {
            self
            GeneralBottomSheet(content: {
                content()
            }, tapBackgroundAction: {
                if let onTapBackgroundAction = onTapBackgroundAction {
                    onTapBackgroundAction()
                }
            }, isShowing: showReminder, padding: padding)
        }
    }
}

struct GeneralReminder_Previews: PreviewProvider {
    static var previews: some View {
        GeneralBottomSheet(content: {
            GeneralReminder(reminderData: ReminderData(title: "title", desc: "desc", buttons: [
                GeneralButtonData(title: "A", style: .fill, action: {
                    
                })
            ]), isPresent: .constant(true))
        }, tapBackgroundAction: {
            
        }, isShowing: ReminderManager.shared.showReminder)
        .customReminderBottomSheet(showReminder: false, onTapBackgroundAction: {
            
        }, content: {
            VStack(spacing: 0) {
                GeneralReminderRowTitle(title: "title")
                    .padding(.bottom, 10)

                Spacer()
                    .frame(maxHeight: 100)

                GeneralReminderRowButton(buttonData: GeneralButtonData(title: "button", style: .fill, action: {
                }))
            }
        })
    }
}

struct InnerHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    public func sheetCornerRadius(cornerRadius: CGFloat) -> some View {
        if #available(iOS 16.4, *) {
            return self.presentationCornerRadius(cornerRadius)
        }
        
        return self
    }
}
