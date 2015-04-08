//
//  SkillCell.swift
//  Yep
//
//  Created by NIX on 15/4/8.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SkillCell: UICollectionViewCell {

    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var skillLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        skillLabel.font = UIFont.skillTextFont()
    }

}
