//
//  PushSettingListView.swift
//  OursReader
//
//  Created by Cliff Chan on 13/10/2024.
//

import SwiftUI

import SwiftUI

struct PushSettingListView: View {
    @ObservedObject var viewModel: PushSettingListViewModel
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: GridItem(), count: 2)) {
                PushSettingCellView(viewModel: viewModel)

                AddPushSettingCellView(viewModel: viewModel)
            }
            .padding(15)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }
}

//MARK: Normal Cell
struct PushSettingCellView: View {
    @ObservedObject var viewModel: PushSettingListViewModel
    
    var body: some View {
        if viewModel.isLoading {
            ProgressView("Loading...")
                .onAppear(perform: viewModel.fetchPushSettings)
        } else {
            ForEach(viewModel.pushSettings, id: \.self) { setting in
                NotificationItemView(push: setting, color: ButtonListType.push_notification.color)
            }
        }
    }
}


struct NotificationItemView: View {
    let push: Push_Setting
    let color: Color
    @StateObject var notificationManager = NotificationManager()
    @State private var isShaking = false
    @State var presentSheet = false

    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(color)
            .frame(height: 100)
            .overlay {
                ZStack {
                    VStack(alignment: .leading) {
                        Text(push.title ?? "")
                            .font(.headline)
                            .foregroundColor(Color(hex: "BC2649"))

                        Text(push.body ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(15)
                    .frame(maxWidth: .infinity, alignment: .leading)

//                    HStack {
//                        Spacer()
//                        VStack {
//                            EditNotificationButton {
//                                print("按鈕被點擊！")
//                                presentSheet = true
//                            }
//                            Spacer()
//                        }
//                    }
                }
            }
            .offset(x: isShaking ? -10 : 0)
            .animation(
                .interpolatingSpring(stiffness: 100, damping: 5)
                    .repeatCount(3, autoreverses: true),
                value: isShaking
            )
            .onTapGesture {
                withAnimation {
                    isShaking = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isShaking = false 
                }

                DatabaseManager.shared.getAllFriendsToken { result in
                    switch result {
                    case .success(let tokens):
                        notificationManager.sendPushNotification(
                            to: tokens,
                            title: push.title ?? "",
                            body: push.body ?? ""
                        ) { result in
                            switch result {
                            case .success(let response):
                                print("Notification sent successfully: \(response)")
                            case .failure(let error):
                                print("Error sending notification: \(error.localizedDescription)")
                            }
                        }
                    case .failure(let error):
                        print("Error getting all friends token: \(error.localizedDescription)")
                    }
                }
            }
            .sheet(isPresented: $presentSheet) {
                EditPushBottomSheet(
                    pushTitle: .constant("hhi"),
                    pushBody: .constant("bbbb")
                ) {
                    print("Push Notification Updated:")
                    // 可在此呼叫更新 API 或儲存新資料
                }
            }
    }
}

struct EditNotificationButton: View {
    @State private var isButtonClicked = false

    var action: () -> Void

    var body: some View {
        Button(action: {
            isButtonClicked.toggle()
            action()
        }) {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(.gray)
                .font(.system(size: 30))
                .symbolEffect(.bounce.up.byLayer, value: isButtonClicked) // 動畫效果
        }
        .padding([.top, .trailing], 10)
    }
}

//MARK: Add Cell
struct AddPushSettingCellView: View {
    @State private var showAddSettingSheet = false
    @State private var newTitle: String = ""
    @State private var newBody: String = ""
    @ObservedObject var viewModel: PushSettingListViewModel
    
    var body: some View {
        Button(action: {
            showAddSettingSheet.toggle()
        }) {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.firstTab)
                .frame(height: 100)
                .overlay {
                    ZStack {
                        VStack(alignment: .leading) {
                            Text("加多幾個通知")
                                .font(.headline)
                                .foregroundColor(Color(hex: "BC2649"))
                            
                            Text("發揮小宇宙")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(15)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "pencil.tip.crop.circle.badge.plus")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 30))
                                    .padding([.top, .trailing], 10)
                                Spacer()
                            }
                        }
                    }
                }
        }
        .sheet(isPresented: $showAddSettingSheet) {
            EditPushBottomSheet(pushTitle: $newTitle,pushBody: $newBody) {
                viewModel.addPushSetting(title: newTitle, body: newBody) { result in
                    switch result {
                    case .success():
                        newTitle = ""
                        newBody = ""
                        viewModel.fetchPushSettings()
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}


