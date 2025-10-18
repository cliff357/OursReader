//
//  GoldFingerManager.swift
//  OursReader
//
//  Created by AI Assistant
//

import Foundation
import SwiftUI

class GoldFingerManager: ObservableObject {
    static let shared = GoldFingerManager()
    
    // 🔧 金手指狀態
    @Published var isEbookUnlocked: Bool = false
    @Published var isWidgetUnlocked: Bool = false
    
    private let ebookUnlockKey = "goldFinger_ebook_unlocked"
    private let widgetUnlockKey = "goldFinger_widget_unlocked"
    
    private init() {
        loadUnlockStatus()
    }
    
    // MARK: - Public Methods
    
    /// 解鎖 Ebook 功能
    func unlockEbook() {
        isEbookUnlocked = true
        UserDefaults.standard.set(true, forKey: ebookUnlockKey)
        print("🔓 [GoldFinger] Ebook unlocked!")
        
        // 🔧 加強觸覺反饋 - 使用多段強烈震動
        triggerUnlockHaptics()
    }
    
    /// 解鎖 Widget 功能
    func unlockWidget() {
        isWidgetUnlocked = true
        UserDefaults.standard.set(true, forKey: widgetUnlockKey)
        print("🔓 [GoldFinger] Widget unlocked!")
        
        // 🔧 加強觸覺反饋 - 使用多段強烈震動
        triggerUnlockHaptics()
    }
    
    /// 鎖定 Ebook 功能（測試用）
    func lockEbook() {
        isEbookUnlocked = false
        UserDefaults.standard.set(false, forKey: ebookUnlockKey)
        print("🔒 [GoldFinger] Ebook locked!")
    }
    
    /// 鎖定 Widget 功能（測試用）
    func lockWidget() {
        isWidgetUnlocked = false
        UserDefaults.standard.set(false, forKey: widgetUnlockKey)
        print("🔒 [GoldFinger] Widget locked!")
    }
    
    /// 重置所有金手指狀態
    func resetAll() {
        isEbookUnlocked = false
        isWidgetUnlocked = false
        UserDefaults.standard.set(false, forKey: ebookUnlockKey)
        UserDefaults.standard.set(false, forKey: widgetUnlockKey)
        print("🔄 [GoldFinger] All locks reset!")
    }
    
    // MARK: - Private Methods
    
    private func loadUnlockStatus() {
        isEbookUnlocked = UserDefaults.standard.bool(forKey: ebookUnlockKey)
        isWidgetUnlocked = UserDefaults.standard.bool(forKey: widgetUnlockKey)
        
        print("📱 [GoldFinger] Loaded status:")
        print("   Ebook: \(isEbookUnlocked ? "🔓 Unlocked" : "🔒 Locked")")
        print("   Widget: \(isWidgetUnlocked ? "🔓 Unlocked" : "🔒 Locked")")
    }
    
    // MARK: - 🔧 新增：加強的解鎖震動效果
    
    private func triggerUnlockHaptics() {
        // 第一段：重擊
        let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
        heavyGenerator.prepare()
        heavyGenerator.impactOccurred(intensity: 1.0)
        
        // 短暫延遲
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 第二段：成功通知
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(.success)
        }
        
        // 再次延遲
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // 第三段：中等強度震動
            let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
            mediumGenerator.prepare()
            mediumGenerator.impactOccurred(intensity: 1.0)
        }
        
        // 最後一段：輕微震動
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let lightGenerator = UIImpactFeedbackGenerator(style: .light)
            lightGenerator.prepare()
            lightGenerator.impactOccurred(intensity: 1.0)
        }
    }
}
