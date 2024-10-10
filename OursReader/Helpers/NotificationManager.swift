//
//  NotificationManager.swift
//  OursReader
//
//  Created by Cliff Chan on 25/3/2024.
//

import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject{
    @Published private(set) var hasPermission = false
    
    init() {
        Task{
            await getAuthStatus()
        }
    }
    
    func request() async{
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
             await getAuthStatus()
        } catch{
            print(error)
        }
    }
    
    func getAuthStatus() async {
        let status = await UNUserNotificationCenter.current().notificationSettings()
        switch status.authorizationStatus {
        case .authorized, .ephemeral, .provisional:
            hasPermission = true
        default:
            hasPermission = false
        }
    }

    func sendPushNotification(to tokens: [String], title: String, body: String, completion: @escaping (Result<String, Error>) -> Void) {
            
            guard let url = URL(string: "") else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let json: [String: Any] = [
                "tokens": tokens,
                "title": title,
                "body": body
            ]
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
                request.httpBody = jsonData
                 
                // 發送請求
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        completion(.success(responseString))
                    } else {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                    }
                }
                task.resume()
            } catch {
                completion(.failure(error))
            }
        }


}
