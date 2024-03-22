//
//  SideMenuOptionModel.swift
//  OursReader
//
//  Created by Autotoll Developer on 22/3/2024.
//

import Foundation

enum SideMenuOptionModel: Int, CaseIterable {
    case dashboard
    case profile
    case search
    case notification
    
    var title: String {
        switch self {
        case .dashboard:
            return "Dashboard"
        case .profile:
            return "Profile"
        case .search:
            return "Search"
        case .notification:
            return "Notification"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .dashboard:
            return "filemenu.and.cursorarrow"
        case .profile:
            return "person"
        case .search:
            return "magnifyingglass"
        case .notification:
            return "bell"
        }
    }
}

extension SideMenuOptionModel: Identifiable {
    var id: Int { return self.rawValue }
}
