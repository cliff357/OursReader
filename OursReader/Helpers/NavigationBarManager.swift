import UIKit
import SwiftUI

class NavigationBarManager {
    static let shared = NavigationBarManager()
    
    private init() {}
    
    // 設置透明導航欄
    func setTransparentNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.clear
        appearance.shadowColor = UIColor.clear
        // 🔧 修改：保留標題文字，設為黑色
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        
        // 🔧 修改：保留返回按鈕，設為黑色
        UINavigationBar.appearance().tintColor = UIColor.black
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    // 設置默認導航欄外觀
    func setDefaultNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(ColorManager.shared.background)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        
        UINavigationBar.appearance().tintColor = UIColor.black
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    // 完全隱藏導航欄
    func hideNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.clear
        appearance.shadowColor = UIColor.clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.clear]
        
        UINavigationBar.appearance().tintColor = UIColor.clear
        UINavigationBar.appearance().isHidden = true
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

// SwiftUI View Modifier 擴展
extension View {
    func transparentNavigationBar() -> some View {
        self.onAppear {
            NavigationBarManager.shared.setTransparentNavigationBar()
        }
        .onDisappear {
            NavigationBarManager.shared.setDefaultNavigationBar()
        }
    }
    
    func defaultNavigationBar() -> some View {
        self.onAppear {
            NavigationBarManager.shared.setDefaultNavigationBar()
        }
    }
}
