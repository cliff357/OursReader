//
//  AddPushBottomsheet.swift
//  OursReader
//
//  Created by Cliff Chan on 13/10/2024.
//

import SwiftUI

struct HalfPresentationDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        return max(20, context.maxDetentValue * 0.7)
    }
}

struct AddPushBottomSheet: View {
    @Binding var pushTitle: String
    @Binding var pushBody: String
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(String(localized:"push_notification"))) {
                    TextField(String(localized:"push_title"), text: $pushTitle)
                        .submitLabel(pushBody.isEmpty ? .next : .done)
                        .onSubmit {
                            handleConfirm()
                        }

                    TextField(String(localized:"push_content"), text: $pushBody)
                        .submitLabel(pushTitle.isEmpty ? .next : .done)
                        .onSubmit {
                            handleConfirm()
                        }
                }
            }
            .navigationTitle(String(localized:"push_add_new"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized:"push_done")) {
                        handleConfirm()
                    }
                    .disabled(pushTitle.isEmpty || pushBody.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized:"push_cancel")) {
                        dismiss()
                    }
                }
            }
            .presentationDetents([.custom(HalfPresentationDetent.self)/*, .fraction(0.5)*/])
            .padding(.bottom, 0)
        }
    }

    private func handleConfirm() {
        if !pushTitle.isEmpty && !pushBody.isEmpty {
            onSave()
            dismiss()
        } else {
            print(String(localized:"push_please_fill_fields"))
        }
    }
}
