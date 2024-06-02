//
//  Model.swift
//  OursReader
//
//  Created by Cliff Chan on 18/10/2023.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift


struct Book {
    var title: String
    var description: String
    var summary: String
    var image: String
}

struct BookDetail {
    var content: String
    var lastReadIndex: Int
}

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

struct TestUserObject: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String?
    let userID: String?
    let fcmToken: String?
    let email: String?
    let login_type: UserType?
    
}
