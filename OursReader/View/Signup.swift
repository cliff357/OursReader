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
        .background(Color.button_solid_bkgd)
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }
    
    var body: some View {
        ZStack{
            Color.white.ignoresSafeArea()
            Spacer()
            Circle()
                .fill(Color.button_solid_bkgd)
                .frame(width: 400 , height: 400)
                .position(x: 150, y: -100)
                .ignoresSafeArea(.keyboard)
            
            Circle()
                .fill(Color.circle_color)
                .frame(width: UIScreen.main.bounds.width * 1.7 , height: UIScreen.main.bounds.width * 1.7)
                .offset(y: UIScreen.main.bounds.width * 0.8)
            
            VStack {
                Spacer()
                FloatingPromptTextField(text: $email) {
                    Text("Email")
                        .foregroundStyle(Color.white)
                }
                .floatingPrompt {
                    Text("Email 快d 入！！")
                        .foregroundStyle(Color.white)
                }
                .padding(10)
                .background(
                    .gray,
                    in: RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )
                .padding(.bottom, 20)
                
                FloatingPromptTextField(text: $password) {
                    Text("Password")
                        .foregroundStyle(Color.white)
                }
                .floatingPrompt {
                    Text("打pwd打快d啦")
                        .foregroundStyle(Color.white)
                }
                .padding(10)
                .background(
                    .gray,
                    in: RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )
                .padding(.bottom, 20)
                
                SignupButton()
                    .padding(.bottom, 10)
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width )
            .navigationTitle("Sign up")
            .navigationBarTitleTextColor(.white)
        }
    }
}

#Preview {
    Signup()
}
