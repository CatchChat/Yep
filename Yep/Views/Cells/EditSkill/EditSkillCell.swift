//
//  EditSkillCell.swift
//  Yep
//
//  Created by nixzhu on 15/8/10.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Ruler

final class EditSkillCell: UITableViewCell {

    var userSkill: UserSkill? {
        didSet {
            skillLabel.text = userSkill?.localName
        }
    }
    var removeSkillAction: ((EditSkillCell, UserSkill) -> Void)?

    @IBOutlet weak var skillLabel: UILabel!
    @IBOutlet weak var skillLabelLeadingConstraint: NSLayoutConstraint!

    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var removeButtonTrailingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        skillLabelLeadingConstraint.constant = Ruler.iPhoneHorizontal(15, 20, 25).value
        removeButtonTrailingConstraint.constant = Ruler.iPhoneHorizontal(15, 20, 25).value

        removeButton.addTarget(self, action: #selector(EditSkillCell.tryRemoveSkill), forControlEvents: .TouchUpInside)
    }

    // MARK: Actions

    func tryRemoveSkill() {
        if let userSkill = userSkill {
            removeSkillAction?(self, userSkill)
        }
    }
}

