//
//  ColorHelper.swift
//  OursReader
//
//  Created by Autotoll Developer on 3/4/2024.
//

import SwiftUI
import RswiftResources

extension Color {
    public static let flesh1: Color = R.color.flesh1.color
    public static let dark_brown: Color = R.color.dark_brown.color
    public static let rice_white: Color = R.color.rice_white.color
    public static let orange1: Color = R.color.orange1.color
    public static let red1: Color = R.color.red1.color
    public static let green1: Color = R.color.green1.color
    public static let dark_brown2: Color = R.color.dark_brown2.color
    public static let background: Color = R.color.background.color
    
    //Dashboard
    public static let firstTab: Color = R.color.first_tab.color
    public static let secondTab: Color = R.color.second_tab.color
    public static let thirdTab: Color = R.color.third_tab.color
}

extension RswiftResources.ColorResource {
    var color: Color {
        Color(name)
    }
}
