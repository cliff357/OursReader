//
//  Login.swift
//  OursReader
//
//  Created by Cliff Chan on 17/3/2024.
//

import SwiftUI

struct Login: View {
    var body: some View {
        NavigationStack {
               NavigationLink {
                    Home()
               } label: {
                    Text("Goto Next Screen")
               }
        }
    }
}

#Preview {
    Login()
}
