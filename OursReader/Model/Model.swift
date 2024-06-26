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
    var connections_userID: [String]?
    
//    private enum CodingKeys: String, CodingKey {
//        case id
//        case name
//        case userID
//        case fcmToken
//        case email
//        case login_type
//    }
//    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        
//        name = try container.decode(String.self, forKey: .name)
//        userID = try container.decode(String.self, forKey: .userID)
//        fcmToken = try container.decode(String.self, forKey: .fcmToken)
//        email = try container.decode(String.self, forKey: .email)
//        login_type = try container.decode(UserType.self, forKey: .login_type)
//        
//    }
}

struct SendableUserObject: Codable {
    let name: String?
    let userID: String?
    let fcmToken: String?
    let email: String?
    let login_type: UserType?
    var connections_userID: [String]?
}
