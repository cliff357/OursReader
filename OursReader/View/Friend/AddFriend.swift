//
//  AddFriend.swift
//  OursReader
//
//  Created by Cliff Chan on 8/5/2024.
//

import SwiftUI

struct AddFriend: View {
    @Environment(\.dismiss) private var dismiss
    @State private var friendID = ""
    @State private var showCopyConfirmation = false
    @State private var showAddFriendConfirmation = false
    @State private var addFriendMessage = ""
    @State private var showPeersView = false
    @StateObject var model = DeviceFinderViewModel()
    
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
                    
                    NearbyDiscoveryButton(action: { showPeersView = true })
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ColorManager.shared.red1)
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

#Preview {
    NavigationStack {
        AddFriend()
    }
}
