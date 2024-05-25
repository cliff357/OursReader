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
            List(model.peers) { peer in
                HStack {
                    Image(systemName: "iphone.gen1")
                        .imageScale(.large)
                        .foregroundColor(.accentColor)
                    
                    Text(peer.peerId.displayName)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 5)
                .onTapGesture {
                    model.selectedPeer = peer
//                    HomeRouter.shared.push(to: .friendDetail)
                }
            }
            //Receive message from other peer
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
//        }
    }
}

#Preview {
    FriendList()
}
