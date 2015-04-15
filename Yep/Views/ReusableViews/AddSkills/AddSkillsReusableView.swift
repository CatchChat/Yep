//
//  AddSkillsReusableView.swift
//  Yep
//
//  Created by NIX on 15/4/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class AddSkillsReusableView: UICollectionReusableView {

    @IBOutlet weak var skillTypeLabel: UILabel!

    @IBOutlet weak var addSkillsButton: UIButton!


    override func awakeFromNib() {
        super.awakeFromNib()

        addSkillsButton.tintColor = UIColor.yepTintColor()
    }
    
}
