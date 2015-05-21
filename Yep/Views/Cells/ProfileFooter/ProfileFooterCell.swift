//
//  ProfileFooterCell.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ProfileFooterCell: UICollectionViewCell {

    @IBOutlet weak var instroductionLabelLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var instroductionLabelRightConstraint: NSLayoutConstraint!

    @IBOutlet weak var introductionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        instroductionLabelLeftConstraint.constant = YepConfig.Profile.leftEdgeInset
        instroductionLabelRightConstraint.constant = YepConfig.Profile.rightEdgeInset

        introductionLabel.font = YepConfig.Profile.introductionLabelFont
        introductionLabel.textColor = UIColor.yepGrayColor()
    }

}
