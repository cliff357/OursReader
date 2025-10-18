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
    @State private var isLoggingIn = false
    
    fileprivate func LoginByUsernameButton() -> some View {
        Button(action: {
            guard !email.isEmpty && !password.isEmpty else { return }
            
            isLoggingIn = true
            
            vm.loginUser(email: email, password: password) { msg in
                DispatchQueue.main.async {
                    isLoggingIn = false
                    
                    // 🔧 檢查登入狀態
                    if vm.isLoggedIn {
                        print("✅ Login Success - Email")
                    } else if let errorMsg = msg, !errorMsg.isEmpty {
                        print("❌ Login failed: \(errorMsg)")
                    }
                }
            }
        }) {
            HStack {
                if isLoggingIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ColorManager.shared.dark_brown2))
                        .scaleEffect(0.8)
                }
                Text(String(localized: "auth_login_button"))
                    .padding(20)
                    .font(FontHelper.shared.workSansMedium16)
            }
        }
        .disabled(isLoggingIn)
        .opacity(isLoggingIn ? 0.6 : 1.0)
        .background(ColorManager.shared.rice_white)
        .foregroundStyle(ColorManager.shared.dark_brown2)
        .clipShape(Capsule())
    }
    
    fileprivate func SignUpButton() -> Button<Text> {
        Button(action: {
            HomeRouter.shared.push(to: .signup)
        }) {
            Text(String(localized: "auth_signup_button"))
                .font(FontHelper.shared.workSansMedium16)
                .foregroundStyle(ColorManager.shared.rice_white)
        }
    }
    
    fileprivate func LoginInByGoogleButton() -> some View {
        Button(action: {
            isLoggingIn = true
            vm.signInByGoogle()
            
            // 🔧 輪詢檢查登入狀態
            checkLoginStatus(loginType: "Google")
        }, label: {
            Image("Google")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .padding(7.5)
        })
        .disabled(isLoggingIn)
        .opacity(isLoggingIn ? 0.6 : 1.0)
    }
    
    fileprivate func LoginInByAppleButton() -> some View {
        Button(action: {
            isLoggingIn = true
            vm.startSignInWithAppleFlow()
            
            // 🔧 輪詢檢查登入狀態
            checkLoginStatus(loginType: "Apple")
        }, label: {
            Image(systemName: "apple.logo")
                .resizable()
                .scaledToFit()
                .padding(15)
                .tint(.black)
                .background(Circle().fill(Color.white))
                .frame(width: 55, height: 55)
        })
        .disabled(isLoggingIn)
        .opacity(isLoggingIn ? 0.6 : 1.0)
    }
    
    // 🔧 簡化的登入檢查
    private func checkLoginStatus(loginType: String) {
        var attempts = 0
        let maxAttempts = 30
        
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            attempts += 1
            
            if vm.isLoggedIn {
                timer.invalidate()
                print("✅ Login Success - \(loginType)")
                DispatchQueue.main.async {
                    isLoggingIn = false
                }
            } else if attempts >= maxAttempts {
                timer.invalidate()
                print("⏱️ Login timeout - \(loginType)")
                DispatchQueue.main.async {
                    isLoggingIn = false
                }
            }
        }
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
                DividerWithText( label: String(localized:"general_or"), color: ColorManager.shared.rice_white)
                HStack {
                    LoginInByAppleButton()
                    LoginInByGoogleButton()
                }
                HStack {
                    Text(String(localized: "login_no_account"))
                        .foregroundStyle(ColorManager.shared.rice_white)
                        .font(FontHelper.shared.workSansMedium16)
                    SignUpButton()
                }
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width )
            .navigationTitle(String(localized:"auth_login_title"))
            .navigationBarTitleTextColor(ColorManager.shared.dark_brown2)
        }
    }
}

#Preview {
    Login()
        .environmentObject(UserAuthModel.shared)
}
