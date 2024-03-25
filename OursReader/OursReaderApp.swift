//
//  OursReaderApp.swift
//  OursReader
//
//  Created by Cliff Chan on 18/10/2023.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcm = Messaging.messaging().fcmToken {
            print("fcm", fcm)
        }
    }
}


@main
struct OursReaderApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var notificationManager = NotificationManager()
    @StateObject var userAuth: UserAuthModel =  UserAuthModel()
    
    var body: some Scene {
        
        WindowGroup {
            //            NavigationView{
            Login()
                .task {
                    await notificationManager.request()
                    await notificationManager.getAuthStatus()
                }
            //            }
                .environmentObject(userAuth)
                .navigationViewStyle(.stack)
        }
    }
}
