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
    @State  var gotoDashboard: Bool = false
    
    fileprivate func SignInButton() -> Button<Text> {
        Button(action: {
            vm.signIn()
        }) {
            Text("Sign In")
        }
    }
    
    fileprivate func SignOutButton() -> Button<Text> {
        Button(action: {
            vm.signOut()
        }) {
            Text("Sign Out")
        }
    }
    
    fileprivate func ProfilePic() -> some View {
        AsyncImage(url: URL(string: vm.profilePicUrl))
            .frame(width: 100, height: 100)
    }
    
    fileprivate func UserInfo() -> Text {
        return Text(vm.givenName)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink(destination: Home().navigationBarHidden(true)
                               , isActive: $vm.isLoggedIn) {
                    EmptyView()
                }
                
                UserInfo()
                ProfilePic()
                if(vm.isLoggedIn){
                    SignOutButton()
                }else{
                    SignInButton()
                }
                Text(vm.errorMessage)
                
            }
            .navigationTitle("Login")
            
        }
        
    }
    
}

#Preview {
    Login()
}
