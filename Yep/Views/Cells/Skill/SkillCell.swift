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
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
                self?.backgroundImageView.tintColor = newValue ? UIColor.black.withAlphaComponent(0.25) : UIColor.yepTintColor()
            }, completion: nil)
        }
    }

    var skill: SkillCellSkill? {
        willSet {
            skillLabel.text = newValue?.localName
        }
    }

    var tapAction: ((_ skill: SkillCellSkill) -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        tapped = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        delay(0.15) { [weak self] in

            if let strongSelf = self {

                strongSelf.tapped = false

                if let skill = strongSelf.skill {
                    strongSelf.tapAction?(skill)
                }
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        tapped = false
    }
}
