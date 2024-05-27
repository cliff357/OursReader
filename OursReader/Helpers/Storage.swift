//
//  Storage.swift
//  OursReader
//
//  Created by Cliff Chan on 25/5/2024.
//

import Foundation
import UIKit

class Storage {
    //Read this before you add key
    //Please concider if key is need to be clear after user logout
    //If should not be clear, please add exception in removeAllUserDefaultsObject()
    enum Key {
        static let isFirstLaunch = "isFirstLaunch"
        static let currentLanguage = "language.current"
        static let currentFontSize = "fontSize.current"
        
        static let nickName = "user.nickName"
        static let pushToken = "user.pushToken"
        static let userName = "user.Name"
        static let userEmail = "user.Email"
    }

    enum StorageType {
        case userDefaults
        case fileSystem
    }

    enum KeychainError: Error {
        // Attempted read for an item that does not exist.
        case itemNotFound

        // Attempted save to override an existing item.
        // Use update instead of save to update existing items
        case duplicateItem

        // A read of an item in any format other than Data
        case invalidItemFormat

        // Any operation result status than errSecSuccess
        case unexpectedStatus(OSStatus)
    }

}

extension Storage {

    static func save<T>(_ key: String, _ param: T) {
        UserDefaults.standard.set(param, forKey: key)
    }

    static func saveObj<T>(_ key: String, _ param: T) where T: Encodable {
        do {
            let data = try JSONEncoder().encode(param)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("cannot save key=\(key) in UserDefaults")
        }

    }

    static func save(image: UIImage,
                     forKey key: String,
                     withStorageType storageType: StorageType) {
        if let pngRepresentation = image.pngData() {
            switch storageType {
            case .fileSystem:
                if let filePath = filePath(forKey: key) {
                    do {
                        try pngRepresentation.write(to: filePath,
                                                    options: .atomic)
                    } catch let err {
                        print("Saving file resulted in error: ", err)
                    }
                }
            case .userDefaults:
                UserDefaults.standard.set(pngRepresentation,
                                            forKey: key)
            }
        }
    }

    static func getBool(_ key: String) -> Bool {
        return UserDefaults.standard.bool(forKey: key)
    }

    static func getInt(_ key: String) -> Int? {
        return UserDefaults.standard.integer(forKey: key)
    }

    static func getString(_ key: String) -> String? {
        return UserDefaults.standard.string(forKey: key)
    }

    static func getDict(_ key: String) -> [String: Any]? {
        return UserDefaults.standard.dictionary(forKey: key)
    }

    static func getArray(_ key: String) -> [Any]? {
        return UserDefaults.standard.array(forKey: key)
    }

    static func getDouble(_ key: String) -> Double? {
        return UserDefaults.standard.double(forKey: key)
    }

    static func getObject<T: Codable>(_ key: String, to type: T.Type) -> T? {
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                let decoder = JSONDecoder()
                let object = try decoder.decode(T.self, from: data)
                return object
            } catch {
                print("unable to decode: \(error)")
                return nil
            }
        }
        return nil
    }

    static func retrieveImage(forKey key: String,
                              inStorageType storageType: StorageType) -> UIImage? {
        switch storageType {
        case .fileSystem:
            if let filePath = self.filePath(forKey: key),
                let fileData = FileManager.default.contents(atPath: filePath.path),
                let image = UIImage(data: fileData) {
                return image
            }
        case .userDefaults:
            if let imageData = UserDefaults.standard.object(forKey: key) as? Data,
                let image = UIImage(data: imageData) {
                return image
            }
        }

        return nil
    }

    private static func filePath(forKey key: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(for: .documentDirectory,
                                                in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
        return documentURL.appendingPathComponent(key + ".png")
    }

    static func remove(_ key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }

    static func removeAll() {
        func clearTempFolder() {
            let fileManager = FileManager.default
            guard let documentsUrl = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first as? NSURL,
                  let documentPath = documentsUrl.path
            else { return }

            do {
                let fileNames = try fileManager.contentsOfDirectory(atPath: "\(documentPath)")
                print("all files in cache: \(fileNames)")
                for fileName in fileNames {
                    print("find \(fileName)")

                    if fileName.hasSuffix(".png") {
                        let filePathName = "\(documentPath)/\(fileName)"
                        try fileManager.removeItem(atPath: filePathName)
                    }
                }

                let files = try fileManager.contentsOfDirectory(atPath: "\(documentPath)")
                print("all files in cache after deleting images: \(files)")
            } catch {
                print("Could not clear temp folder: \(error)")
            }
        }

        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        }

        clearTempFolder()
    }

    static func removeAll(exception: [String]) {
        var exceptionList: [String: Any] = [:]
        for id in exception {
            exceptionList[id] = Storage.getString(id)
        }
        
        removeAll()
        
        for id in exception {
            if exceptionList[id] != nil, let list = exceptionList[id] {
                Storage.save(id, list)
            }
        }
    }
    
    static func removeAllUserDefaultsObject(){
        
        for (key,_) in UserDefaults.standard.dictionaryRepresentation() {
            if key == Storage.Key.isFirstLaunch ||
                key == Storage.Key.currentFontSize ||
                key == Storage.Key.currentLanguage
           {
                continue
            }else{
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        UserDefaults.standard.synchronize()
        
    }
    
    // DEBUG Usage

    static func printAll() {
        for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
            print("\(key) = \(value) \n")
        }
    }

}

// save to keyChain
extension Storage {
    static func cleanKeychain(exception: [CFString] = []) {
        print("cleanKeychain")
        var secItemClasses = [
            kSecClassGenericPassword,// clean kSecClassGenericPassword will cause ftoken refresh
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]

        secItemClasses = secItemClasses.filter { !exception.contains($0) }

        for itemClass in secItemClasses {
            let spec: NSDictionary = [kSecClass: itemClass]
            print("clear spec \(spec)")
            SecItemDelete(spec)
        }
    }
}
