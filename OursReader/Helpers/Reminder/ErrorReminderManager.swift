//
//  ErrorReminderManager.swift
//  OursReader
//
//  Created by Cliff Chan on 25/05/2024.
//

import Foundation
import Combine

protocol ErrorReminderProtocol {
    func addReminder(error: APIError)
}

class ErrorReminderManager: BaseReminder, ErrorReminderProtocol {
    static let shared = ErrorReminderManager()
    
    func addReminder(error: APIError) {
        var reminder: ReminderData?
        
        switch error {
        case .httpError(let error):
            reminder = ReminderData(title: "Error", desc: error.errorMsg, buttons: [
                GeneralButtonData(title: "OK", style: .fill, action: {

                })
            ])
        case .undefined(let message):
            reminder = ReminderData(title: "Error", desc: message, buttons: [
                GeneralButtonData(title: "OK", style: .fill, action: {

                })
            ])
        }
        
        if let reminder {
            reminderQueue.enqueue(reminder)
        }
        
        getNextReminder()
    }
}
