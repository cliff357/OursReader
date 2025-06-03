//
//  KeychainManager.swift
//  OursReader
//
//  Created by Cliff Chan on 19/2/2025.
//

import Foundation
import Security

enum KeychainKey: String {
    case firebaseToken = "firebaseToken"
}

class KeychainManager {
    
    static let shared = KeychainManager()
    
    private init() {}

    // 🔐 存入 Keychain
    func save(key: KeychainKey, value: String) {
        if let data = value.data(using: .utf8) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key.rawValue,
                kSecValueData as String: data
            ]

            // 先刪除舊的 key，避免重複存取問題
            SecItemDelete(query as CFDictionary)
            
            // 再新增新值2
            let status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                print("⚠️ Keychain Save Error: \(status)")
            }
        }
    }

    // 🔍 從 Keychain 讀取
    func read(key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let retrievedData = dataTypeRef as? Data {
            return String(data: retrievedData, encoding: .utf8)
        } else {
            print("⚠️ Keychain Read Error: \(status)")
            return nil
        }
    }

    // 🗑️ 從 Keychain 刪除資料
    func delete(key: KeychainKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            print("⚠️ Keychain Delete Error: \(status)")
        }
    }
}
