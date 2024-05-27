//
//  WelcomePage.swift
//  OursReader
//
//  Created by Cliff Chan on 2/4/2024.
//

import SwiftUI

//TODO: just an idea, want to insert this page before login

struct WelcomePage: View {
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
            
//            VStack {
//                Spacer()
//                ORTextField(text: $email,placeholder: LM.Key.login_email_title(), floatingPrompt: LM.Key.login_email_floating_msg())
//                    .padding(.bottom, 20)
//                ORTextField(text: $password,placeholder: LM.Key.login_pass_title(), floatingPrompt: LM.Key.login_pass_floating_msg(),isSecure: true)
//                    .padding(.bottom, 20)
//                
//                SignupButton()
//                    .padding(.bottom, 10)
//            }
//            .padding()
//            .frame(width: UIScreen.main.bounds.width )
//            .navigationTitle(LM.Key.sign_up())
        }
    }
}

#Preview {
    WelcomePage()
}
