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
    @FocusState private var isTitleFocused: Bool // 追蹤標題 TextField 的焦點
    @FocusState private var isBodyFocused: Bool // 追蹤內容 TextField 的焦點
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("通知")) {
                    TextField("標題", text: $pushTitle)
                        .submitLabel(pushBody.isEmpty ? .next : .done) // 根據 body 是否為空設置提交標籤
                        .focused($isTitleFocused) // 將焦點綁定到 isTitleFocused
                        .onSubmit {
                            if pushBody.isEmpty {
                                isBodyFocused = true // 如果 body 是空，則焦點轉移到 body
                            } else {
                                handleConfirm() // 如果兩者都有，調用 confirm
                            }
                        }
                    
                    TextField("內容", text: $pushBody)
                        .submitLabel(pushTitle.isEmpty ? .next : .done) // 根據 title 是否為空設置提交標籤
                        .focused($isBodyFocused) // 將焦點綁定到 isBodyFocused
                        .onSubmit {
                            if pushTitle.isEmpty {
                                isTitleFocused = true // 如果 title 是空，則焦點轉移到 title
                            } else {
                                handleConfirm() // 如果兩者都有，調用 confirm
                            }
                        }
                }
            }
            .navigationTitle("新增通知")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("搞掂") {
                        handleConfirm()
                    }
                    .disabled(pushTitle.isEmpty || pushBody.isEmpty) // 禁用按鈕
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("唔整住") {
                        dismiss()
                    }
                }
            }
            .presentationDetents([.custom(HalfPresentationDetent.self),.fraction(0.3)])
            .padding(.bottom, 0) // 確保底部無額外填充
            .onAppear {
                // 在視圖出現時，保持焦點不改變底部視圖的位置
                if isTitleFocused {
                    isBodyFocused = false
                } else if isBodyFocused {
                    isTitleFocused = false
                }
            }
        }
    }
    
    // 處理確認按鈕
    private func handleConfirm() {
        if !pushTitle.isEmpty && !pushBody.isEmpty {
            onSave() // 調用 onSave() 來儲存資料
            dismiss() // 關閉視圖
        } else {
            // 提示用戶填寫必填項
            print("請填寫標題和內容")
        }
    }
}
