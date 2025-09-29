import SwiftUI

struct ProgressSyncIndicator: View {
    let isVisible: Bool
    let message: String
    let isError: Bool
    
    init(isVisible: Bool, message: String = "Saving...", isError: Bool = false) {
        self.isVisible = isVisible
        self.message = message
        self.isError = isError
    }
    
    var body: some View {
        if isVisible {
            HStack(spacing: 8) {
                if !isError {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                }
                
                Text(message)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(20)
            .transition(.opacity.combined(with: .scale))
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressSyncIndicator(isVisible: true, message: "Saving...")
        ProgressSyncIndicator(isVisible: true, message: "Saved!", isError: false)
        ProgressSyncIndicator(isVisible: true, message: "Save failed", isError: true)
    }
    .padding()
    .background(Color.gray.opacity(0.3))
}
