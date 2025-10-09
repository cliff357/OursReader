import SwiftUI

struct AddPushSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var body = ""
    @ObservedObject var viewModel: PushSettingListViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // 添加背景色
                ColorManager.shared.flesh1.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notification Title *")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            TextField("Enter notification title", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Body Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notification Message *")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            TextField("Enter notification message", text: $body, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        
                        // Save Button
                        Button(action: {
                            viewModel.addPushSetting(title: title, body: body)
                            dismiss()
                        }) {
                            HStack {
                                Text("Save Notification")
                                Image(systemName: "bell.badge.fill")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(isFormValid ? ColorManager.shared.red1 : Color.gray)
                            .cornerRadius(10)
                        }
                        .disabled(!isFormValid)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Notification")
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
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    AddPushSettingView(viewModel: PushSettingListViewModel())
}