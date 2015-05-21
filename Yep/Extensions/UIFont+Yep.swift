//
//  UIFont+Yep.swift
//  Yep
//
//  Created by NIX on 15/3/30.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

extension UIFont {
    class func chatTextFont() -> UIFont {
        return UIFont.systemFontOfSize(16)
    }

    class func skillTextFont() -> UIFont {
        return UIFont(name: "Helvetica-Light", size: 14)!
    }

    class func skillTextLargeFont() -> UIFont {
        return UIFont(name: "Helvetica-Light", size: 20)!
    }
    
    class func skillHomeTextLargeFont() -> UIFont {
        return UIFont(name: "Helvetica-Light", size: 18)!
    }
    
    class func skillHomeButtonFont() -> UIFont {
        return UIFont(name: "Helvetica-Light", size: 16)!
    }

    class func navigationBarTitleFont() -> UIFont {
        return UIFont(name: "HelveticaNeue-CondensedBlack", size: 20)!
    }
}
