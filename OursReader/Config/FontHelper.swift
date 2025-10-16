//
//  FontHelper.swift
//  OursReader
//
//  Created by Cliff Chan on 25/5/2024.
//

import SwiftUI


class FontHelper {
    
    /// 單例實例
    static let shared = FontHelper()
    
    /// 私有初始化，防止外部實例化
    private init() {}
    
    // MARK: - 動態字體調整
    /// 當前字體大小調整
    var extraSize: CGFloat = FontManager.currentFontSize.extraSize
    
    // MARK: - 字體設定
    var workSansMedium12: Font {
        Font.custom("WorkSans-Medium", size: 12 + extraSize)
    }
    
    var workSansMedium16: Font {
        Font.custom("WorkSans-Medium", size: 16 + extraSize)
    }
    
    var workSansMedium14: Font {
        Font.custom("WorkSans-Medium", size: 14 + extraSize)
    }
    
    var workSansMedium20: Font {
        Font.custom("WorkSans-Medium", size: 20 + extraSize)
    }
    
    var workSansMedium22: Font {
        Font.custom("WorkSans-Medium", size: 22 + extraSize)
    }
    
    var workSansMedium24: Font {
        Font.custom("WorkSans-Medium", size: 24 + extraSize)
    }
    
    var workSansMedium28: Font {
        Font.custom("WorkSans-Medium", size: 28 + extraSize)
    }
    
    var workSansMedium32: Font {
        Font.custom("WorkSans-Medium", size: 32 + extraSize)
    }
    
    var workSans12: Font {
        Font.custom("WorkSans-Regular", size: 12 + extraSize)
    }
    
    var workSans14: Font {
        Font.custom("WorkSans-Regular", size: 14 + extraSize)
    }
    
    var workSans16: Font {
        Font.custom("WorkSans-Regular", size: 16 + extraSize)
    }
    
    var workSans28: Font {
        Font.custom("WorkSans-Regular", size: 28 + extraSize)
    }
    
    var workSans32: Font {
        Font.custom("WorkSans-Regular", size: 32 + extraSize)
    }
}
