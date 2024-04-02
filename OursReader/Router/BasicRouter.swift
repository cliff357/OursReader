//
//  BasicRouter.swift
//  OursReader
//
//  Created by Cliff Chan on 27/3/2024.
//

import SwiftUI
import UIKit

class BaseRouter<T: Route>: ObservableObject {
    @Published var path: [T] = []
    
    func push(to screen: T) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.path.append(screen)
        }
    }
    
    func popBackTo(route: T) {
        guard path.contains(route) else { return }
        while path.last != route {
            back()
        }
    }
    
    func back() {
        _ = self.path.popLast()
    }
    
    func reset(_ screens: [T] = []) {
        path.removeLast(path.count)
        path.append(contentsOf: screens)
    }
}
