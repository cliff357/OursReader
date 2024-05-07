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
    enum UserType : Int, Codable{
        case apple
        case google
        case email
    }

    struct UserObject: Codable, Identifiable {
        @DocumentID var id: String?
        let name: String?
        let userID: String?
        let fcmToken: String?
        let email: String?
        let login_type: UserType?
        
    }
    
    // add user into fireStore
    func addUser(user:UserObject) {
        Firestore.firestore().collection(DatabaseManager.Key.user).document(user.userID ?? "").setData([
            "name": user.name ?? "",
            "fcmToken": user.fcmToken ?? "",
            "email": user.email ?? "",
            "login_type": user.login_type?.rawValue ?? 0
        ]) { (error) in
            if let err = error {
                print("error")
            } else {
                print("add user success")
            }
        }
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
    
    //check user exist in firestore
    func checkUserExist(email: String, completion: @escaping (Bool) -> ()) {
        Firestore.firestore().collection(DatabaseManager.Key.user).document(email).getDocument { (document, error) in
            if let err = error {
                print(err.localizedDescription)
            }
            else {
                if document?.exists == true {
                    completion(true)
                }
                else {
                    completion(false)
                }
            }
        }
    }
    
    func checkUserExist(userID: String, completion: @escaping (Bool) -> ()) {
        Firestore.firestore().collection(DatabaseManager.Key.user).document(userID).getDocument { (document, error) in
            if let err = error {
                print(err.localizedDescription)
            }
            else {
                if document?.exists == true {
                    completion(true)
                }
                else {
                    completion(false)
                }
            }
        }
    }
    
}
