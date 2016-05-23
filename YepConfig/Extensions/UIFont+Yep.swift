//
//  UIFont+Yep.swift
//  Yep
//
//  Created by NIX on 16/5/23.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

public extension UIFont {

    public class func chatTextFont() -> UIFont {
        return UIFont.systemFontOfSize(16)
    }

    public class func feedMessageFont() -> UIFont {
        return UIFont.systemFontOfSize(17)
    }

    public class func feedSkillFont() -> UIFont {
        return UIFont.systemFontOfSize(12)
    }

    public class func feedBottomLabelsFont() -> UIFont {
        return UIFont.systemFontOfSize(14)
    }

    public class func feedVoiceTimeLengthFont() -> UIFont {
        return UIFont.systemFontOfSize(12)
    }
}

