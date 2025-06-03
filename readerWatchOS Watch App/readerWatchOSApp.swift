//
//  readerWatchOSApp.swift
//  readerWatchOS Watch App
//
//  Created by Cliff Chan on 12/2/2025.
//

import SwiftUI
import FirebaseCore
import FirebaseAppCheck

class AppDelegate: NSObject, ObservableObject {
    func setupFirebase() {
        // 添加錯誤處理，防止因找不到配置文件而崩潰
        guard let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            print("⚠️ GoogleService-Info.plist not found. Firebase services will not work properly.")
            return
        }
        
        guard let options = FirebaseOptions(contentsOfFile: filePath) else {
            print("⚠️ Unable to initialize Firebase with GoogleService-Info.plist")
            return
        }
        
        FirebaseApp.configure(options: options)
        
        // 在 watchOS 上使用 Debug Provider
        let providerFactory = OurReaderAppCheckProviderFactory()
//        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
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
struct readerWatchOS_Watch_AppApp: App {
    @StateObject private var appDelegate = AppDelegate()
    
    init() {
        appDelegate.setupFirebase()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
