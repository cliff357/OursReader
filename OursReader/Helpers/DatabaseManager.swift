//
//  DatabaseManager.swift
//  OursReader
//
//  Created by Cliff Chan on 17/3/2024.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    //firebase key
    enum Key {
        static let user = "User"
    }
}

// MARK: - Account management
extension DatabaseManager {
    struct UserObject: Codable, Identifiable {
        @DocumentID var id: String?
        let name: String?
        let userID: String?
        let fcmToken: String?

    }
    
    // add user into fireStore
    func addUser(name: String, userID: String, fcmToken: String) {
        let user = UserObject(name: name, userID: userID, fcmToken: fcmToken)
        do {
            _ = try Firestore.firestore().collection(DatabaseManager.Key.user).addDocument(from: user)
        } catch {
            print(error)
        }
        
//        Firestore.firestore().collection(DatabaseManager.Key.user).document(projectId).setData([
//            "name": self.name ?? "",
//            "version": self.version ?? "",
//        ]) { (error) in
//            if let err = error {
//               print("error")
//            } else {
//                self.sendPushNotifiaction(type: self.type, name: projectName, version: self.version ?? "", platform: self.platform ?? "")
//                self.presenter?.presentRouteToLandingPage()
//            }
//        }
    }
    
    
    // update user info
    func updateUser(name: String, userID: String, fcmToken: String) {
//        let db = Firestore.firestore()
//        let updateReference = db.collection(DatabaseManager.Key.user).document(userID)
//        updateReference.getDocument { (document, err) in
//            if let err = err {
//                print(err.localizedDescription)
//            }
//            else {
//                FirestoreResponse.updateOne(document: document, name: name, userID: userID, fcmToken: fcmToken) { (updated) in
//                    if updated {
//                        self.presenter?.presentRouteToLandingPage()
//                    }
//                }
//            }
//        }
        
//        let db = Firestore.firestore()
//        let updateReference = db.collection(Configs.Database.rootname).document(id)
//        updateReference.getDocument { (document, err) in
//            if let err = err {
//                print(err.localizedDescription)
//            }
//            else {
//                FirestoreResponse.updateOne(document: document, name: self.name ?? item.name, version: self.version ?? item.version, bundle: self.bundle ?? item.bundle, platform: self.platform ?? item.platform, release: self.release ?? item.release, company: self.company ?? item.company, download: self.download ?? item.downloadURL, now: Int(now)) { (updated) in
//                    if updated {
//                        self.sendPushNotifiaction(type: self.type, name: self.name ?? item.name ?? "", version: self.version ?? item.version ?? "", platform: item.platform ?? "")
//                            self.presenter?.presentRouteToLandingPage()
//                    }
//                }
//            }
//        }
    }
    

//    static func updateOne(document: FirebaseFirestore.DocumentSnapshot?, name: String?, userID: String?, fcmToken: String? , completion: @escaping (Bool) -> ()) {
//        document?.reference.setData([
//            "name": name ?? "",
//            "userID": userID ?? "",
//            "fcmtoken": fcmToken ?? ""
//        ])
//        
//        completion(true)
//    }
   
}
