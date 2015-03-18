//
//  ProfileFooterCell.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

let profileIntroductionLabelLeadingSpaceToContainer: CGFloat = 20
let profileIntroductionLabelTrailingSpaceToContainer: CGFloat = 20

class ProfileFooterCell: UICollectionViewCell {

    @IBOutlet weak var instroductionLabelLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var instroductionLabelRightConstraint: NSLayoutConstraint!


    @IBOutlet weak var introductionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        instroductionLabelLeftConstraint.constant = profileIntroductionLabelLeadingSpaceToContainer
        instroductionLabelRightConstraint.constant = profileIntroductionLabelTrailingSpaceToContainer
    }

}
