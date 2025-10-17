import SwiftUI
import UserNotifications

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            ColorManager.shared.background.ignoresSafeArea()
            
            VStack {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // 帳戶設置
                        SettingsSectionView(title: "account_settings") {
                            VStack(spacing: 12) {
                                SettingsRowView(
                                    icon: "person.circle.fill",
                                    title: "user_profile",
                                    value: viewModel.userName,
                                    color: ColorManager.shared.red1
                                )
                                
                                SettingsRowView(
                                    icon: "envelope.fill",
                                    title: "email_address",
                                    value: viewModel.userEmail,
                                    color: .blue
                                )
                            }
                        }
                        
                        // 閱讀設置
                        SettingsSectionView(title: "reading_settings") {
                            VStack(spacing: 12) {
                                SettingsSliderRow(
                                    icon: "textformat.size",
                                    title: "font_size",
                                    value: $viewModel.fontSize,
                                    range: 12...24,
                                    color: ColorManager.shared.green1
                                )
                                .onChange(of: viewModel.fontSize) { oldValue, newValue in
                                    viewModel.saveFontSize(newValue)
                                }
                                
                                SettingsPickerRow(
                                    icon: "text.justify.left",
                                    title: "font_family",
                                    selection: $viewModel.selectedFont,
                                    options: viewModel.availableFonts,
                                    color: .orange
                                )
                                .onChange(of: viewModel.selectedFont) { oldValue, newValue in
                                    viewModel.saveFontFamily(newValue)
                                }
                                
                                // 字體預覽區域
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("font_preview")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text("Hello, World! 你好，世界！")
                                        .font(.system(size: viewModel.fontSize))
                                        .fontDesign(viewModel.fontDesign)
                                        .foregroundColor(.black)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // 🔧 修改：語言設置 - 禁用並顯示為中文
                        SettingsSectionView(title: "language_settings") {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.gray)
                                    .frame(width: 30)
                                
                                Text("app_language".localized)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text("繁體中文")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white)
                        }
                        
                        // 通知設置
                        SettingsSectionView(title: "notification_settings") {
                            VStack(spacing: 12) {
                                SettingsToggleRow(
                                    icon: "bell.fill",
                                    title: "enable_notifications",
                                    isOn: $viewModel.notificationsEnabled,
                                    color: .red
                                )
                                .onChange(of: viewModel.notificationsEnabled) { oldValue, newValue in
                                    viewModel.toggleNotifications(newValue)
                                }
                                
                                if viewModel.notificationsEnabled {
                                    SettingsToggleRow(
                                        icon: "book.fill",
                                        title: "reading_reminders",
                                        isOn: $viewModel.readingReminders,
                                        color: ColorManager.shared.red1
                                    )
                                }
                            }
                        }
                        
                        // 儲存空間
                        SettingsSectionView(title: "storage_management") {
                            VStack(spacing: 12) {
                                VStack(spacing: 8) {
                                    // 🔧 修改：顯示已使用和剩餘空間
                                    SettingsRowView(
                                        icon: "icloud.fill",
                                        title: "icloud_storage",
                                        value: viewModel.iCloudStorageDisplay,
                                        color: .blue
                                    )
                                    
                                    // 詳細統計
                                    if viewModel.isLoadingStorage {
                                        HStack {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                            Text("storage_calculating".localized)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal)
                                    } else if let stats = viewModel.storageStats {
                                        VStack(alignment: .leading, spacing: 6) {
                                            StorageStatRow(
                                                label: "storage_books_count",
                                                value: "\(stats.booksCount)",
                                                icon: "book.fill",
                                                color: ColorManager.shared.red1
                                            )
                                            
                                            StorageStatRow(
                                                label: "storage_total_size",
                                                value: stats.totalSizeFormatted,
                                                icon: "externaldrive.fill",
                                                color: .blue
                                            )
                                            
                                            StorageStatRow(
                                                label: "storage_avg_book_size",
                                                value: stats.averageSizeFormatted,
                                                icon: "chart.bar.fill",
                                                color: ColorManager.shared.green1
                                            )
                                            
                                            // 🔧 新增：剩餘空間
                                            if let remaining = viewModel.remainingStorage {
                                                StorageStatRow(
                                                    label: "storage_remaining",
                                                    value: remaining,
                                                    icon: "circle.dashed",
                                                    color: .orange
                                                )
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                        .background(Color.blue.opacity(0.05))
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                    }
                                    
                                    // 重新整理按鈕
                                    Button(action: {
                                        viewModel.refreshStorageUsage()
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.clockwise")
                                                .foregroundColor(.blue)
                                            Text("storage_refresh".localized)
                                                .foregroundColor(.black)
                                            Spacer()
                                            if viewModel.isLoadingStorage {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                            }
                                        }
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(10)
                                    }
                                    .disabled(viewModel.isLoadingStorage)
                                }
                            }
                        }
                        
                        // 關於
                        SettingsSectionView(title: "about_app") {
                            VStack(spacing: 12) {
                                SettingsRowView(
                                    icon: "info.circle.fill",
                                    title: "app_version",
                                    value: viewModel.appVersion,
                                    color: .gray
                                )
                            }
                        }
                        
                        // 登出按鈕
                        Button(action: {
                            viewModel.showLogoutAlert = true
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("auth_logout_button".localized)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(10)
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
            }
        }
        .alert("confirm_logout".localized, isPresented: $viewModel.showLogoutAlert) {
            Button("general_cancel".localized, role: .cancel) {}
            Button("auth_logout_button".localized, role: .destructive) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("userDidLogout"),
                    object: nil
                )
                UserAuthModel.shared.signOut()
                dismiss()
            }
        } message: {
            Text("logout_confirmation_message".localized)
        }
        .onAppear {
            viewModel.checkNotificationPermission()
        }
        .id(viewModel.languageChangeID)
    }
}

