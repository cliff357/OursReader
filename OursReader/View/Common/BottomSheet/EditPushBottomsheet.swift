//
//  EditPushBottomsheet.swift
//  OursReader
//
//  Created by Cliff Chan on 13/10/2024.
//

import SwiftUI


struct HalfPresentationDetent: CustomPresentationDetent {
    // 1
    static func height(in context: Context) -> CGFloat? {
        // 2
        return max(20, context.maxDetentValue * 0.5)
    }
}

struct EditPushBottomSheet: View {
    @Binding var pushTitle: String
    @Binding var pushBody: String
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Edit Notification")) {
                    TextField("Title", text: $pushTitle)
                    TextField("Body", text: $pushBody)
                }
            }
            .navigationTitle("Edit Notification")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .presentationDetents([.custom(HalfPresentationDetent.self),.large]) // 設置為半頁顯示
        }
    }
}
