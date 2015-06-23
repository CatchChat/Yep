//
//  AddSkillsReusableView.swift
//  Yep
//
//  Created by NIX on 15/4/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

enum SkillSetType: Int, Printable {
    case Master
    case Learning

    var description: String {
        switch self {
        case .Master:
            return NSLocalizedString("Master", comment: "")
        case .Learning:
            return NSLocalizedString("Learning", comment: "")
        }
    }
}

class AddSkillsReusableView: UICollectionReusableView {
    
    var skillSetType: SkillSetType = .Master {
        willSet {
            skillTypeLabel.text = "\(newValue)"
        }
    }

    @IBOutlet weak var skillTypeLabel: UILabel!
}
