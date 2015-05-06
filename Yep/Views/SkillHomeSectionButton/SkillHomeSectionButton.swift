//
//  SkillHomeSectionButton.swift
//  Yep
//
//  Created by kevinzhow on 15/5/6.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

func createSkillHomeButtonWithText(text: String, width: CGFloat, height: CGFloat) -> UIButton {
    
    var button = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    button.frame = CGRectMake(0, 0, width, height)
    button.setTitle(text, forState: UIControlState.Normal)
    button.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
    button.backgroundColor = UIColor.whiteColor()
    button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    button.titleLabel?.font = UIFont.systemFontOfSize(16.0)
    return button
    
}
