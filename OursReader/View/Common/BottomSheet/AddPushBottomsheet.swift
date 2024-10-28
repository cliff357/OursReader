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
                Section(header: Text("通知")) {
                    TextField("標題", text: $pushTitle)
                        .submitLabel(pushBody.isEmpty ? .next : .done)
                        .onSubmit {
                            handleConfirm()
                        }

                    TextField("內容", text: $pushBody)
                        .submitLabel(pushTitle.isEmpty ? .next : .done)
                        .onSubmit {
                            handleConfirm()
                        }
                }
            }
            .navigationTitle("新增通知")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("搞掂") {
                        handleConfirm()
                    }
                    .disabled(pushTitle.isEmpty || pushBody.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("唔整住") {
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
            print("請填寫標題和內容")
        }
    }
}
