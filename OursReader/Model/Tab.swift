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
            return "通知"
        case .widget:
            return "Widget"
        case .ebook:
            return "電子書"
        }
    }
    
    static func == (lhs: Tab, rhs: Tab) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}
