//
//  FriendSharedComponents.swift
//  OursReader
//
//  Created by Cliff Chan on 8/5/2024.
//

import SwiftUI

// MARK: - Extensions
extension View {
    /// Shows a view with a timer for automatic dismissal
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
    /// Styled divider with consistent appearance
    func styled() -> some View {
        self.background(ColorManager.shared.red1)
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

// MARK: - Section Components
struct UserIDSection: View {
    @Binding var showConfirmation: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: String(localized: "friend_your_user_id"))
            
            HStack {
                Text(UserAuthModel.shared.getCurrentFirebaseUser()?.uid ?? String(localized: "friend_not_signed_in"))
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
                ConfirmationMessage(text: String(localized: "friend_copied_to_clipboard"))
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
            SectionHeader(title: String(localized: "friend_add_by_id"))
            
            HStack {
                StyledTextField(placeholder: String(localized: "friend_enter_id"), text: $friendID)
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
                Text(String(localized: "friend_find_nearby"))
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

// MARK: - NearbyPeersView and Support Components
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
            let name = request.peerId.displayName
            return Alert(
                title: Text("friend_linking_request \(name)"),
                primaryButton: .default(Text("friend_linking_start"), action: {
                    request.onRequest(true)
                    viewModel.peerJoin(peerId: request.peerId)
                }),
                secondaryButton: .cancel(Text("general_no"), action: {
                    request.onRequest(false)
                })
            )
        }
    }
    
    private var headerView: some View {
        HStack {
            Text(String(localized: "friend_nearby_title"))
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
        Text(isPeerJoined ? String(localized: "friend_send_info") : String(localized: "friend_connect"))
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
