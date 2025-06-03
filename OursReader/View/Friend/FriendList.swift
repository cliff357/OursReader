//
//  FriendList.swift
//  OursReader
//
//  Created by Cliff Chan on 8/5/2024.
//

import SwiftUI

struct FriendList: View {
    @StateObject var model = DeviceFinderViewModel()
    @State private var toast: Toast? = nil
    @State private var showPeersView = false
    @State private var friendID = ""
    @State private var showCopyConfirmation = false
    
    var body: some View {
        ZStack {
            ColorManager.shared.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // User ID display section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your User ID")
                            .font(.headline)
                            .foregroundColor(ColorManager.shared.red1)
                        
                        HStack {
                            Text(UserAuthModel.shared.getCurrentFirebaseUser()?.uid ?? "Not signed in")
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(ColorManager.shared.rice_white)
                                .cornerRadius(8)
                                .foregroundColor(ColorManager.shared.rice_white)
                            
                            Button {
                                UIPasteboard.general.string = UserAuthModel.shared.getCurrentFirebaseUser()?.uid
                                withAnimation {
                                    showCopyConfirmation = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        showCopyConfirmation = false
                                    }
                                }
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .padding(10)
                                    .background(ColorManager.shared.rice_white)
                                    .foregroundColor(ColorManager.shared.red1)
                                    .cornerRadius(8)
                            }
                        }
                        
                        if showCopyConfirmation {
                            Text("Copied to clipboard!")
                                .foregroundColor(Color.gray)
                                .font(.caption)
                                .transition(.opacity)
                        }
                    }
                    .padding()
                    
                    Divider()
                        .background(ColorManager.shared.red1)
                    
                    // Add friend by ID section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Friend by ID")
                            .font(.headline)
                            .foregroundColor(ColorManager.shared.red1)
                        
                        HStack {
                            // Extract TextField into a simpler form
                            friendIdTextField
                            
                            // Extract Button into a simpler form
                            addFriendButton
                        }
                    }
                    .padding()
                    
                    Divider()
                        .background(ColorManager.shared.red1)
                    
                    // Friends list section (keeping existing functionality)
                    Text("Your Friends")
                        .font(.headline)
                        .foregroundColor(ColorManager.shared.red1)
                        .padding(.horizontal)
                    
                    // Here would go the friends list display
                    
                    Spacer(minLength: 20)
                    
                    // Secondary feature - Nearby discovery
                    Button {
                        showPeersView = true
                    } label: {
                        HStack {
                            Image(systemName: "wave.3.right")
                            Text("Find Friends Nearby")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorManager.shared.rice_white)
                        .foregroundColor(ColorManager.shared.red1)
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }
            
            if showPeersView {
                NearbyPeersView(isPresented: $showPeersView, viewModel: model)
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: showPeersView)
            }
        }
    }
    
    // MARK: - Extracted Views
    private var friendIdTextField: some View {
        TextField("Enter friend's ID", text: $friendID)
            .padding()
            .background(ColorManager.shared.rice_white)
            .cornerRadius(8)
            .foregroundColor(ColorManager.shared.red1)
    }
    
    private var addFriendButton: some View {
        Button {
            addFriendByID()
        } label: {
            Image(systemName: "plus")
                .padding(10)
                .background(ColorManager.shared.rice_white)
                .foregroundColor(Color.gray)
                .cornerRadius(8)
        }
    }
    
    private func addFriendByID() {
        guard !friendID.isEmpty else { return }
        
        DatabaseManager.shared.checkUserExist(userID: friendID) { exists in
            if exists {
                // Create a minimal UserObject with just the ID
                let friendUser = UserObject(name: nil, userID: friendID, fcmToken: nil, email: nil, login_type: nil)
                
                // Add the friend
                DatabaseManager.shared.addFriend(friend: friendUser) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            toast = Toast(style: .success, message: "Friend added successfully!")
                            friendID = ""
                        case .failure(let error):
                            toast = Toast(style: .error, message: "Failed to add friend: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                toast = Toast(style: .warning, message: "User not found with that ID")
            }
        }
    }
}

struct NearbyPeersView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: DeviceFinderViewModel
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Content
            VStack(spacing: 16) {
                headerView
                peerListView
                Spacer()
            }
            .background(ColorManager.shared.background)
            .cornerRadius(15)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .alert(item: $viewModel.permissionRequest) { request in
            Alert(
                title: Text("Start linking to \(request.peerId.displayName)"),
                primaryButton: .default(Text("Start!"), action: {
                    request.onRequest(true)
                    viewModel.peerJoin(peerId: request.peerId)
                }),
                secondaryButton: .cancel(Text("No"), action: {
                    request.onRequest(false)
                })
            )
        }
    }
    
    // MARK: - Extracted Views
    private var headerView: some View {
        HStack {
            Text("Find Nearby Friends")
                .font(.headline)
                .foregroundColor(ColorManager.shared.rice_white)
            
            Spacer()
            
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(ColorManager.shared.rice_white)
                    .imageScale(.large)
            }
        }
        .padding()
    }
    
    private var peerListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.peers) { peer in
                    PeerCellView(peer: peer, viewModel: viewModel)
                }
            }
        }
        .onAppear {
            viewModel.startBrowsing()
        }
        .onDisappear {
            viewModel.finishBrowsing()
        }
    }
}

struct PeerCellView: View {
    let peer: PeerDevice
    @ObservedObject var viewModel: DeviceFinderViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "person.wave.2")
                .imageScale(.large)
                .foregroundColor(ColorManager.shared.rice_white)
            
            Text(peer.peerId.displayName)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(ColorManager.shared.rice_white)
            
            connectButton
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var connectButton: some View {
        Button {
            handlePeerConnection()
        } label: {
            buttonLabel
        }
    }
    
    private var buttonLabel: some View {
        Text(isPeerJoined ? "Send Info" : "Connect")
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.gray)
            .foregroundColor(ColorManager.shared.rice_white)
            .cornerRadius(5)
    }
    
    private var isPeerJoined: Bool {
        viewModel.joinedPeer.contains(where: { $0.peerId == peer.peerId })
    }
    
    private func handlePeerConnection() {
        if isPeerJoined {
            viewModel.sendUserData()
        } else {
            viewModel.selectedPeer = peer
        }
    }
}

#Preview {
    FriendList()
}

