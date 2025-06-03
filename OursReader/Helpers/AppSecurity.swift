//
//  AppSecurity.swift
//  OursReader
//
//  Created by Cliff Chan on 9/10/2024.
//

import Foundation
import DeviceCheck

func generateAppAttestKey() {
    if DCAppAttestService.shared.isSupported {
        let keyID = "your_key_id"  // 可以保存到本地
        DCAppAttestService.shared.generateKey { newKeyID, error in
            if let error = error {
                print("Failed to generate App Attest Key: \(error)")
                return
            }
            guard let newKeyID = newKeyID else { return }

            // 獲取 attestation
            DCAppAttestService.shared.attestKey(newKeyID, clientDataHash: Data()) { attestation, error in
                if let error = error {
                    print("Failed to attest App Attest Key: \(error)")
                    return
                }
                guard let attestation = attestation else { return }

                // 發送 attestation 到伺服器進行驗證
                sendAttestationToServer(attestation: attestation, keyID: newKeyID)
            }
        }
    } else {
        print("App Attest is not supported on this device.")
    }
}

func sendAttestationToServer(attestation: Data, keyID: String) {
    // 將 attestation 發送到伺服器，這裡可以通過 URLSession 發送請求
    guard let url = URL(string: "https://your-server.com/verify-attestation") else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let payload = [
        "attestation": attestation.base64EncodedString(),
        "keyID": keyID
    ]

    let jsonData = try? JSONSerialization.data(withJSONObject: payload)
    request.httpBody = jsonData

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error sending attestation: \(error)")
            return
        }

        print("Attestation sent successfully.")
    }

    task.resume()
}
