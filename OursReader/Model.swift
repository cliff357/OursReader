//
//  Model.swift
//  OursReader
//
//  Created by Cliff Chan on 18/10/2023.
//

import Foundation


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
