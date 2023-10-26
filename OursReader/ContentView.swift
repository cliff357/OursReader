//
//  ContentView.swift
//  OursReader
//
//  Created by Cliff Chan on 18/10/2023.
//

import SwiftUI

struct ContentView: View {
    
    @State private var pickerType: TripPicker = .normal
    var body: some View {
        VStack {
            Picker("", selection: $pickerType) {
                ForEach(TripPicker.allCases, id: \.rawValue) {
                    Text($0.rawValue)
                        .tag($0)
                }
                .pickerStyle(.segmented)
                .padding()
                
                Spacer(minLength: 0)
            }
            
            ScrollView(.horizontal) {
                HStack(spacing: 35) {
                    ForEach(1...8, id: \.self) { index in
//                        Image("Pick \()    ")
                    }
                }
            }
            .scrollIndicators(.hidden)
        }

        
        
        
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


enum TripPicker: String, CaseIterable {
    case scaled = "Scaled"
    case normal = "Normal"
}
