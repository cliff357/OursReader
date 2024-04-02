//
//  Profile.swift
//  OursReader
//
//  Created by Autotoll Developer on 27/3/2024.
//

import SwiftUI

struct Profile: View {
    var body: some View {
        Button {
            UserAuthModel.shared.signOut()
        } label: {
            Text("Logout!")
        }

    }
}

#Preview {
    Profile()
}
