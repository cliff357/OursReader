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
        case simplifiedChinese = "zh-Hans"
        
        var apiValue: String {
            switch self {
            case .english:                  return "en"
            case .traditionalChinese:       return "tc"
            case .simplifiedChinese:        return "sc"
            }
        }
        
        // 🔧 新增：Bundle 語言代碼
        var bundleLanguageCode: String {
            switch self {
            case .english:              return "en"
            case .traditionalChinese:   return "zh-Hant"
            case .simplifiedChinese:    return "zh-Hans"
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
                return .simplifiedChinese
            } else if preferredLanguages.hasPrefix(AppLanguage.traditionalChinese.rawValue) {
                return .traditionalChinese
            }

            return defaultLanguage
        }

        set {
            if self.currentLanguage == newValue { return }
            Storage.save(Storage.Key.currentLanguage, newValue.rawValue)
        }
    }
    
    // 🔧 新增：動態獲取本地化字串
    static func localized(_ key: String) -> String {
        // 獲取當前語言的 Bundle
        guard let bundlePath = Bundle.main.path(forResource: currentLanguage.bundleLanguageCode, ofType: "lproj"),
              let bundle = Bundle(path: bundlePath) else {
            // 如果找不到對應的 Bundle，使用主 Bundle
            return NSLocalizedString(key, comment: "")
        }
        
        // 從對應語言的 Bundle 中獲取字串
        let localizedString = bundle.localizedString(forKey: key, value: nil, table: nil)
        
        // 如果找不到翻譯，返回 key 本身
        return localizedString != key ? localizedString : NSLocalizedString(key, comment: "")
    }
}

// 🔧 新增：SwiftUI 擴展，方便使用
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

// 🔧 新增：SwiftUI Text 擴展
extension Text {
    init(localizedKey: String) {
        self.init(LM.localized(localizedKey))
    }
}
