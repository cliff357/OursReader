//
//  ColorHelper.swift
//  OursReader
//
//  Created by Cliff Chan on 3/4/2024.
//

import SwiftUI


class ColorManager {
    
    /// 單例實例
    static let shared = ColorManager()
    
    /// 私有初始化，防止外部實例化
    private init() {}
    
    var flesh1: Color {
        Color("flesh1")
    }
    
    var dark_brown: Color {
        Color("dark_brown")
    }
    
    var rice_white: Color {
        Color("rice_white")
    }
    
    var orange1: Color {
        Color("orange1")
    }
    
    var red1: Color {
        Color("red1")
    }
    
    var green1: Color {
        Color("green1")
    }
    
    var dark_brown2: Color {
        Color("dark_brown2")
    }
    
    var background: Color {
        Color("background")
    }
    
    var firstTab: Color {
        Color("first_tab")
    }
    
    var secondTab: Color {
        Color("second_tab")
    }
    
    var thirdTab: Color {
        Color("third_tab")
    }
}
