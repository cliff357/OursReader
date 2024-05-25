//
//  Queue.swift
//  OursReader
//
//  Created by Cliff Chan on 25/5/2024.
//

import Foundation

struct Queue<T> {
    var list = [T]()
    
    var isEmpty: Bool {
        return list.isEmpty
    }
    
    mutating func enqueue(_ element: T) {
        list.append(element)
    }
    
    @discardableResult
    mutating func dequeue() -> T? {
        if !list.isEmpty {
            return list.removeFirst()
        } else {
            return nil
        }
    }
    
    func peek() -> T? {
        if !list.isEmpty {
            return list[0]
        } else {
            return nil
        }
    }
}
