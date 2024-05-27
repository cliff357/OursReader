//
//  WelcomePage.swift
//  OursReader
//
//  Created by Cliff Chan on 2/4/2024.
//

import SwiftUI

//TODO: just an idea, want to insert this page before login

struct WelcomePage: View {
    @State var nickname: String = ""
    @EnvironmentObject var vm: UserAuthModel
    
    fileprivate func confirmButton() -> some View {
        Button(action: {
            vm.nickName = nickname
            Storage.save(Storage.Key.nickName, nickname)
        }) {
            Text(LM.Key.general_done())
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
                ORTextField(text: $nickname,placeholder: LM.Key.nick_name(), floatingPrompt: LM.Key.nick_name())
                    .padding(.bottom, 20)
                
                confirmButton()
                    .padding(.bottom, 10)
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width )
            .navigationTitle(LM.Key.sign_up())
        }
    }
}

#Preview {
    WelcomePage()
}
