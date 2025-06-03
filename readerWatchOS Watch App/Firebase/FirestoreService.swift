//
//  FirestoreService.swift
//  readerWatchOS Watch App
//
//  Created by Cliff Chan on 28/5/2025.
//

import Foundation
import WatchConnectivity

actor WatchDataService {
    enum WatchDataError: Error {
        case connectivityNotSupported
        case connectivityInactive
        case requestFailed(String)
        case dataNotFound
        case parseError
        case noResponse
    }
    
    private let session: WCSession
    
    init(session: WCSession = .default) {
        self.session = session
    }
    
    func activateSession() async throws {
        guard WCSession.isSupported() else {
            throw WatchDataError.connectivityNotSupported
        }
        
        if session.activationState != .activated {
            return try await withCheckedThrowingContinuation { continuation in
                class ActivationDelegate: NSObject, WCSessionDelegate {
                    let continuation: CheckedContinuation<Void, Error>
                    
                    init(continuation: CheckedContinuation<Void, Error>) {
                        self.continuation = continuation
                    }
                    
                    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if activationState == .activated {
                            continuation.resume()
                        } else {
                            continuation.resume(throwing: WatchDataError.connectivityInactive)
                        }
                    }
                    
                    // On watchOS these methods are not required
                    #if os(iOS)
                    func sessionDidBecomeInactive(_ session: WCSession) {}
                    func sessionDidDeactivate(_ session: WCSession) {}
                    #endif
                }
                
                let delegate = ActivationDelegate(continuation: continuation)
                session.delegate = delegate
                session.activate()
                
                // Keep the delegate alive until activation completes
                objc_setAssociatedObject(session, "activationDelegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }
    
    func getUserPushSettings() async throws -> [Push_Setting] {
        try await activateSession()
        
        guard session.isReachable else {
            // 從本地緩存獲取
            return try getCachedPushSettings()
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            session.sendMessage(["request": "getPushSettings"], replyHandler: { response in
                guard let settingsData = response["settings"] as? Data else {
                    continuation.resume(throwing: WatchDataError.dataNotFound)
                    return
                }
                
                do {
                    let settings = try JSONDecoder().decode([Push_Setting].self, from: settingsData)
                    // 更新本地緩存
                    try? self.cachePushSettings(settings)
                    continuation.resume(returning: settings)
                } catch {
                    print("Failed to decode push settings: \(error)")
                    continuation.resume(throwing: WatchDataError.parseError)
                }
            }, errorHandler: { error in
                print("Failed to get push settings: \(error)")
                // 嘗試從本地緩存獲取
                do {
                    let cachedSettings = try self.getCachedPushSettings()
                    continuation.resume(returning: cachedSettings)
                } catch {
                    continuation.resume(throwing: WatchDataError.requestFailed(error.localizedDescription))
                }
            })
        }
    }
    
    func getFriendTokens() async throws -> [String] {
        try await activateSession()
        
        guard session.isReachable else {
            // 從本地緩存獲取
            return try getCachedFriendTokens()
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            session.sendMessage(["request": "getFriendTokens"], replyHandler: { response in
                guard let tokensData = response["tokens"] as? Data else {
                    continuation.resume(throwing: WatchDataError.dataNotFound)
                    return
                }
                
                do {
                    let tokens = try JSONDecoder().decode([String].self, from: tokensData)
                    // 更新本地緩存
                    try? self.cacheFriendTokens(tokens)
                    continuation.resume(returning: tokens)
                } catch {
                    print("Failed to decode friend tokens: \(error)")
                    continuation.resume(throwing: WatchDataError.parseError)
                }
            }, errorHandler: { error in
                print("Failed to get friend tokens: \(error)")
                // 嘗試從本地緩存獲取
                do {
                    let cachedTokens = try self.getCachedFriendTokens()
                    continuation.resume(returning: cachedTokens)
                } catch {
                    continuation.resume(throwing: WatchDataError.requestFailed(error.localizedDescription))
                }
            })
        }
    }
    
    // Cache management
    private func cachePushSettings(_ settings: [Push_Setting]) throws {
        let data = try JSONEncoder().encode(settings)
        UserDefaults.standard.set(data, forKey: "cachedPushSettings")
    }
    
    private func getCachedPushSettings() throws -> [Push_Setting] {
        guard let data = UserDefaults.standard.data(forKey: "cachedPushSettings") else {
            return []
        }
        
        return try JSONDecoder().decode([Push_Setting].self, from: data)
    }
    
    private func cacheFriendTokens(_ tokens: [String]) throws {
        let data = try JSONEncoder().encode(tokens)
        UserDefaults.standard.set(data, forKey: "cachedFriendTokens")
    }
    
    private func getCachedFriendTokens() throws -> [String] {
        guard let data = UserDefaults.standard.data(forKey: "cachedFriendTokens") else {
            return []
        }
        
        return try JSONDecoder().decode([String].self, from: data)
    }
}
