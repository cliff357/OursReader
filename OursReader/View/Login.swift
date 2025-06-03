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
            Text("login_title")
                .padding(20)
                .font(FontHelper.shared.workSansMedium16)
        }
        .background(ColorManager.shared.rice_white)
        .foregroundStyle(ColorManager.shared.dark_brown2)
        .clipShape(Capsule())
    }
    
    fileprivate func SignUpButton() -> Button<Text> {
        Button(action: {
            HomeRouter.shared.push(to: .signup)
        }) {
            Text("sign_up")
                .font(FontHelper.shared.workSansMedium16)
                .foregroundStyle(ColorManager.shared.rice_white)
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
            ColorManager.shared.rice_white.ignoresSafeArea()
            Spacer()
            Circle()
                .fill(ColorManager.shared.background)
                .frame(width: 400 , height: 400)
                .position(x: 150, y: -100)
                .ignoresSafeArea(.keyboard)
                
            
            Circle()
                .fill(ColorManager.shared.dark_brown)
                .frame(width: UIScreen.main.bounds.width * 1.7 , height: UIScreen.main.bounds.width * 1.7)
                .offset(y: UIScreen.main.bounds.width * 0.5)
            
            VStack {
                Spacer()
                
                ORTextField(text: $email,placeholder: String(localized:"login_email_title"), floatingPrompt: String(localized:"login_email_floating_msg"))
                    .padding(.bottom, 20)
                ORTextField(text: $password,placeholder: String(localized: "login_pass_title"), floatingPrompt: String(localized: "login_pass_floating_msg") ,isSecure: true)
                    .padding(.bottom, 20)
                
                LoginByUsernameButton()
                DividerWithText( label: String(localized:"or"), color: ColorManager.shared.rice_white)
                HStack {
                    LoginInByAppleButton()
                    LoginInByGoogleButton()
                }
                HStack {
                    Text("login_no_account")
                        .foregroundStyle(ColorManager.shared.rice_white)
                        .font(FontHelper.shared.workSansMedium16)
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
            .navigationTitle(String(localized:"login"))
            .navigationBarTitleTextColor(ColorManager.shared.dark_brown2)
        }
    }
}

#Preview {
    Login()
}
