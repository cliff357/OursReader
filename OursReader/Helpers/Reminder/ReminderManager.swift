//
//  ErrorReminderManager.swift
//  OursReader
//
//  Created by Cliff Chan on 25/05/2024.
//

import Foundation
import Combine

protocol ReminderProtocol {
    func addReminder(reminder: ReminderData)
}

class ReminderManager: BaseReminder, ReminderProtocol {
    static let shared = ReminderManager()

    func addReminder(reminder: ReminderData) {
        reminderQueue.enqueue(reminder)
        
        guard reminderData == nil else { return }
        
        getNextReminder()
    }
}
