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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcm = Messaging.messaging().fcmToken {
            print("FCM Token: \(fcm)")
            Storage.save(Storage.Key.pushToken, fcm )
        }
    }
}


@main
struct OursReaderApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject var notificationManager = NotificationManager()
    @StateObject var reminderManager = ReminderManager.shared
//    @StateObject var toastManager = ToastManager.shared
    
//    @State var showSplashView: Bool = true
//    @State private var timeRemaining = 2
//    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some Scene {
        
        WindowGroup {
            ZStack {
                MainView()
//                if showSplashView {
//                    SplashView()
//                }
                
            }
            .reminderBottomSheet(showReminder: $reminderManager.showReminder)
            .task {
                await notificationManager.request()
                await notificationManager.getAuthStatus()
            }
//            .toastMessage(show: toastManager.isPresenting, title: toastManager.title, message: toastManager.message)
//            .onReceive(timer) { _ in
//                if timeRemaining > 0 {
//                    timeRemaining -= 1
//                } else {
//                    showSplashView = false
//                    timer.upstream.connect().cancel()
//                }
//            }
        }
    }
}
