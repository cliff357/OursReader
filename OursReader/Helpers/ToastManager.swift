//
//  ToastManager.swift
//  OursReader
//
//  Created by Cliff Chan on 25/05/2024.
//

import UIKit
import SwiftUI

class ToastManager: ObservableObject {
    static let shared: ToastManager = .init()
    
    @Published var isPresenting: Bool = false
    @Published var title: String = ""
    @Published var message: String = ""
    
    func presentComingSoonToast(title: String = "Coming Soon", message: String = "努力緊") {
        guard !isPresenting else { return }
        
        self.title = title
        self.message = message
        
        withAnimation {
            isPresenting = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                self.isPresenting = false
            }
        }
    }
}

struct ToastMessage: View {
    let title: String
    let message: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(FontHelper.shared.workSansMedium16)
                .kerning(0.16)
                .foregroundColor(.black)
            
            Text(message)
                .font(FontHelper.shared.workSans14)
                .kerning(0.08)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
//        .background(Color.black900)
        .cornerRadius(12)
    }
}

struct ToastMessageView: View {
    let title: String
    let message: String
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                
                ToastMessage(title: title, message: message)
                    .padding(.bottom, 114)
                    .padding(.horizontal, 24)
            }
            
        }
    }
}

public extension View {
    func toastMessage(show: Bool, title: String, message: String) -> some View {
        ZStack {
            self
            if show {
                ToastMessageView(title: title, message: message)
            }
        }
    }
}
