//
//  ErrorReminderManager.swift
//  OursReader
//
//  Created by Cliff Chan on 25/05/2024.
//

import Foundation

struct ReminderData {
    var title: String
    var desc: String
    var buttons: [GeneralButtonData]
    var canDismissByGesture = false
}

class BaseReminder: ObservableObject {
    var reminderQueue: Queue<ReminderData> = Queue<ReminderData>()
    @Published var showReminder: Bool = false
    @Published var reminderData: ReminderData?
    
//    // Deeplink
//    @Published var showDeeplinkReminder: Bool = false
    
    init() {
        self.reminderQueue = Queue<ReminderData>()
    }
    
    func onDismiss() {
        reminderQueue.dequeue()
        reminderData = nil
        
        getNextReminder()
    }
    
    func getNextReminder() {
        Task { @MainActor in
            self.reminderData = reminderQueue.peek()
            handleShowReminder()
        }
    }
    
    private func handleShowReminder() {
        let showReminder = reminderData != nil
        
//        if DeepLinkManager.shared.route == nil {
            Task { @MainActor in
                self.showReminder = showReminder
            }
//        } else {
//            self.showDeeplinkReminder = showReminder
//        }
    }
}
