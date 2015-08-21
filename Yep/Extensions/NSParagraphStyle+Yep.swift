//
//  NSParagraphStyle+Yep.swift
//  Yep
//
//  Created by nixzhu on 15/8/21.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

extension NSParagraphStyle {

    class func chatTextParagraphStyle() -> NSParagraphStyle {

        let style = NSMutableParagraphStyle()

        style.minimumLineHeight = 17.3
        style.lineSpacing = 0
        style.paragraphSpacing = 0
        style.paragraphSpacingBefore = 0
        style.lineBreakMode = .ByWordWrapping

        return style
    }
}
