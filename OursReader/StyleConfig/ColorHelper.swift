//
//  ColorHelper.swift
//  OursReader
//
//  Created by Autotoll Developer on 3/4/2024.
//

import SwiftUI
import RswiftResources

extension Color {
    public static let menu_bkgd: Color = R.color.menu_bkgd.color
    public static let circle_color: Color = R.color.circle_color.color
    public static let button_solid_bkgd: Color = R.color.button_solid_bkgd.color
    public static let button_hollow_outline: Color = R.color.button_hollow_outline.color
    public static let button_hollow_bkgd: Color = R.color.button_hollow_bkgd.color
    public static let button_selected: Color = R.color.button_selected.color
}

extension RswiftResources.ColorResource {
    var color: Color {
        Color(name)
    }
}
