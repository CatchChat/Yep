//
//  SkillCell.swift
//  Yep
//
//  Created by NIX on 15/4/8.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class SkillCell: UICollectionViewCell {

    static let height: CGFloat = 24

    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var skillLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        skillLabel.font = UIFont.skillTextFont()
    }

    var tapped: Bool = false {
        willSet {
            UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
                self?.backgroundImageView.tintColor = newValue ? UIColor.blackColor().colorWithAlphaComponent(0.25) : UIColor.yepTintColor()
            }, completion: nil)
        }
    }

    var skill: SkillCellSkill? {
        willSet {
            skillLabel.text = newValue?.localName
        }
    }

    var tapAction: ((skill: SkillCellSkill) -> Void)?

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        tapped = true
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {

        delay(0.15) { [weak self] in

            if let strongSelf = self {

                strongSelf.tapped = false

                if let skill = strongSelf.skill {
                    strongSelf.tapAction?(skill: skill)
                }
            }
        }
    }

    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        tapped = false
    }
}
