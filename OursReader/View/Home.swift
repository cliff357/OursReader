//
//  Home.swift
//  OursReader
//
//  Created by Cliff Chan on 15/11/2023.
//

import SwiftUI

struct Home: View {
    @State private var selectedTab: Tab?
    @Environment(\.colorScheme) private var scheme
    /// Tab Progress
    @State private var tabProgress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Button(action: {}, label: {
                    Image(systemName: "line.3.horizontal.decrease")
                })
                
                Spacer()
                
                Button(action: {}, label: {
                    Image(systemName: "bell.badge")
                })
            }
            .font(.title2)
            .overlay {
                Text("Messages")
                    .font(.title3.bold())
            }
            .foregroundStyle(.primary)
            .padding(15)
            
            CustomTabBar()
            
            //Paging View using new iOS 17 APIS
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0 ) {
                    SampleView(.purple)
                        .containerRelativeFrame(.horizontal)
                    
                    SampleView(.red)
                        .containerRelativeFrame(.horizontal)
                    
                    SampleView(.blue)
                        .containerRelativeFrame(.horizontal)
                }
            }
            .scrollPosition(id: $selectedTab)
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollClipDisabled()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.gray.opacity(0.1))
        .onChange(of: selectedTab) { oldValue, newValue in
            print("changed ")
        }
    }
    
    @ViewBuilder
    func CustomTabBar() -> some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                HStack(spacing: 10) {
                    Image(systemName: tab.systemImage)
                    
                    Text(tab.rawValue)
                        .font(.callout)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .contentShape(.capsule)
                .onTapGesture {
                    withAnimation(.snappy) {
                        selectedTab = tab
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
                    .fill(scheme == .dark ? .black : .white)
                    .frame(width: capsuleWidth)
                    .offset(x: tabProgress * (size.width - capsuleWidth))
            }
        }
        .background(.gray.opacity(0.1), in: .capsule)
        .padding(.horizontal, 15)
    }
    
    // Sample View for Demonstrating Scrollabel Tab Bar Indicator
    @ViewBuilder
    func SampleView(_ color: Color) -> some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: GridItem(), count: 2), content: {
                ForEach(1...10,id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 15)
                        .fill(color.gradient)
                        .frame(height: 150)
                }
                
            })
            .padding(15)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .mask {
                Rectangle()
                    .padding(.bottom, -100)
            }
        }
    }
}

#Preview {
    ContentView()
}
