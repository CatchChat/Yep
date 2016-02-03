//
//  SkillHomeSectionButton.swift
//  Yep
//
//  Created by kevinzhow on 15/5/6.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import pop

let skillHeomSectionButtonLineHeight: CGFloat = 2

class SkillHomeSectionButton: UIButton {
    
    let highLight = CALayer()
    
    func setActive(animated animated: Bool) {

        let setting: () -> Void = {
            self.highLight.frame =  CGRectMake(0, self.frame.size.height - skillHeomSectionButtonLineHeight, self.frame.size.width, skillHeomSectionButtonLineHeight)
            self.highLight.backgroundColor = UIColor.yepTintColor().CGColor
        }

        if animated {
            UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {

                setting()

            }, completion: nil)

        } else {
            setting()
        }
    }
    
    func setInActive(animated animated: Bool) {

        let setting: () -> Void = {
            self.highLight.frame =  CGRectMake(0, self.frame.size.height - skillHeomSectionButtonLineHeight, self.frame.size.width, skillHeomSectionButtonLineHeight)
            self.highLight.backgroundColor = UIColor.yepDisabledColor().CGColor
        }

        if animated {
            UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {

                setting()

            }, completion: nil)

        } else {
            setting()
        }
    }
    
    func updateHightLightBounce() {
        highLight.frame =  CGRectMake(0, self.frame.size.height - skillHeomSectionButtonLineHeight, self.frame.size.width, skillHeomSectionButtonLineHeight)
    }
}


func createSkillHomeButtonWithText(text: String, width: CGFloat, height: CGFloat) -> SkillHomeSectionButton {

    let button = SkillHomeSectionButton()
    
    button.frame = CGRectMake(0, 0, width, height)
    button.setTitle(text, forState: UIControlState.Normal)
    button.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
    button.backgroundColor = UIColor.whiteColor()
    button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    button.titleLabel?.font = UIFont.skillHomeButtonFont()
    button.layer.addSublayer(button.highLight)
    button.highLight.backgroundColor = UIColor.yepTintColor().CGColor
    
    return button
}

