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
    case settings
    
    
    var title: String {
        switch self {
        case .dashboard:
            return LM.Key.dashboard()
        case .profile:
            return LM.Key.profile()
        case .widget:
            return LM.Key.widget()
        case .friendList:
            return LM.Key.friendList()
        case .settings:
            return LM.Key.settings()
        }
    }
    
    var systemImageName: String {
        switch self {
        case .dashboard:
            return "filemenu.and.cursorarrow"
        case .profile:
            return "person"
        case .widget:
            return "square.and.pencil"
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
