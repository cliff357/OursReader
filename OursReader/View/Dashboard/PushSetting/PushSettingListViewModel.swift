//
//  PushSettingListViewModel.swift
//  OursReader
//
//  Created by Cliff Chan on 13/10/2024.
//

import SwiftUI
import Combine

class PushSettingListViewModel: ObservableObject {
    @Published var pushSettings: [Push_Setting] = []
    @Published var isLoading = true
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchPushSettings()
    }
    
    func fetchPushSettings() {
        DatabaseManager.shared.getUserPushSetting { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let settings):
                    self.pushSettings = settings
                case .failure(let error):
                    print("Failed to fetch push settings: \(error.localizedDescription)")
                    self.pushSettings = [Push_Setting.defaultSetting]
                }
                self.isLoading = false
            }
        }
    }
    
    func addPushSetting(title: String, body: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let newSetting = Push_Setting(title: title, body: body)
        DatabaseManager.shared.addPushSetting(newSetting) { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    self.pushSettings.append(newSetting)
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}
