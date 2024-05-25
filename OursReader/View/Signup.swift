//
//  Signup.swift
//  OursReader
//
//  Created by Cliff Chan on 2/4/2024.
//

import SwiftUI
import Foundation
import Firebase
import GoogleSignIn
import FirebaseAuth

struct Signup: View {
    @State var email: String = ""
    @State var password: String = ""
    @State var confirmPassword: String = ""

    
    fileprivate func SignupButton() -> some View {
        Button(action: {
            UserAuthModel.shared.createUser(email: email, password: password) { msg in
                let reminderData = ReminderData(
                    title: "!!",
                    desc: msg ?? "",
                    buttons: [GeneralButtonData(title: LM.Key.general_ok(), style: .fill, action: {})])
                ReminderManager.shared.addReminder(reminder: reminderData)
            }
        }) {
            Text(LM.Key.sign_up_button())
                .padding(20)
        }
        .background(Color.rice_white)
        .foregroundStyle(Color.dark_brown2)
        .clipShape(Capsule())
    }
    
    var body: some View {
        ZStack{
            Color.rice_white.ignoresSafeArea()
            Spacer()
            Circle()
                .fill(Color.background)
                .frame(width: 400 , height: 400)
                .position(x: 150, y: -100)
                .ignoresSafeArea(.keyboard)
            
            Circle()
                .fill(Color.dark_brown)
                .frame(width: UIScreen.main.bounds.width * 1.7 , height: UIScreen.main.bounds.width * 1.7)
                .offset(y: UIScreen.main.bounds.width * 0.8)
            
            VStack {
                Spacer()
                ORTextField(text: $email,placeholder: LM.Key.login_email_title(), floatingPrompt: LM.Key.login_email_floating_msg())
                    .padding(.bottom, 20)
                ORTextField(text: $password,placeholder: LM.Key.login_pass_title(), floatingPrompt: LM.Key.login_pass_floating_msg(),isSecure: true)
                    .padding(.bottom, 20)
                
                SignupButton()
                    .padding(.bottom, 10)
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width )
            .navigationTitle(LM.Key.sign_up())
        }
    }
}

#Preview {
    Signup()
}
