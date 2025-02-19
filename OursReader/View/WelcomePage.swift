//
//  WelcomePage.swift
//  OursReader
//
//  Created by Cliff Chan on 2/4/2024.
//

import SwiftUI

import Combine

class IconViewModel: ObservableObject {
    @Published var currentIcon: String = "cover_image_1"
    
    private var images = ["cover_image_1", "cover_image_2", "cover_image_3"]
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
        index = (index + 1) % images.count
        withAnimation(.easeOut(duration: 1)) {
            currentIcon = images[index]
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
            Text("general_done")
                .padding(20)
        }
        .background(ColorManager.shared.rice_white)
        .foregroundStyle(ColorManager.shared.dark_brown2)
        .clipShape(Capsule())
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
                .offset(y: UIScreen.main.bounds.width * 0.8)
            
            VStack {
                Spacer().frame(height: 100)
                
                Image(viewModel.currentIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 400, height: 400)
                    .transition(AnyTransition.opacity.combined(with: .scale))
                    .padding()
                
                ORTextField(text: $nickname,placeholder: String(localized: "nick_name"), floatingPrompt: String(localized: "nick_name"))
                    .padding(.bottom, 20)
                
                confirmButton()
                    .padding(.bottom, 10)
                
                Spacer()
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width )
        }
        .navigationTitle("nick_name")
    }
}

#Preview {
    WelcomePage()
}
