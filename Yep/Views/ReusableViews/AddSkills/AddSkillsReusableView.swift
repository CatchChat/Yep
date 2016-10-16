//
//  AddSkillsReusableView.swift
//  Yep
//
//  Created by NIX on 15/4/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Ruler

final class AddSkillsReusableView: UICollectionReusableView {
    
    var skillSet: SkillSet = .master {
        willSet {
            skillTypeLabel.text = "\(newValue.name)"
        }
    }

    @IBOutlet weak var skillTypeLabel: UILabel!
    @IBOutlet weak var skillTypeLabelLeadingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        skillTypeLabelLeadingConstraint.constant = registerPickSkillsLayoutLeftEdgeInset
    }
}

