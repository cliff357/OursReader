//
//  Route.swift
//  OursReader
//
//  Created by Cliff Chan on 27/3/2024.
//

import SwiftUI

protocol Route: Identifiable, Hashable, View {}

enum HomeRoute: Route {
    var id: Self {
        
        return self
    }
    
    case login
    case home
    case signup
   
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.hashValue)
    }
    
    // Add compare func for each Route, otherwise trigger faceId will cause UI Block and memory leak
    static func == (lhs: HomeRoute, rhs: HomeRoute) -> Bool {
        switch (lhs, rhs) {
        case (.login, .login):
            return true
        case (.home, .home):
            return true
        case (.signup, .signup):
            return true
        default:
            return false
        }
    }
}

extension HomeRoute: View {
    var body: some View {
        switch self {
        case .login:
            Login()
        case .home:
            Home().navigationBarHidden(true)
        case .signup:
            Signup()
        }
    }
}
