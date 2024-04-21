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
                
            }
        }) {
            Text("Sign up")
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
                ORTextField(text: $email,placeholder: "呢到就入Email", floatingPrompt: "隻手呀，一二一二")
                    .padding(.bottom, 20)
                ORTextField(text: $password,placeholder: "密碼黎架喂", floatingPrompt: "爽手啦",isSecure: true)
                    .padding(.bottom, 20)
                
                SignupButton()
                    .padding(.bottom, 10)
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width )
            .navigationTitle("Sign up")
        }
    }
}

#Preview {
    Signup()
}
