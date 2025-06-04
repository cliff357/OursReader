//
//  FriendList.swift
//  OursReader
//
//  Created by Cliff Chan on 8/5/2024.
//

import SwiftUI

struct FriendList: View {
    @StateObject private var viewModel = FriendListViewModel()
    @State private var showAddFriendSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorManager.shared.background.ignoresSafeArea()
                
                VStack {
                    // Custom header with add button
                    HStack {
                        Text("Friends")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorManager.shared.red1)
                        
                        Spacer()
                        
                        Button {
                            showAddFriendSheet = true
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "person.badge.plus")
                                Text("Add")
                            }
                            .padding(8)
                            .background(ColorManager.shared.rice_white.opacity(0.3))
                            .cornerRadius(8)
                            .foregroundColor(ColorManager.shared.red1)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Main content
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(ColorManager.shared.rice_white)
                        } else if viewModel.friends.isEmpty {
                            emptyStateView
                        } else {
                            friendListView
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddFriendSheet) {
                NavigationStack {
                    AddFriend()
                }
            }
            .onAppear(perform: viewModel.loadFriends)
            .refreshable {
                await viewModel.loadFriendsAsync()
            }
        }
    }
    
    // MARK: - View Components
    
    // Keep this for compatibility but it won't be used with navigationBarHidden(true)
    private var addFriendButton: some View {
        Button {
            showAddFriendSheet = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "person.badge.plus")
                Text("Add")
            }
            .padding(8)
            .background(ColorManager.shared.rice_white.opacity(0.2))
            .cornerRadius(8)
            .foregroundColor(ColorManager.shared.red1)
        }
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "person.2.slash",
            title: "No Friends Yet",
            message: "Add friends to connect and share stories together.",
            buttonTitle: "Add Friend",
            action: { showAddFriendSheet = true }
        )
    }
    
    private var friendListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.friends) { friend in
                    FriendRow(friend: friend)
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.removeFriend(friend)
                            } label: {
                                Label("Remove Friend", systemImage: "person.badge.minus")
                            }
                        }
                }
            }
            .padding(.horizontal)
            .padding(.top)
        }
    }
}

// MARK: - View Model
class FriendListViewModel: ObservableObject {
    @Published var friends: [UserObject] = []
    @Published var isLoading = false
    
    func loadFriends() {
        isLoading = true
        
        DatabaseManager.shared.getFriendsList { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let friends):
                    self?.friends = friends
                case .failure(let error):
                    self?.friends = []
                    print("Error loading friends: \(error.localizedDescription)")
                    // Error handling here if needed
                }
            }
        }
    }
    
    // Added async version for refreshable
    @MainActor
    func loadFriendsAsync() async {
        isLoading = true
        
        do {
            friends = try await DatabaseManager.shared.getFriendsListAsync()
        } catch {
            friends = []
            print("Error loading friends: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func removeFriend(_ friend: UserObject) {
        guard let friendID = friend.userID else { return }
        
        DatabaseManager.shared.removeFriend(friendID: friendID) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.friends.removeAll { $0.userID == friendID }
                case .failure(let error):
                    print("Error removing friend: \(error.localizedDescription)")
                    // Error handling here if needed
                }
            }
        }
    }
}
