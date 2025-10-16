//
//  EditPushSettingBottomsheet.swift
//  OursReader
//
//  Created by Cliff Chan on 13/10/2024.
//

import SwiftUI

// MARK: - Edit Push Setting Content
struct EditPushSettingContent: BaseSheetContent {
    @ObservedObject var viewModel: PushSettingListViewModel
    let push: Push_Setting
    
    @State private var editedTitle: String
    @State private var editedBody: String
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: PushSettingListViewModel, push: Push_Setting) {
        self.viewModel = viewModel
        self.push = push
        _editedTitle = State(initialValue: push.title ?? "")
        _editedBody = State(initialValue: push.body ?? "")
    }
    
    var title: String {
        String(localized: "push_edit")
    }
    
    var isFormValid: Bool {
        !editedTitle.isEmpty && !editedBody.isEmpty
    }
    
    var primaryButtonTitle: String {
        String(localized: "push_done")
    }
    
    var primaryButtonAction: () -> Void {
        return {
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
            }
        }
    }
    
    var content: AnyView {
        AnyView(
            VStack(spacing: 20) {
                // Title Input
                SheetInputSection(
                    title: String(localized: "push_title"),
                    placeholder: String(localized: "push_title"),
                    text: $editedTitle,
                    isRequired: true
                )
                
                // Body Input
                SheetInputSection(
                    title: String(localized: "push_content"),
                    placeholder: String(localized: "push_content"),
                    text: $editedBody,
                    isRequired: true,
                    isMultiline: true
                )
                
                // Delete Button
                Button {
                    showDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text(String(localized: "push_remove"))
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
                }
                .alert(String(localized: "push_confirm_delete"), isPresented: $showDeleteAlert) {
                    Button(String(localized: "push_delete"), role: .destructive) {
                        viewModel.removePushSetting(withID: push.id) { _ in
                            dismiss()
                        }
                    }
                    Button(String(localized: "push_cancel"), role: .cancel) {}
                } message: {
                    Text(String(localized: "push_delete_confirm_message"))
                }
            }
        )
    }
    
    var body: some View {
        content
    }
}

// MARK: - Main View
struct EditPushSettingBottomsheet: View {
    @ObservedObject var viewModel: PushSettingListViewModel
    let push: Push_Setting
    
    var body: some View {
        BaseSheetView(
            sheetContent: EditPushSettingContent(
                viewModel: viewModel,
                push: push
            )
        )
    }
}
