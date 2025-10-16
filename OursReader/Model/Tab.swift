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
            return NSLocalizedString("push_notification", comment: "")
        case .widget:
            return NSLocalizedString("widget", comment: "")
        case .ebook:
            return NSLocalizedString("ebook", comment: "")
        }
    }
    
    static func == (lhs: Tab, rhs: Tab) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}
