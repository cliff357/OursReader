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
    //    @State  var gotoDashboard: Bool = false
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
        .background(Color.button_solid_bkgd)
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }
    
    fileprivate func SignUpButton() -> Button<Text> {
        Button(action: {
            //redirect to signup page
        }) {
            Text("Sign Up")
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
                .frame(width: 25, height: 25)
                .padding(7.5)
        })
        
        
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
                .offset(y: UIScreen.main.bounds.width * 0.5)
            
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
                
                LoginByUsernameButton()
                    .padding(.bottom, 10)
                DividerWithText(label: "or")
                    .padding(.bottom, 10)
                HStack {
                    LoginInByAppleButton()
                    LoginInByGoogleButton()
                }
                HStack {
                    Text("Don't have an account? ")
                    SignUpButton()
                }
                
                
            }
            .foregroundStyle(Color.white)
            .padding()
            .frame(width: UIScreen.main.bounds.width )
            .onChange(of: vm.isLoggedIn) { oldValue, newValue in
                if newValue {
                    HomeRouter.shared.push(to: .home)
                }
            }
            .navigationTitle("Login")
            .navigationBarTitleTextColor(.white)
        }
    }
}

#Preview {
    Login()
}
