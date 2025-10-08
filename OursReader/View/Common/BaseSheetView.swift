import SwiftUI

// MARK: - 基礎彈出式視窗協議
protocol BaseSheetContent: View {
    var title: String { get }
    var content: AnyView { get }
    var isFormValid: Bool { get }
    var primaryButtonTitle: String { get }
    var primaryButtonAction: () -> Void { get }
}

// MARK: - 通用彈出式視窗基類
struct BaseSheetView<Content: BaseSheetContent>: View {
    @Environment(\.dismiss) private var dismiss
    let sheetContent: Content
    
    var body: some View {
        NavigationView {
            ZStack {
                // 統一背景色
                ColorManager.shared.flesh1.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        sheetContent.content
                        
                        // 統一主要操作按鈕
                        Button(action: {
                            sheetContent.primaryButtonAction()
                            dismiss()
                        }) {
                            HStack {
                                Text(sheetContent.primaryButtonTitle)
                                Image(systemName: "checkmark.circle.fill")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(sheetContent.isFormValid ? ColorManager.shared.red1 : Color.gray)
                            .cornerRadius(10)
                        }
                        .disabled(!sheetContent.isFormValid)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle(sheetContent.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
}

// MARK: - 通用輸入欄位組件
struct SheetInputSection: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let isRequired: Bool
    let isMultiline: Bool
    let helperText: String?
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isRequired: Bool = false,
        isMultiline: Bool = false,
        helperText: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.isRequired = isRequired
        self.isMultiline = isMultiline
        self.helperText = helperText
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title + (isRequired ? " *" : ""))
                .font(.headline)
                .foregroundColor(.black)
            
            if let helperText = helperText {
                Text(helperText)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if isMultiline {
                TextField(placeholder, text: $text, axis: .vertical)
                    .padding(12)
                    .background(Color.white)
                    .foregroundColor(.black) // 添加文字顏色為黑色
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .lineLimit(3...10)
            } else {
                TextField(placeholder, text: $text)
                    .padding(12)
                    .background(Color.white)
                    .foregroundColor(.black) // 添加文字顏色為黑色
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

#Preview {
    struct PreviewContent: BaseSheetContent {
        @State private var testText = ""
        
        var title: String = "預覽標題"
        var isFormValid: Bool = true
        var primaryButtonTitle: String = "確認"
        var primaryButtonAction: () -> Void = {}
        
        var content: AnyView {
            AnyView(
                VStack {
                    SheetInputSection(
                        title: "測試欄位",
                        placeholder: "輸入內容",
                        text: $testText,
                        isRequired: true
                    )
                }
            )
        }
        
        // 需要明確實現 View 協議的 body
        var body: some View {
            content
        }
    }
    
    return BaseSheetView(sheetContent: PreviewContent())
}
