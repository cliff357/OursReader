//
//  Dashboard.swift
//  OursReader
//
//  Created by Autotoll Developer on 7/5/2024.
//

import SwiftUI

struct Dashboard: View {
    @State private var tabProgress: CGFloat = 0
    @State private var selectedTab: Tab?
    @State private var selectedButtonListType: ButtonListType = .push_notification
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 15) {
                Spacer().frame(height: 15)
                
                CustomTabBar()
                
                // Paging View using new iOS 17 APIS
                GeometryReader { geometry in
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 0 ) {
                            BooklistView(type: selectedButtonListType)
                                .id(Tab.push)
                                .containerRelativeFrame(.horizontal)
                            
                            BooklistView(type: selectedButtonListType)
                                .id(Tab.widget)
                                .containerRelativeFrame(.horizontal)
                            
                            BooklistView(type: selectedButtonListType)
                                .id(Tab.ebook)
                                .containerRelativeFrame(.horizontal)
                        }
                        .scrollTargetLayout()
                        .offsetX { value in
                            let progress = -value / (geometry.size.width * CGFloat(Tab.allCases.count - 1))
                            tabProgress = max(min(progress, 1), 0)
                            
                            let currentPage = Int(round(-value / geometry.size.width))
                            switch currentPage {
                            case 0:
                                selectedButtonListType = .push_notification
                                selectedTab = .push
                            case 1:
                                selectedButtonListType = .widget
                                selectedTab = .widget
                            case 2:
                                selectedButtonListType = .ebook
                                selectedTab = .ebook
                            default:
                                break
                            }
                        }
                    }
                    .scrollPosition(id: $selectedTab)
                    .scrollIndicators(.hidden)
                    .scrollTargetBehavior(.paging)
                    .scrollClipDisabled()
                }
            }
        }
    }
    
    @ViewBuilder
    func CustomTabBar() -> some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                HStack(spacing: 10) {
                    Image(systemName: tab.systemImage)
                    Text(tab.name).font(.callout)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .contentShape(.capsule)
                .onTapGesture {
                    withAnimation(.snappy) {
                        selectedTab = tab
                        switch tab {
                        case .push:
                            selectedButtonListType = .push_notification
                        case .widget:
                            selectedButtonListType = .widget
                        case .ebook:
                            selectedButtonListType = .ebook
                        }
                    }
                }
            }
        }
        .background {
            GeometryReader { geometry in
                let capsuleWidth = geometry.size.width / CGFloat(Tab.allCases.count)
                Capsule()
                    .fill(Color.green1)
                    .frame(width: capsuleWidth)
                    .offset(x: tabProgress * (geometry.size.width - capsuleWidth))
            }
        }
        .background(Color.gray.opacity(0.1), in: .capsule)
        .padding(.horizontal, 15)
    }
    
    @ViewBuilder
    func BooklistView(type: ButtonListType) -> some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: GridItem(), count: 2)) {
                switch type {
                case .push_notification:
                    PushSettingView()
                    
                case .widget:
                    ForEach(widgetList, id: \.id) { widget in
                        RoundedRectangle(cornerRadius: 15)
                            .fill(type.color)
                            .frame(height: 100)
                            .overlay {
                                VStack(alignment: .leading) {
                                    Text(widget.name)
                                        .font(.headline)
                                        .foregroundColor(Color(hex: "FFFFFF"))
                                    Text(widget.actionCode)
                                        .font(.subheadline)
                                        .foregroundColor(Color(hex: "FFD741"))
                                }
                                .padding(15)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                    }
                    
                case .ebook:
                    ForEach(ebookList, id: \.id) { ebook in
                        RoundedRectangle(cornerRadius: 15)
                            .fill(type.color)
                            .frame(height: 150)
                            .overlay {
                                VStack(alignment: .leading) {
                                    Text(ebook.title).font(.headline)
                                    Text(ebook.name).font(.subheadline).foregroundColor(.gray)
                                    Text(ebook.instruction).font(.body).foregroundColor(.gray).lineLimit(2)
                                    Spacer()
                                }
                                .padding(15)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                    }
                }
            }
            .padding(15)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }
}

struct PushSettingView: View {
    @State private var pushSettings: [Push_Setting] = []
    @State private var isLoading = true
    
    var body: some View {
        if isLoading {
            ProgressView("Loading...") // 顯示載入中指示
                .onAppear(perform: fetchPushSettings)
        } else {
            ForEach(pushSettings, id: \.self) { setting in
                NotificationItemView(
                    push: setting,
                    color: ButtonListType.push_notification.color
                )
            }
        }
    }
    
    private func fetchPushSettings() {
        DatabaseManager.shared.getUserPushSetting { result in
            switch result {
            case .success(let settings):
                self.pushSettings = settings
            case .failure(let error):
                print("Failed to fetch push settings: \(error.localizedDescription)")
                self.pushSettings = [Push_Setting.defaultSetting]
            }
            isLoading = false
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

                    HStack {
                        Spacer()
                        VStack {
                            EditNotificationButton {
                                print("按鈕被點擊！")
                                presentSheet = true
                            }
                            Spacer()
                        }
                    }
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
                    isShaking = false // 恢復原狀
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

#Preview {
    Dashboard()
}
