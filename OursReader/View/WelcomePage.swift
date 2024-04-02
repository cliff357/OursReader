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
        Image("welcome_background")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(minWidth: 0, maxWidth: .infinity)
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    WelcomePage()
}
