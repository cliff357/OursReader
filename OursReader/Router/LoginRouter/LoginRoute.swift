//
//  LoginRoute.swift
//  OursReader
//
//  Created by Cliff Chan on 27/3/2024.
//

import SwiftUI

enum LoginRoute: Route {
    var id: Self {
        
        return self
    }
    
    case home
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.hashValue)
    }
    
    // Add compare func for each Route, otherwise trigger faceId will cause UI Block and memory leak
    static func == (lhs: LoginRoute, rhs: LoginRoute) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home):
            return true
        default:
            return false
        }
    }
}

extension LoginRoute: View {
    var body: some View {
        switch self {
        case .home:
            Home()
        }
    }
}
