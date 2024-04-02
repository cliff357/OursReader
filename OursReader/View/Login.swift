//
//  Login.swift
//  OursReader
//
//  Created by Cliff Chan on 17/3/2024.
//

import SwiftUI
import GoogleSignIn

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
                .padding(5)
        }
        .buttonStyle(.bordered)
        .tint(.white)
        .buttonBorderShape(.capsule)
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
            VStack {
                VStack {
                    UnderlineTextField
                        .init(icon: "person.circle", placeHolder: "Email",keyboardType: .default, text: $email)
                        .padding(.bottom, 20)
                    UnderlineTextField
                        .init(icon: "lock", placeHolder: "Password",keyboardType: .default, text: $password)
                        .padding(.bottom, 50)
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
                .padding()
                
                
                
            }
            .onChange(of: vm.isLoggedIn) { oldValue, newValue in
                if newValue {
                    HomeRouter.shared.push(to: .home)
                }
            }
            .navigationTitle("Login")
        }
        
        
        
    }
}

#Preview {
    Login()
}
