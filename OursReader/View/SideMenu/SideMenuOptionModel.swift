//
//  SideMenuOptionModel.swift
//  OursReader
//
//  Created by Cliff Chan on 22/3/2024.
//

import Foundation

enum SideMenuOptionModel: Int, CaseIterable, Equatable {
    case dashboard
    case friendList
    case settings

    var title: String {
        switch self {
        case .dashboard:
            return String(localized:"dashboard")
        case .friendList:
            return String(localized:"friendList")
        case .settings:
            return String(localized:"settings")
        }
    }
    
    var systemImageName: String {
        switch self {
        case .dashboard:
            return "house"
        case .friendList:
            return "person.2"
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
