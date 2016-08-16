//
//  ProfileSocialAccountCell.swift
//  Yep
//
//  Created by kevinzhow on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class ProfileSocialAccountCell: UICollectionViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconImageViewLeadingConstraint: NSLayoutConstraint!

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameLabelTrailingConstraint: NSLayoutConstraint!


    override func awakeFromNib() {
        super.awakeFromNib()

        iconImageViewLeadingConstraint.constant = YepConfig.Profile.leftEdgeInset
        nameLabelTrailingConstraint.constant = YepConfig.Profile.rightEdgeInset
    }

}
