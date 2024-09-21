//
//  Dashboard.swift
//  OursReader
//
//  Created by Autotoll Developer on 7/5/2024.
//

import SwiftUI

struct Dashboard: View {
    /// Tab Progress
    @State private var tabProgress: CGFloat = 0
    @State private var selectedTab: Tab?
    @State private var selectedButtonListType: ButtonListType = .push_notification
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 15) {
                Spacer().frame(height: 15)
                
                
                CustomTabBar()
                
                //Paging View using new iOS 17 APIS
                GeometryReader {
                    let size = $0.size
                    
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
                            /// Converting offset into progress
                            let progress = -value / (size.width * CGFloat(Tab.allCases.count - 1))
                            /// Capping Progress BTW 0-1
                            tabProgress = max(min(progress, 1),0)
                            
                            /// Determine the current page based on offset
                            let currentPage = Int(round(-value / size.width))
                            
                            /// Update the `selectedButtonListType` based on currentPage
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
//            .background(Color.background)
        }
        
    }
    
    @ViewBuilder
    func CustomTabBar() -> some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                HStack(spacing: 10) {
                    Image(systemName: tab.systemImage)
                    
                    Text(tab.name)
                        .font(.callout)
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
        
        /// Scrollable Active Tab Indicator
        .background() {
            GeometryReader {
                let size = $0.size
                let capsuleWidth = size.width / CGFloat(Tab.allCases.count)
                
                Capsule()
//                    .fill(scheme == .dark ? Color.green1 : Color.red1)
                    .fill(Color.green1)
                    .frame(width: capsuleWidth)
                    .offset(x: tabProgress * (size.width - capsuleWidth))
            }
        }
        .background(.gray.opacity(0.1), in: .capsule)
        .padding(.horizontal, 15)
    }
    
    @ViewBuilder
    func BooklistView(type: ButtonListType) -> some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: GridItem(), count: 2), content: {
                switch type {
                case .push_notification:
                    ForEach(pushNotificationList, id: \.id) { push in
                        RoundedRectangle(cornerRadius: 15)
                            .fill(type.color)
                            .frame(height: 100)
                            .overlay {
                                VStack(alignment: .leading) {
                                    Text(push.title)
                                        .font(.headline)
                                        .foregroundColor(Color(hex: "BC2649"))
                                    Text(push.message)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding(15)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                    }
                    
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
                                    Text(ebook.title)
                                        .font(.headline)
                                    
                                    Text(ebook.name)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text(ebook.instruction)
                                        .font(.body)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                    
                                    Spacer()
                                }
                                .padding(15)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                    }
                }
                
            })
            .padding(15)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }
}

#Preview {
    Dashboard()
}
