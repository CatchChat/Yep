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
        return UIFont.systemFont(ofSize: 16)
    }

    class func feedMessageFont() -> UIFont {
        return UIFont.systemFont(ofSize: 17)
    }

    class func feedSkillFont() -> UIFont {
        return UIFont.systemFont(ofSize: 12)
    }

    class func feedBottomLabelsFont() -> UIFont {
        return UIFont.systemFont(ofSize: 14)
    }

    class func feedVoiceTimeLengthFont() -> UIFont {
        return UIFont.systemFont(ofSize: 12)
    }
}

extension UIFont {

    class func skillDiscoverTextFont() -> UIFont {
        return UIFont.systemFont(ofSize: 11)
    }
    
    class func skillTextFont() -> UIFont {
        return UIFont.systemFont(ofSize: 14)
    }

    class func skillTextLargeFont() -> UIFont {
        return UIFont.systemFont(ofSize: 20)
    }
    
    class func skillHomeTextLargeFont() -> UIFont {
        return UIFont.systemFont(ofSize: 18)
    }
    
    class func skillHomeButtonFont() -> UIFont {
        return UIFont.systemFont(ofSize: 16)
    }
    
    class func barButtonFont() -> UIFont {
        return UIFont.systemFont(ofSize: 14)
    }

    class func navigationBarTitleFont() -> UIFont { // make sure it's the same as system use
        return UIFont.boldSystemFont(ofSize: 17)
    }
}

