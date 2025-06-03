//
//  FontManager.swift
//  OursReader
//
//  Created by Cliff Chan on 25/5/2024.
//

import Foundation
import SwiftUI


final class FontManager {
    enum FontSize: String, Equatable {
        case small = "font-small"
        case medium = "font-medium"
        case large = "font-large"
        
        var extraSize: CGFloat {
            switch self {
            case .small:            return -2
            case .medium:           return 0
            case .large:            return 2
            }
        }
    }
    
    private static var defaultFontSize: FontSize = .medium
    static var currentFontSize: FontSize {
        get {
            if let str = Storage.getString(Storage.Key.currentFontSize),
               let fontSize = FontSize(rawValue: str) {
                return fontSize
            }

            return defaultFontSize
        }

        set {
            if self.currentFontSize == newValue { return }
            Storage.save(Storage.Key.currentFontSize, newValue.rawValue)
        }
    }
}
