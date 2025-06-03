//
//  Push_Setting.swift
//  readerWatchOS Watch App
//
//  Created by Cliff Chan on 28/5/2025.
//

import Foundation

struct Push_Setting: Codable, Hashable, Identifiable {
    let id: String
    var title: String?
    var body: String?
    
    static let defaultSetting = Push_Setting(id: UUID().uuidString, title: "默認標題", body: "默認內容")
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "title": title ?? "",
            "body": body ?? ""
        ]
    }
}
