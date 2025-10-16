//
//  AddPushBottomsheet.swift
//  OursReader
//
//  Created by Cliff Chan on 13/10/2024.
//

import SwiftUI

// MARK: - AddPush 內容實現
struct AddPushContent: BaseSheetContent {
    @Binding private var pushTitle: String
    @Binding private var pushBody: String
    let onSave: () -> Void
    
    init(
        pushTitle: Binding<String>,
        pushBody: Binding<String>,
        onSave: @escaping () -> Void
    ) {
        self._pushTitle = pushTitle
        self._pushBody = pushBody
        self.onSave = onSave
    }
    
    var title: String { String(localized: "push_add_new") }
    var primaryButtonTitle: String { String(localized: "push_done") }
    var isFormValid: Bool {
        !pushTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !pushBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var primaryButtonAction: () -> Void { onSave }
    
    var content: AnyView {
        AnyView(
            VStack(spacing: 20) {
                SheetInputSection(
                    title: "Notification Title",
                    placeholder: "Enter notification title",
                    text: $pushTitle,
                    isRequired: true
                )
                
                SheetInputSection(
                    title: "Notification Message",
                    placeholder: "Enter notification message",
                    text: $pushBody,
                    isRequired: true,
                    isMultiline: true
                )
            }
        )
    }
    
    // 需要明確實現 View 協議的 body
    var body: some View {
        content
    }
}

// MARK: - 自定義 Presentation Detent
struct HalfPresentationDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        return max(20, context.maxDetentValue * 0.7)
    }
}

// MARK: - AddPushBottomSheet 使用基類
struct AddPushBottomSheet: View {
    @Binding var pushTitle: String
    @Binding var pushBody: String
    let onSave: () -> Void
    
    var body: some View {
        BaseSheetView(
            sheetContent: AddPushContent(
                pushTitle: $pushTitle,
                pushBody: $pushBody,
                onSave: onSave
            )
        )
        .presentationDetents([.custom(HalfPresentationDetent.self)])
    }
}

#Preview {
    AddPushBottomSheet(
        pushTitle: .constant(""),
        pushBody: .constant(""),
        onSave: { print("Save notification") }
    )
}
