//
//  WelcomePage.swift
//  OursReader
//
//  Created by Cliff Chan on 2/4/2024.
//

import SwiftUI

import Combine

class IconViewModel: ObservableObject {
    @Published var currentIcon: String = "star.fill"
    
    private var icons = ["heart.fill", "bell.fill", "figure.badminton", "figure.boxing"]
    private var index = 0
    private var timer: AnyCancellable?
    
    init() {
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                self?.nextIcon()
            }
    }
    
    private func nextIcon() {
        index = (index + 1) % icons.count
        withAnimation(.easeOut(duration: 1)) {
            currentIcon = icons[index]
        }
    }
}

struct WelcomePage: View {
    @State var nickname: String = ""
    @EnvironmentObject var vm: UserAuthModel
    @StateObject private var viewModel = IconViewModel()
    
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
                Spacer().frame(height: 100)
                Image(systemName: viewModel.currentIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .transition(AnyTransition.opacity.combined(with: .scale))
                    .padding()
                
                ORTextField(text: $nickname,placeholder: LM.Key.nick_name(), floatingPrompt: LM.Key.nick_name())
                    .padding(.bottom, 20)
                
                confirmButton()
                    .padding(.bottom, 10)
                
                Spacer()
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width )
        }
        .navigationTitle(LM.Key.nick_name())
    }
}

#Preview {
    WelcomePage()
}
