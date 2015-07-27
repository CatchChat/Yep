//
//  ProfileSectionHeaderReusableView.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

class ProfileSectionHeaderReusableView: UICollectionReusableView {

    var tapAction: (() -> Void)?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleLabelLeadingConstraint: NSLayoutConstraint!

    @IBOutlet weak var accessoryImageView: UIImageView!
    @IBOutlet weak var accessoryImageViewTrailingConstraint: NSLayoutConstraint!

    
    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabelLeadingConstraint.constant = YepConfig.Profile.leftEdgeInset
        accessoryImageViewTrailingConstraint.constant = YepConfig.Profile.leftEdgeInset

        accessoryImageView.tintColor = UIColor.darkGrayColor()

        let tap = UITapGestureRecognizer(target: self, action: "tap")
        addGestureRecognizer(tap)
    }

    func tap() {
        tapAction?()
    }
    
}
