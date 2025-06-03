//
//  PushSettingsListView.swift
//  readerWatchOS Watch App
//
//  Created by Cliff Chan on 28/5/2025.
//

import SwiftUI

struct PushSettingsListView: View {
    @StateObject private var viewModel = PushSettingsViewModel()
    var isPhoneConnected: Bool
    @State private var isRefreshing = false
    
    init(isPhoneConnected: Bool = true) {
        self.isPhoneConnected = isPhoneConnected
    }
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                } else {
                    // 添加刷新提示區塊
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                            Text("下拉刷新")
                                .font(.caption2)
                        }
                        .foregroundColor(.gray)
                        .padding(.vertical, 4)
                        Spacer()
                    }
                    
                    // 手動刷新按鈕
                    Button(action: {
                        isRefreshing = true
                        Task {
                            await refreshData()
                            isRefreshing = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("刷新通知設定")
                            
                            if isRefreshing {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                    }
                    .disabled(isRefreshing)
                    
                    if viewModel.pushSettings.isEmpty {
                        Text("未找到通知設定")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(viewModel.pushSettings, id: \.id) { setting in
                            PushSettingRow(setting: setting, viewModel: viewModel)
                        }
                    }
                }
            }
            .navigationTitle("推送設定")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !isPhoneConnected {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("錯誤", isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("確定") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .task {
                await viewModel.fetchPushSettings()
                await viewModel.fetchFriendTokens()
            }
            .refreshable {
                await refreshData()
            }
        }
    }
    
    private func refreshData() async {
        // 添加震動反饋
        WKInterfaceDevice.current().play(.click)
        
        await viewModel.fetchPushSettings()
        await viewModel.fetchFriendTokens()
    }
}

struct PushSettingRow: View {
    let setting: Push_Setting
    @ObservedObject var viewModel: PushSettingsViewModel
    @State private var showConfirmation = false
    
    var body: some View {
        Button(action: {
            showConfirmation = true
        }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(setting.title ?? "")
                    .font(.headline)
                    .lineLimit(1)
                
                Text(setting.body ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog("發送推送通知？", isPresented: $showConfirmation) {
            Button("發送") {
                Task {
                    await viewModel.sendPushNotification(using: setting)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("確定向好友發送這個通知嗎？")
        }
        .disabled(viewModel.isSending)
        .overlay {
            if viewModel.isSending {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
    }
}
