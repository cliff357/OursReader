//
//  EditPushSettingBottomsheet.swift
//  OursReader
//
//  Created by Cliff Chan on 13/10/2024.
//

import SwiftUI

struct EditPushSettingBottomsheet: View {
    @ObservedObject var viewModel: PushSettingListViewModel
    var push: Push_Setting

    @Environment(\.dismiss) private var dismiss
    @State private var editedTitle: String
    @State private var editedBody: String
    @State private var showDeleteAlert = false

    init(viewModel: PushSettingListViewModel, push: Push_Setting) {
        self.viewModel = viewModel
        self.push = push
        _editedTitle = State(initialValue: push.title ?? "")
        _editedBody = State(initialValue: push.body ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(String(localized:"push_notification"))) {
                    TextField(String(localized:"push_title"), text: $editedTitle)
                    TextField(String(localized:"push_content"), text: $editedBody)
                }

                Button {
                    showDeleteAlert = true
                } label: {
                    Label(String(localized:"push_remove"), systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle(String(localized:"push_edit"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized:"push_done")) {
                        handleConfirm()
                    }
                    .disabled(editedTitle.isEmpty || editedBody.isEmpty) // 防止空資料
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized:"push_cancel")) {
                        dismiss()
                    }
                }
            }
            .alert(String(localized:"push_confirm_delete"), isPresented: $showDeleteAlert) {
                Button(String(localized:"push_delete"), role: .destructive) {
                    viewModel.removePushSetting(withID: push.id) { _ in
                        dismiss()
                    }
                }
                Button(String(localized:"push_cancel"), role: .cancel) {}
            } message: {
                Text(String(localized:"push_delete_confirm_message"))
            }
        }
    }

    private func handleConfirm() {
        viewModel.editPushSetting(
            withID: push.id,
            newTitle: editedTitle,
            newBody: editedBody
        ) { result in
            switch result {
            case .success:
                print("Push Notification Updated")
            case .failure(let error):
                print("Error updating Push Notification: \(error.localizedDescription)")
            }
            dismiss()
        }
    }
}

//#Pre00
