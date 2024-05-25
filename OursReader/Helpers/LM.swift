//
//  LM.swift
//  OursReader
//
//  Created by Cliff Chan on 25/5/2024.
//

import Foundation

#if DEBUG
import RswiftResources
import SwiftUI
#endif

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
    }

    private static var defaultLanguage: AppLanguage = .english
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

    static var Key: _R.string.localizable {
        return R.string(preferredLanguages: [currentLanguage.rawValue]).localizable
    }
}

//#if DEBUG
//extension StringResource {
//    public func callAsFunction() -> String {
//        if LM.currentLanguage == .key {
//            return self.key.description
//        }
//        
//        return String(resource: self)
//    }
//}
//
//extension Text {
//    public init(_ resource: StringResource) {
//        if LM.currentLanguage == .key {
//            self.init(resource.key.description)
//        } else {
//            self.init(String(resource: resource))
//        }
//    }
//}
//#endif
