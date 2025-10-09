//
//  SideMenuOptionModel.swift
//  OursReader
//
//  Created by Cliff Chan on 22/3/2024.
//

import Foundation

enum SideMenuOptionModel: Int, CaseIterable, Equatable {
    case dashboard
    case profile
    case widget
    case friendList
    case myBooks // 新增我的書籍選項
    case settings

    var title: String {
        switch self {
        case .dashboard:
            return String(localized:"dashboard")
        case .profile:
            return String(localized:"profile")
        case .widget:
            return String(localized:"widget")
        case .friendList:
            return String(localized:"friendList")
        case .myBooks:
            return "My Books"
        case .settings:
            return String(localized:"settings")
        }
    }
    
    var systemImageName: String {
        switch self {
        case .dashboard:
            return "house"
        case .profile:
            return "person"
        case .widget:
            return "app.dashed"
        case .friendList:
            return "person.2"
        case .myBooks:
            return "books.vertical"
        case .settings:
            return "gear"
        }
    }
    
    static func == (lhs: SideMenuOptionModel, rhs: SideMenuOptionModel) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension SideMenuOptionModel: Identifiable {
    var id: Int { return self.rawValue }
}
