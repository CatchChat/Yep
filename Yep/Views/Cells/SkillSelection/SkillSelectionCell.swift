//
//  SkillSelectionCell.swift
//  Yep
//
//  Created by NIX on 15/4/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SkillSelectionCell: UICollectionViewCell {

    static let height: CGFloat = 35

    @IBOutlet weak var backgroundImageView: UIImageView!

    @IBOutlet weak var skillLabel: UILabel!

    var skillSelected: Bool = false {
        willSet {
            if newValue {
                backgroundImageView.image = UIImage(named: "skill_bubble_large_empty")
                skillLabel.textColor = UIColor.yepTintColor()

            } else {
                backgroundImageView.image = UIImage(named: "skill_bubble_large")
                skillLabel.textColor = UIColor.whiteColor()
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        skillLabel.font = UIFont.skillTextLargeFont()
    }
}
