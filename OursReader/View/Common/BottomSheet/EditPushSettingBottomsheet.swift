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
                Section(header: Text("通知")) {
                    TextField("標題", text: $editedTitle)
                    TextField("內容", text: $editedBody)
                }

                Button {
                    showDeleteAlert = true
                } label: {
                    Label("移除通知", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("修改通知")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("搞掂") {
                        handleConfirm()
                    }
                    .disabled(editedTitle.isEmpty || editedBody.isEmpty) // 防止空資料
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("唔整住") {
                        dismiss()
                    }
                }
            }
            .alert("確認刪除", isPresented: $showDeleteAlert) {
                Button("刪除", role: .destructive) {
                    viewModel.removePushSetting(withID: push.id) { _ in
                        dismiss()
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("你確定要移除這個通知嗎？此操作無法復原。")
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
