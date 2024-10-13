//
//  DashboardModel.swift
//  OursReader
//
//  Created by Cliff Chan on 19/9/2024.
//

import Foundation
import SwiftUI

enum ButtonListType {
    case push_notification
    case widget
    case ebook
    
    var color: Color {
        switch self {
        case .push_notification:
            return Color.firstTab
        case .widget:
            return Color.secondTab
        case .ebook:
            return Color.thirdTab
        }
    }
}

// 定義 Widget 結構
struct OurPushNotification {
    var id: String
    var title: String
    var message: String
}

// 定義 Widget 結構
struct Widget {
    var id: String
    var name: String
    var actionCode: String
}

// 定義 Ebook 結構
struct Ebook {
    var id: String
    var name: String
    var title: String
    var instruction: String
}

// 建立 widget list
let pushNotificationList: [OurPushNotification] = [
    OurPushNotification(id: "push_001", title: "bb通知", message: "我掛住你啊🥹"),
    OurPushNotification(id: "push_002", title: "bb通知", message: "你做緊咩呀"),
    OurPushNotification(id: "push_003", title: "bb通知", message: "今晚食咩好"),
    OurPushNotification(id: "push_004", title: "bb通知", message: "抖下先啦～ 唔好咁辛苦"),
    OurPushNotification(id: "push_004", title: "bb通知", message: "收工未")
]
let widgetList: [Widget] = [
    Widget(id: "widget_001", name: "Weather Widget", actionCode: "SHOW_WEATHER"),
    Widget(id: "widget_002", name: "Calendar Widget", actionCode: "OPEN_CALENDAR"),
    Widget(id: "widget_003", name: "Music Player Widget", actionCode: "PLAY_MUSIC"),
    Widget(id: "widget_004", name: "Stock Tracker Widget", actionCode: "SHOW_STOCKS")
]

// 建立 ebook list
let ebookList: [Ebook] = [
    Ebook(id: "ebook_001", name: "Programming 101", title: "Introduction to Programming", instruction: "Learn the basics of programming languages."),
    Ebook(id: "ebook_002", name: "Mastering Python", title: "Advanced Python Techniques", instruction: "Master advanced features in Python."),
    Ebook(id: "ebook_003", name: "Design Patterns", title: "Understanding Software Design Patterns", instruction: "Explore common software design patterns."),
    Ebook(id: "ebook_004", name: "Data Science with R", title: "Data Science Fundamentals", instruction: "Learn data science using R programming.")
]

