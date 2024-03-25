//
//  Tab.swift
//  OursReader
//
//  Created by Cliff Chan on 15/11/2023.
//

import Foundation

enum Tab: Int, CaseIterable, Equatable {
    case fav = 0
    case new = 1
    case all = 2
    
    var systemImage: String {
        switch self {
        case .fav:
            return "list.star"
        case .new:
            return "book.fill"
        case .all:
            return "book.closed.fill"
        }
    }
    
    var name: String {
        switch self {
        case .fav:
            return "Favourite"
        case .new:
            return "New"
        case .all:
            return "All"
        }
    }
    
    static func == (lhs: Tab, rhs: Tab) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}
