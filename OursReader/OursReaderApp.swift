//
//  OursReaderApp.swift
//  OursReader
//
//  Created by Cliff Chan on 18/10/2023.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}


@main
struct OursReaderApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject var userAuth: UserAuthModel =  UserAuthModel()
    
    var body: some Scene {
        
        WindowGroup {
//            NavigationView{
                Login()
//            }
            .environmentObject(userAuth)
            .navigationViewStyle(.stack)
        }
    }
}
