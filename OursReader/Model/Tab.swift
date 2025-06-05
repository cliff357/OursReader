//
//  Tab.swift
//  OursReader
//
//  Created by Cliff Chan on 15/11/2023.
//

import Foundation

enum Tab: Int, CaseIterable, Equatable {
    case push = 0
    case widget = 1
    case ebook = 2
    
    var systemImage: String {
        switch self {
        case .push:
            return "list.star"
        case .widget:
            return "book.fill"
        case .ebook:
            return "book.closed.fill"
        }
    }
    
    var name: String {
        switch self {
        case .push:
            return String(localized: "push_notification")
        case .widget:
            return String(localized: "widget")
        case .ebook:
            return String(localized: "ebook")
        }
    }
    
    static func == (lhs: Tab, rhs: Tab) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}
