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
        let newSetting = Push_Setting(id: UUID().uuidString, title: title, body: body)
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
    
    func removePushSetting(withID id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        DatabaseManager.shared.deletePushSetting(id: id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    // 使用 first(where:) 找到匹配的設定
                    if let index = self.pushSettings.firstIndex(where: { $0.id == id }) {
                        self.pushSettings.remove(at: index) // 成功後從本地陣列中移除
                        completion(.success(()))
                    } else {
                        completion(.failure(NSError(domain: String(localized: "error_setting_not_found"), code: -1, userInfo: nil)))
                    }
                case .failure(let error):
                    print("Failed to delete push setting: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

    func editPushSetting(withID id: String, newTitle: String, newBody: String, completion: @escaping (Result<Void, Error>) -> Void) {
            let updatedSetting = Push_Setting(id: id, title: newTitle, body: newBody)
            
            DatabaseManager.shared.updatePushSetting(updatedSetting) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success():
                        if let index = self.pushSettings.firstIndex(where: { $0.id == id }) {
                            self.pushSettings[index] = updatedSetting
                            completion(.success(()))
                        } else {
                            completion(.failure(NSError(domain: String(localized: "error_setting_not_found"), code: -1, userInfo: nil)))
                        }
                    case .failure(let error):
                        print("Failed to edit push setting: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
            }
        }
}
