//
//  LM.swift
//  OursReader
//
//  Created by Cliff Chan on 25/5/2024.
//

import Foundation
import SwiftUI

typealias LM = LocalizationManager

/// Localization Manager
final class LocalizationManager {
    enum AppLanguage: String {
        case english = "en"
        case traditionalChinese = "zh-Hant"
        case simplifiedChinese = "zh-Hans" // 🔧 保留但不使用
        
        var apiValue: String {
            switch self {
            case .english:                  return "en"
            case .traditionalChinese:       return "tc"
            case .simplifiedChinese:        return "sc"
            }
        }
        
        var localeIdentifier: String {
            switch self {
            case .english:              return "en"
            case .traditionalChinese:   return "zh-HK"
            case .simplifiedChinese:    return "zh-HK" // 🔧 簡體也使用繁體
            }
        }
    }

    private static var defaultLanguage: AppLanguage = .traditionalChinese
    
    static var currentLanguage: AppLanguage {
        get {
            if let str = Storage.getString(Storage.Key.currentLanguage),
               let lang = AppLanguage(rawValue: str) {
                return lang
            }

            let preferredLanguages = NSLocale.preferredLanguages[0]

            if preferredLanguages.hasPrefix(AppLanguage.english.rawValue) {
                return .english
            } else if preferredLanguages.hasPrefix(AppLanguage.simplifiedChinese.rawValue) {
                return .traditionalChinese // 🔧 簡體轉為繁體
            } else if preferredLanguages.hasPrefix(AppLanguage.traditionalChinese.rawValue) {
                return .traditionalChinese
            }

            return defaultLanguage
        }

        set {
            if self.currentLanguage == newValue { return }
            Storage.save(Storage.Key.currentLanguage, newValue.rawValue)
            print("✅ Language changed to: \(newValue.rawValue)")
        }
    }
    
    // 🔧 修改：使用 Locale 方式獲取本地化字串（支持 .xcstrings）
    static func localized(_ key: String) -> String {
        // 使用當前語言的 Locale
        let locale = Locale(identifier: currentLanguage.localeIdentifier)
        
        // 使用 String(localized:locale:) 從 .xcstrings 獲取翻譯
        let localizedString = String(localized: String.LocalizationValue(key), locale: locale)
        
        // 如果找到翻譯，返回
        if localizedString != key {
            return localizedString
        }
        
        // 如果沒有找到，使用默認的本地化
        return NSLocalizedString(key, comment: "")
    }
}

// 🔧 SwiftUI 擴展
extension String {
    /// 使用 LM 動態本地化
    var localized: String {
        return LM.localized(self)
    }
    
    /// 帶參數的本地化
    func localized(_ arguments: CVarArg...) -> String {
        return String(format: LM.localized(self), arguments: arguments)
    }
}

// 🔧 SwiftUI Text 擴展
extension Text {
    init(localizedKey: String) {
        self.init(LM.localized(localizedKey))
    }
}