// MARK: - Settings Section View
struct SettingsSectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 🔧 修改：使用 LM.localized
            Text(title.localized)
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

// MARK: - Settings Row View
struct SettingsRowView: View {
    let icon: String
    let title: String
    let value: String?
    let color: Color
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        value: String? = nil,
        color: Color,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: { action?() }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                // 🔧 修改：使用 LM.localized
                Text(title.localized)
                    .foregroundColor(.black)
                    .foregroundColor(color)
                Spacer()
                
                if let value = value {
                    Text(value)
                        .foregroundColor(.gray)
                }
                Spacer()
                if action != nil {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .padding()
        }
        .disabled(action == nil)
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            // 🔧 修改：使用 LM.localized
            Text(title.localized)
                .foregroundColor(.black)
                .foregroundColor(color)
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
    }
}

// MARK: - Settings Slider Row
struct SettingsSliderRow: View {
    let icon: String
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                // 🔧 修改：使用 LM.localized
                Text(title.localized)
                    .foregroundColor(.black)
                    .foregroundColor(color)
                Spacer()
                
                Text("\(Int(value))")
                    .foregroundColor(.gray)
                    .monospacedDigit()
            }
            Spacer()
            Slider(value: $value, in: range, step: 1)
                .tint(color)
        }
        .padding()
    }
}

// MARK: - Settings Picker Row
struct SettingsPickerRow: View {
    let icon: String
    let title: String
    @Binding var selection: String
    let options: [String]
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            // 🔧 修改：使用 LM.localized
            Text(title.localized)
                .foregroundColor(.black)
                .foregroundColor(color)
            Spacer()
            
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
        .padding()
    }
}

// MARK: - Settings Navigation Row
struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                // 🔧 修改：使用 LM.localized
                Text(title.localized)
                    .foregroundColor(.black)
                    .foregroundColor(color)
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
        }
    }
}

