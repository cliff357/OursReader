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
            Text("Login Now")
                .padding(20)
        }
        .background(Color.rice_white)
        .foregroundStyle(Color.dark_brown2)
        .clipShape(Capsule())
    }
    
    fileprivate func SignUpButton() -> Button<Text> {
        Button(action: {
            HomeRouter.shared.push(to: .signup)
        }) {
            Text("Sign Up")
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
                .frame(width: 25, height: 25)
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
                .padding(8)
                .tint(.black)
                .background(Circle().fill(Color.white))
                .frame(width: 28, height: 28)
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
                
                ORTextField(text: $email,placeholder: "呢到就入Email", floatingPrompt: "隻手呀，一二一二")
                    .padding(.bottom, 20)
                ORTextField(text: $password,placeholder: "密碼黎架喂", floatingPrompt: "爽手啦",isSecure: true)
                    .padding(.bottom, 20)
                
                LoginByUsernameButton()
                DividerWithText( label: "or", color: Color.rice_white)
                HStack {
                    LoginInByAppleButton()
                    LoginInByGoogleButton()
                }
                HStack {
                    Text("Don't have an account? ")
                        .foregroundStyle(Color.rice_white)
                    SignUpButton()
                }
                
                
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width )
            .onChange(of: vm.isLoggedIn) { oldValue, newValue in
                if newValue {
                    HomeRouter.shared.push(to: .home)
                }
            }
            .navigationTitle("Login")
            .navigationBarTitleTextColor(.dark_brown2)
        }
    }
}

#Preview {
    Login()
}
