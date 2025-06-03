//
//  ContentView.swift
//  readerWatchOS Watch App
//
//  Created by Cliff Chan on 12/2/2025.
//

import SwiftUI
import FirebaseCore
import WatchConnectivity

struct ContentView: View {
    @State private var isPhoneConnected = false
    @State private var isCheckingConnection = true
    
    var body: some View {
        Group {
            if isCheckingConnection {
                ProgressView("檢查連接...")
                    .task {
                        await checkPhoneConnection()
                    }
            } else {
                // 無論手機是否連接，都顯示推送設定頁面
                TabView {
                    PushSettingsListView(isPhoneConnected: isPhoneConnected)
                        .tabItem {
                            Label("推送設定", systemImage: "bell")
                        }
                    
                    Text("更多功能")
                        .tabItem {
                            Label("更多", systemImage: "ellipsis")
                        }
                }
                .overlay(alignment: .top) {
                    if !isPhoneConnected {
                        HStack {
                            Image(systemName: "iphone.slash")
                            Text("使用離線模式")
                        }
                        .font(.caption)
                        .padding(8)
                        .background(Color.red.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.top, 2)
                    }
                }
            }
        }
    }
    
    func checkPhoneConnection() async {
        isCheckingConnection = true
        
        // 檢查是否支持 WCSession
        guard WCSession.isSupported() else {
            isPhoneConnected = false
            isCheckingConnection = false
            return
        }
        
        let session = WCSession.default
        if session.activationState != .activated {
            session.delegate = WatchSessionDelegate.shared
            session.activate()
            
            // 等待激活完成
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        }
        
        isPhoneConnected = session.isReachable
        isCheckingConnection = false
    }
}

class WatchSessionDelegate: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchSessionDelegate()
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("WCSession reachability changed: \(session.isReachable)")
    }
}

#Preview {
    ContentView()
}