// MARK: - Settings ViewModel
class SettingsViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var fontSize: Double = 16
    @Published var selectedFont: String = "System"
    @Published var notificationsEnabled: Bool = false
    @Published var readingReminders: Bool = true
    @Published var iCloudStorageUsed: String = "storage_calculating..."
    @Published var showLogoutAlert: Bool = false
    @Published var isLoadingStorage = false
    @Published var storageStats: StorageStatistics?
    @Published var remainingStorage: String?
    
    // 🔧 修改：固定語言為繁體中文
    @Published var selectedLanguage: String = "繁體中文"
    @Published var languageChangeID = UUID()
    
    var availableLanguages: [String] {
        return ["繁體中文"]
    }
    
    let availableFonts = ["System", "Rounded", "Serif", "Monospaced"]
    
    // 🔧 新增：顯示格式化的儲存空間資訊
    var iCloudStorageDisplay: String {
        if let stats = storageStats, let remaining = remainingStorage {
            return "\(stats.totalSizeFormatted) / \(remaining)"
        }
        return iCloudStorageUsed
    }
    
    // 🔧 新增：根據選擇的字體返回對應的 Font.Design
    var fontDesign: Font.Design {
        switch selectedFont {
        case "Rounded":
            return .rounded
        case "Serif":
            return .serif
        case "Monospaced":
            return .monospaced
        default:
            return .default
        }
    }
    
    var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "v\(version) (\(build))"
        }
        return "version_unavailable".localized
    }
    
    init() {
        loadUserInfo()
        loadSettings()
        refreshStorageUsage()
        checkNotificationPermission()
        loadCurrentLanguage()
    }
    
    private func loadUserInfo() {
        if let user = UserAuthModel.shared.getCurrentFirebaseUser() {
            userEmail = user.email ?? ""
            userName = user.displayName ?? user.email ?? ""
        }
    }
    
    private func loadSettings() {
        fontSize = UserDefaults.standard.double(forKey: "fontSize")
        if (fontSize == 0) { fontSize = 16 }
        selectedFont = UserDefaults.standard.string(forKey: "selectedFont") ?? "System"
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        readingReminders = UserDefaults.standard.bool(forKey: "readingReminders")
    }
    
    // 🔧 新增：保存字體大小到 UserDefaults 並發送通知
    func saveFontSize(_ size: Double) {
        UserDefaults.standard.set(size, forKey: "fontSize")
        NotificationCenter.default.post(
            name: NSNotification.Name("FontSizeDidChange"),
            object: nil,
            userInfo: ["fontSize": size]
        )
    }
    
    // 🔧 新增：保存字體樣式到 UserDefaults 並發送通知
    func saveFontFamily(_ family: String) {
        UserDefaults.standard.set(family, forKey: "selectedFont")
        NotificationCenter.default.post(
            name: NSNotification.Name("FontFamilyDidChange"),
            object: nil,
            userInfo: ["fontFamily": family]
        )
    }
    
    // 🔧 新增：檢查通知權限
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // 🔧 新增：切換通知
    func toggleNotifications(_ enabled: Bool) {
        if enabled {
            // 請求通知權限
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                DispatchQueue.main.async {
                    self.notificationsEnabled = granted
                    if let error = error {
                        print("通知授權失敗: \(error)")
                    }
                }
            }
        } else {
            // 提示用戶到設置中關閉
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    // 🔧 修改：載入當前語言（始終為繁體中文）
    private func loadCurrentLanguage() {
        selectedLanguage = "繁體中文"
    }
    
    // 🔧 修改：禁用語言更改
    func changeLanguage(_ language: String) {
        // 忽略所有語言更改請求
        print("⚠️ Language selection is disabled")
    }
    
    // 🔧 修改：重新整理儲存使用量，包含計算剩餘空間
    func refreshStorageUsage() {
        guard let currentUser = UserAuthModel.shared.getCurrentFirebaseUser() else {
            iCloudStorageUsed = "storage_not_signed_in".localized
            return
        }
        
        isLoadingStorage = true
        
        CloudKitManager.shared.fetchStorageStatistics(firebaseUserID: currentUser.uid) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingStorage = false
                
                switch result {
                case .success(let stats):
                    self?.storageStats = stats
                    self?.iCloudStorageUsed = stats.totalSizeFormatted
                    
                    // 🔧 新增：計算剩餘空間（假設 iCloud 免費方案 5GB）
                    let totalQuota: Int64 = 5 * 1024 * 1024 * 1024 // 5GB
                    let remaining = totalQuota - stats.totalSize
                    self?.remainingStorage = ByteCountFormatter.string(fromByteCount: remaining, countStyle: .file)
                    
                case .failure(let error):
                    print("獲取儲存統計失敗: \(error.localizedDescription)")
                    self?.iCloudStorageUsed = "storage_error".localized
                }
            }
        }
    }
}

// 🔧 新增：儲存統計數據結構
struct StorageStatistics {
    let booksCount: Int
    let totalSize: Int64
    let averageSize: Int64
    
    var totalSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var averageSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: averageSize, countStyle: .file)
    }
}

// MARK: - 🔧 新增：儲存統計行組件
struct StorageStatRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 20)
            
            // 🔧 修改：使用 LM.localized
            Text(label.localized)
                .font(.caption)
                .foregroundColor(.black)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.black)
        }
    }
}

#Preview {
    SettingsView()
}
