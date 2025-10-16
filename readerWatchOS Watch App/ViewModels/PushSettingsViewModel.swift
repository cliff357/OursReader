//
//  PushSettingsViewModel.swift
//  readerWatchOS Watch App
//
//  Created by Cliff Chan on 28/5/2025.
//

import Foundation
import SwiftUI

@MainActor
class PushSettingsViewModel: ObservableObject {
    @Published var pushSettings: [Push_Setting] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var isSending = false
    @Published var friendTokens: [String] = []
    
    private let watchDataService = WatchDataService()
    private let firebaseService = FirebaseService()
    
    func fetchPushSettings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            pushSettings = try await watchDataService.getUserPushSettings()
            if pushSettings.isEmpty {
                pushSettings = [Push_Setting.defaultSetting]
            }
        } catch {
            if let error = error as? WatchDataService.WatchDataError {
                switch error {
                case .connectivityNotSupported, .connectivityInactive, .requestFailed:
                    // 使用本地緩存的默認設置，不顯示錯誤
                    print("使用本地緩存：\(error)")
                default:
                    errorMessage = "無法獲取通知設定：\(error.localizedDescription)"
                }
            } else {
                print("Failed to fetch push settings: \(error)")
            }
            
            // 確保至少有一個默認設置
            if pushSettings.isEmpty {
                pushSettings = [Push_Setting.defaultSetting]
            }
        }
        
        isLoading = false
    }
    
    func fetchFriendTokens() async {
        do {
            friendTokens = try await watchDataService.getFriendTokens()
        } catch {
            // 在離線模式下，使用緩存的 token，不顯示錯誤
            print("Failed to fetch friend tokens: \(error)")
        }
    }
    
    func sendPushNotification(using setting: Push_Setting) async {
        guard !friendTokens.isEmpty else {
            errorMessage = "未找到好友裝置"
            return
        }
        
        isSending = true
        
        for token in friendTokens {
            do {
                let message = try await firebaseService.sendPushNotification(
                    to: token,
                    title: setting.title ?? "未知標題",
                    body: setting.body ?? "未知內容"
                )
                print("Notification sent: \(message)")
            } catch {
                errorMessage = "發送通知失敗：\(error.localizedDescription)"
                print("Failed to send notification: \(error)")
            }
        }
        
        isSending = false
    }
}
