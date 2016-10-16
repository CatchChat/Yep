//
//  SkillSelectionCell.swift
//  Yep
//
//  Created by NIX on 15/4/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class SkillSelectionCell: UICollectionViewCell {

    static let height: CGFloat = 35

    @IBOutlet weak var backgroundImageView: UIImageView!

    @IBOutlet weak var skillLabel: UILabel!

    enum Selection {
        case unavailable
        case off
        case on
    }

    var skillSelection: Selection = .off {
        willSet {
            switch newValue {

            case .unavailable:
                backgroundImageView.image = UIImage.yep_skillBubbleLargeEmpty
                skillLabel.textColor = UIColor.yepTintColor()
                contentView.alpha = 0.2

            case .off:
                backgroundImageView.image = UIImage.yep_skillBubbleLargeEmpty
                skillLabel.textColor = UIColor.yepTintColor()
                contentView.alpha = 1

            case .on:
                backgroundImageView.image = UIImage.yep_skillBubbleLarge
                skillLabel.textColor = UIColor.white
                contentView.alpha = 1
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        skillLabel.font = UIFont.skillTextLargeFont()
    }
}
