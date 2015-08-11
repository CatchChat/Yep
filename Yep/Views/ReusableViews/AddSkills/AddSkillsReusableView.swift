//
//  AddSkillsReusableView.swift
//  Yep
//
//  Created by NIX on 15/4/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class AddSkillsReusableView: UICollectionReusableView {
    
    var skillSet: SkillSet = .Master {
        willSet {
            skillTypeLabel.text = "\(newValue.name)"
        }
    }

    @IBOutlet weak var skillTypeLabel: UILabel!
}
