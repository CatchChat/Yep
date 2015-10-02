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
        //return UIFont(name: "Helvetica-Light", size: 14)!
        return UIFont.systemFontOfSize(14)
    }

    class func skillTextLargeFont() -> UIFont {
        //return UIFont(name: "Helvetica-Light", size: 20)!
        return UIFont.systemFontOfSize(20)
    }
    
    class func skillHomeTextLargeFont() -> UIFont {
        //return UIFont(name: "Helvetica-Light", size: 18)!
        return UIFont.systemFontOfSize(18)
    }
    
    class func skillHomeButtonFont() -> UIFont {
        //return UIFont(name: "Helvetica-Light", size: 16)!
        return UIFont.systemFontOfSize(16)
    }
    
    class func barButtonFont() -> UIFont {
        //return UIFont(name: "Helvetica-Light", size: 14)!
        return UIFont.systemFontOfSize(14)
    }

    class func navigationBarTitleFont() -> UIFont {
        //return UIFont(name: "Helvetica-Bold", size: 15)!
        return UIFont.boldSystemFontOfSize(15)
    }

    class func feedMessageFont() -> UIFont {
        return UIFont.systemFontOfSize(17)
    }
}
