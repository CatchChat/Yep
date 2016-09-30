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

final class SkillHomeSectionButton: UIButton {
    
    let highLight = CALayer()
    
    func setActive(animated: Bool) {

        let setting: () -> Void = {
            self.highLight.frame =  CGRect(x: 0, y: self.frame.size.height - skillHeomSectionButtonLineHeight, width: self.frame.size.width, height: skillHeomSectionButtonLineHeight)
            self.highLight.backgroundColor = UIColor.yepTintColor().cgColor
        }

        if animated {
            UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {

                setting()

            }, completion: nil)

        } else {
            setting()
        }
    }
    
    func setInActive(animated: Bool) {

        let setting: () -> Void = {
            self.highLight.frame =  CGRect(x: 0, y: self.frame.size.height - skillHeomSectionButtonLineHeight, width: self.frame.size.width, height: skillHeomSectionButtonLineHeight)
            self.highLight.backgroundColor = UIColor.yepDisabledColor().cgColor
        }

        if animated {
            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {

                setting()

            }, completion: nil)

        } else {
            setting()
        }
    }
    
    func updateHightLightBounce() {
        highLight.frame =  CGRect(x: 0, y: self.frame.size.height - skillHeomSectionButtonLineHeight, width: self.frame.size.width, height: skillHeomSectionButtonLineHeight)
    }
}


func createSkillHomeButtonWithText(_ text: String, width: CGFloat, height: CGFloat) -> SkillHomeSectionButton {

    let button = SkillHomeSectionButton()
    
    button.frame = CGRect(x: 0, y: 0, width: width, height: height)
    button.setTitle(text, for: .normal)
    button.setTitleColor(UIColor.black, for: .normal)
    button.backgroundColor = UIColor.white
    button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    button.titleLabel?.font = UIFont.skillHomeButtonFont()
    button.layer.addSublayer(button.highLight)
    button.highLight.backgroundColor = UIColor.yepTintColor().cgColor
    
    return button
}

