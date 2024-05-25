//
//  Login.swift
//  OursReader
//
//  Created by Cliff Chan on 17/3/2024.
//

import SwiftUI
import GoogleSignIn
import FloatingPromptTextField

struct Login: View {
    
    @EnvironmentObject var vm: UserAuthModel
    @State var email: String = ""
    @State var password: String = ""
    
    fileprivate func LoginByUsernameButton() -> some View {
        Button(action: {
            vm.loginUser(email: email, password: password) { msg in
                
            }
        }) {
            Text(LM.Key.login_title())
                .padding(20)
        }
        .background(Color.rice_white)
        .foregroundStyle(Color.dark_brown2)
        .clipShape(Capsule())
    }
    
    fileprivate func SignUpButton() -> Button<Text> {
        Button(action: {
            HomeRouter.shared.push(to: .signup)
//            let reminderData = ReminderData(
//                title: "test",
//                desc: "test",
//                buttons: [GeneralButtonData(title: "OK", style: .fill, action: {})])
//            ReminderManager.shared.addReminder(reminder: reminderData)
        }) {
            Text(LM.Key.sign_up())
                .foregroundStyle(Color.rice_white)
        }
    }
    
    fileprivate func LoginInByGoogleButton() -> some View {
        Button(action: {
            vm.signInByGoogle()
        }, label: {
            Image("Google")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .padding(7.5)
        })
    }
    
    fileprivate func LoginInByAppleButton() -> some View {
        
        Button(action: {
            vm.startSignInWithAppleFlow()
        }, label: {
            Image(systemName: "apple.logo")
                .resizable()
                .scaledToFit()
                .padding(15)
                .tint(.black)
                .background(Circle().fill(Color.white))
                .frame(width: 55, height: 55)
        })
        
        
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
                .offset(y: UIScreen.main.bounds.width * 0.5)
            
            VStack {
                Spacer()
                
                ORTextField(text: $email,placeholder: LM.Key.login_email_title(), floatingPrompt: LM.Key.login_email_floating_msg())
                    .padding(.bottom, 20)
                ORTextField(text: $password,placeholder: LM.Key.login_pass_title(), floatingPrompt: LM.Key.login_pass_floating_msg(),isSecure: true)
                    .padding(.bottom, 20)
                
                LoginByUsernameButton()
                DividerWithText( label: LM.Key.or(), color: Color.rice_white)
                HStack {
                    LoginInByAppleButton()
                    LoginInByGoogleButton()
                }
                HStack {
                    Text(LM.Key.login_no_account())
                        .foregroundStyle(Color.rice_white)
                    SignUpButton()
                }
                
                
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width )
//            .onChange(of: vm.isLoggedIn) { oldValue, newValue in
//                if newValue {
//                    HomeRouter.shared.push(to: .home)
//                }
//            }
            .navigationTitle(LM.Key.login_title())
            .navigationBarTitleTextColor(.dark_brown2)
        }
    }
}

#Preview {
    Login()
}
