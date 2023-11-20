//
//  Tab.swift
//  OursReader
//
//  Created by Cliff Chan on 15/11/2023.
//

import Foundation

enum Tab: String, CaseIterable {
    case fav = "Favourite"
    case new = "New"
    case all = "All"
    
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
}
