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
import FirebaseAppCheck
import WatchConnectivity

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate, WCSessionDelegate {
    
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        
        FirebaseApp.configure()
        
        let providerFactory = OurReaderAppCheckProviderFactory()
//        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        // 設置 Watch Connectivity
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        
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
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
            
            // 當 session 激活時，嘗試發送 token
            if activationState == .activated {
                UserAuthModel.shared.sendFirebaseTokenToWatch()
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // 在這種情況下，您應該激活新的會話
        print("WCSession deactivated")
        WCSession.default.activate()
    }
    
    // 響應手錶的數據請求
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let request = message["request"] as? String {
            switch request {
            case "getPushSettings":
                // 獲取推送設置
                DatabaseManager.shared.getUserPushSetting { result in
                    switch result {
                    case .success(let settings):
                        do {
                            let data = try JSONEncoder().encode(settings)
                            replyHandler(["settings": data])
                        } catch {
                            print("Error encoding push settings: \(error)")
                            replyHandler([:])
                        }
                    case .failure(let error):
                        print("Error fetching push settings: \(error)")
                        replyHandler([:])
                    }
                }
                
            case "getFriendTokens":
                // 獲取朋友的 FCM tokens
                DatabaseManager.shared.getAllFriendsToken { result in
                    switch result {
                    case .success(let tokens):
                        do {
                            let data = try JSONEncoder().encode(tokens)
                            replyHandler(["tokens": data])
                        } catch {
                            print("Error encoding friend tokens: \(error)")
                            replyHandler([:])
                        }
                    case .failure(let error):
                        print("Error fetching friend tokens: \(error)")
                        replyHandler([:])
                    }
                }
                
            default:
                replyHandler([:])
            }
        } else {
            replyHandler([:])
        }
    }
}



class OurReaderAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        if #available(iOS 14.0, *) {
            return AppAttestProvider(app: app)
        } else {
            return DeviceCheckProvider(app: app)
        }
    }
}

@main
struct OursReaderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var userAuthModel = UserAuthModel.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userAuthModel)
        }
    }
}
