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

    override func awakeFromNib() {
        super.awakeFromNib()

        skillLabel.font = UIFont.skillTextLargeFont()
    }
}
