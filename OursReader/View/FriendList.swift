//
//  FriendList.swift
//  OursReader
//
//  Created by Autotoll Developer on 8/5/2024.
//

import SwiftUI

struct FriendList: View {
    @StateObject var model = DeviceFinderViewModel()
    @State private var toast: Toast? = nil
    
    var body: some View {
        ZStack {
            //Should check have user grand notification permission, otherwise, should not able to exchange data
            
            Color.background.ignoresSafeArea()

            List(model.peers) { peer in
                VStack {
                    HStack {
                        Image(systemName: "person.wave.2")
                            .imageScale(.large)
                            .foregroundColor(Color.rice_white)
                        
                        Text(peer.peerId.displayName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        
                        Button {
                            if model.joinedPeer.contains(where: { $0.peerId == peer.peerId }) {
                                model.sendUserData()
                            } else {
                                model.selectedPeer = peer
                            }
                        }
                        label: {
                            Text(model.joinedPeer.contains(where: { $0.peerId == peer.peerId }) ?
                                 "Send" : "Connect" )
                                .foregroundColor(Color.rice_white)
                            
                        }
                    }
                }
                .listRowBackground(Color.dark_brown2)
                .padding(.vertical, 5)
            }
            .scrollContentBackground(.hidden)
            
            //Receive  message from other peer
            .alert(item: $model.permissionRequest, content: { request in
                Alert(
                    title: Text("Start linking to  \(request.peerId.displayName)"),
                    primaryButton: .default(Text("Start! "), action: {
                        request.onRequest(true)
                        model.show(peerId: request.peerId)
                    }),
                    secondaryButton: .cancel(Text("No"), action: {
                        request.onRequest(false)
                    })
                )
            })
            .onAppear {
                model.startBrowsing()
            }
            .onDisappear {
                model.finishBrowsing()
            }
        }
        .onChange(of: model.toastMsg, { oldValue, newValue in
            toast = Toast(style: .warning, message: newValue)
        })
        .toastView(toast: $toast)
            
    }
}

#Preview {
    FriendList()
}
