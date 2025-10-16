//
//  FirebaseService.swift
//  readerWatchOS Watch App
//
//  Created by Cliff Chan on 25/2/2025.
//

import Foundation
import FirebaseFunctions

actor FirebaseService {
    private let functions = Functions.functions()

    // 發送推送通知
    func sendPushNotification(to token: String, title: String, body: String) async throws -> String {
        let payload: [String: Any] = [
            "tokens": token,
            "title": title,
            "body": body
        ]

        return try await withCheckedThrowingContinuation { continuation in
            functions.httpsCallable("sendPushNotificationWithAppCheckForWatchOS")
                .call(payload) { result, error in
                    if let error = error as NSError? {
                        print("Error: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    } else if let resultData = result?.data as? [String: Any],
                              let message = resultData["message"] as? String {
                        print("Result: \(message)")
                        continuation.resume(returning: message)
                    } else {
                        continuation.resume(throwing: NSError(domain: "FirebaseServiceError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
                    }
                }
        }
    }
}

