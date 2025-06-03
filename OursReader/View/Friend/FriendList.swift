//
//  FriendList.swift
//  OursReader
//
//  Created by Cliff Chan on 8/5/2024.
//

import SwiftUI

struct FriendList: View {
    @StateObject var model = DeviceFinderViewModel()
    @State private var showPeersView = false
    @State private var friendID = ""
    @State private var showCopyConfirmation = false
    @State private var showAddFriendConfirmation = false
    @State private var addFriendMessage = ""
    
    var body: some View {
        ZStack {
            ColorManager.shared.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    UserIDSection(showConfirmation: $showCopyConfirmation)
                    
                    Divider().styled()
                    
                    AddFriendSection(
                        friendID: $friendID,
                        showConfirmation: $showAddFriendConfirmation,
                        message: $addFriendMessage,
                        onAdd: addFriendByID
                    )
                    
                    Divider().styled()
                    
                    // Friends list would go here
                    
                    Spacer(minLength: 20)
                    
                    NearbyDiscoveryButton(action: { showPeersView = true })
                }
            }
            
            if showPeersView {
                NearbyPeersView(isPresented: $showPeersView, viewModel: model)
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: showPeersView)
            }
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
                            self.addFriendMessage = "Friend added successfully!"
                            friendID = ""
                            showConfirmationMessage()
                        case .failure(let error):
                            self.addFriendMessage = "Failed: \(error.localizedDescription)"
                            showConfirmationMessage()
                        }
                    }
                }
            } else {
                self.addFriendMessage = "User not found with that ID"
                showConfirmationMessage()
            }
        }
    }
    
    private func showConfirmationMessage() {
        withAnimation {
            showAddFriendConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            withAnimation {
                showAddFriendConfirmation = false
            }
        }
    }
}

// MARK: - Section Components
struct UserIDSection: View {
    @Binding var showConfirmation: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Your User ID")
            
            HStack {
                Text(UserAuthModel.shared.getCurrentFirebaseUser()?.uid ?? "Not signed in")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ColorManager.shared.rice_white)
                    .cornerRadius(8)
                    .foregroundColor(ColorManager.shared.red1)
                
                Button {
                    UIPasteboard.general.string = UserAuthModel.shared.getCurrentFirebaseUser()?.uid
                    showWithTimer(binding: $showConfirmation)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .padding(10)
                        .background(ColorManager.shared.rice_white)
                        .foregroundColor(ColorManager.shared.red1)
                        .cornerRadius(8)
                }
            }
            
            if showConfirmation {
                ConfirmationMessage(text: "Copied to clipboard!")
            }
        }
        .padding()
    }
}

struct AddFriendSection: View {
    @Binding var friendID: String
    @Binding var showConfirmation: Bool
    @Binding var message: String
    let onAdd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Add Friend by ID")
            
            HStack {
                StyledTextField(placeholder: "Enter friend's ID", text: $friendID)
                
                StyledButton(icon: "plus", action: onAdd)
            }
            
            if showConfirmation {
                ConfirmationMessage(
                    text: message,
                    color: message.contains("success") ? Color.green : Color.gray
                )
            }
        }
        .padding()
    }
}

struct NearbyDiscoveryButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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

// MARK: - Reusable UI Components
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(ColorManager.shared.red1)
            .padding(.horizontal)
    }
}

struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(ColorManager.shared.rice_white)
            .cornerRadius(8)
            .foregroundColor(ColorManager.shared.red1)
    }
}

struct StyledButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .padding(10)
                .background(ColorManager.shared.rice_white)
                .foregroundColor(Color.gray)
                .cornerRadius(8)
        }
    }
}

struct ConfirmationMessage: View {
    let text: String
    var color: Color = Color.gray
    
    var body: some View {
        Text(text)
            .foregroundColor(color)
            .font(.caption)
            .transition(.opacity)
            .padding(.top, 4)
    }
}

// MARK: - Extensions
extension View {
    func showWithTimer(binding: Binding<Bool>, duration: Double = 5) {
        withAnimation {
            binding.wrappedValue = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                binding.wrappedValue = false
            }
        }
    }
}

extension Divider {
    func styled() -> some View {
        self.background(ColorManager.shared.red1)
    }
}

// MARK: - NearbyPeersView
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

// MARK: - PeerCellView
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
