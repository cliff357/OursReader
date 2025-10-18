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
        
        // 觸覺反饋
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// 解鎖 Widget 功能
    func unlockWidget() {
        isWidgetUnlocked = true
        UserDefaults.standard.set(true, forKey: widgetUnlockKey)
        print("🔓 [GoldFinger] Widget unlocked!")
        
        // 觸覺反饋
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
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
}
