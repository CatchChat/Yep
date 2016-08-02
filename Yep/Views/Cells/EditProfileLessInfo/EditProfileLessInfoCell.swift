//
//  EditProfileLessInfoCell.swift
//  Yep
//
//  Created by NIX on 15/4/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class EditProfileLessInfoCell: UITableViewCell {

    @IBOutlet weak var annotationLabel: UILabel!

    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var infoLabelTrailingConstraint: NSLayoutConstraint!

    struct ConstraintConstant {
        static let minInfoLabelTrailing: CGFloat = 8
        static let normalInfoLabelTrailing: CGFloat = 8 + 30 + 8
    }

    @IBOutlet weak var badgeImageView: UIImageView!

    @IBOutlet weak var accessoryImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        accessoryImageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
    }
}
    
