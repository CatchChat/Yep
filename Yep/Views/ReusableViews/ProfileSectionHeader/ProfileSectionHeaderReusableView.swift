//
//  ProfileSectionHeaderReusableView.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ProfileSectionHeaderReusableView: UICollectionReusableView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleLabelLeadingConstraint: NSLayoutConstraint!

    @IBOutlet weak var accessoryImageView: UIImageView!
    @IBOutlet weak var accessoryImageViewTrailingConstraint: NSLayoutConstraint!

    var tapAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        accessoryImageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()

        titleLabelLeadingConstraint.constant = YepConfig.Profile.leftEdgeInset
        accessoryImageViewTrailingConstraint.constant = YepConfig.Profile.leftEdgeInset

        let tap = UITapGestureRecognizer(target: self, action: "tap")
        addGestureRecognizer(tap)
    }

    func tap() {
        tapAction?()
    }
}
    
