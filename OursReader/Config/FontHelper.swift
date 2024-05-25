//
//  FontHelper.swift
//  OursReader
//
//  Created by Cliff Chan on 25/5/2024.
//

import SwiftUI
import RswiftResources

extension Font {
    // Example:
    public static var workSansMedium12: Font {
        Font(R.font.workSansMedium(size: 12 + FontManager.currentFontSize.extraSize) ?? UIFont())
    }
    public static var workSansMedium16: Font {
        Font(R.font.workSansMedium(size: 16 + FontManager.currentFontSize.extraSize) ?? UIFont())
    }
    public static var workSansMedium14: Font {
        Font(R.font.workSansMedium(size: 14 + FontManager.currentFontSize.extraSize) ?? UIFont())
    }
    public static var workSansMedium20: Font {
        Font(R.font.workSansMedium(size: 20 + FontManager.currentFontSize.extraSize) ?? UIFont())
    }
    public static var workSansMedium22: Font {
        Font(R.font.workSansMedium(size: 22 + FontManager.currentFontSize.extraSize) ?? UIFont())
    }
    public static var workSansMedium24: Font {
        Font(R.font.workSansMedium(size: 24 + FontManager.currentFontSize.extraSize) ?? UIFont())
    }
    public static var workSansMedium28: Font {
        Font(R.font.workSansMedium(size: 28 + FontManager.currentFontSize.extraSize) ?? UIFont())
    }
    public static var workSansMedium32: Font {
        Font(R.font.workSansMedium(size: 32 + FontManager.currentFontSize.extraSize) ?? UIFont())
    }
    public static var workSans12: Font {
        Font(R.font.workSansRegular(size: 12 + FontManager.currentFontSize.extraSize) ?? UIFont())
    }
    public static var workSans14: Font {
        Font(R.font.workSansRegular(size: 14 + FontManager.currentFontSize.extraSize) ?? UIFont())
    }
    public static var workSans16: Font {
        Font(R.font.workSansRegular(size: 16 + FontManager.currentFontSize.extraSize) ?? UIFont())
    }
    public static var workSans28: Font {
        Font(R.font.workSansRegular(size: 28 + FontManager.currentFontSize.extraSize) ?? UIFont())
    }
    public static var workSans32: Font {
        Font(R.font.workSansRegular(size: 32 + FontManager.currentFontSize.extraSize) ?? UIFont())
    }
}
