//
//  FriendList.swift
//  OursReader
//
//  Created by Autotoll Developer on 8/5/2024.
//

import SwiftUI

struct FriendList: View {
    @StateObject var model = DeviceFinderViewModel()
    
    var body: some View {
        ZStack {
            //Should check have user grand notification permission, otherwise, should not able to exchange data
            
            Color.background.ignoresSafeArea()

            List(model.peers) { peer in
                HStack {
                    Image(systemName: "person.wave.2")
                        .imageScale(.large)
                        .foregroundColor(Color.rice_white)
                    
                    Text(peer.peerId.displayName)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if model.joinedPeer.contains(where: { $0.peerId == peer.peerId }) {
                        Text("Connected")
                            .foregroundColor(.green)
                            .padding(.horizontal)
                    }
                }
                .listRowBackground(Color.dark_brown2)
                .padding(.vertical, 5)
                .onTapGesture {
                    model.selectedPeer = peer
//                    HomeRouter.shared.push(to: .friendDetail)
                    print("list tabbed")
                }
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
           
            
    }
}

#Preview {
    FriendList()
}
