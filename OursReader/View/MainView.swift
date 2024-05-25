//
//  MainView.swift
//  OursReader
//
//  Created by Cliff Chan on 25/5/2024.
//

import SwiftUI

struct MainView: View {
    @StateObject var userAuth: UserAuthModel =  UserAuthModel()
    @StateObject var homeRouter: HomeRouter = HomeRouter.shared
    @StateObject var loginRouter: LoginRouter = LoginRouter.shared
    
//    @StateObject var reminderManager = ReminderManager.shared
//    @StateObject var errorReminderManager = ErrorReminderManager.shared
    
    var body: some View {
        VStack {
            Group {
                if userAuth.isLoggedIn {
                    NavigationStack(path: $homeRouter.path ) {
                        Home()
                            .environmentObject(userAuth)
                            .navigationDestination(for: HomeRoute.self, destination: { $0 })
                    }
                } else {
                    NavigationStack(path: $homeRouter.path ) {
                        Login()
                            .environmentObject(userAuth)
                            .navigationDestination(for: HomeRoute.self, destination: { $0 })
                    }

                }
            }
            
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(.stack)
        }
    }
}

#Preview {
    MainView()
}

