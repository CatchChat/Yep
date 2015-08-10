//
//  EditSkillCell.swift
//  Yep
//
//  Created by nixzhu on 15/8/10.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

class EditSkillCell: UITableViewCell {

    var userSkill: UserSkill? {
        didSet {
            skillLabel.text = userSkill?.localName
        }
    }
    var removeSkillAction: (UserSkill -> Void)?

    @IBOutlet weak var skillLabel: UILabel!
    @IBOutlet weak var skillLabelLeadingConstraint: NSLayoutConstraint!

    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var removeButtonTrailingConstraint: NSLayoutConstraint!


    override func awakeFromNib() {
        super.awakeFromNib()

        skillLabelLeadingConstraint.constant = Ruler.match(.iPhoneWidths(15, 20, 25))
        removeButtonTrailingConstraint.constant = Ruler.match(.iPhoneWidths(15, 20, 25))

        removeButton.addTarget(self, action: "tryRemoveSkill", forControlEvents: .TouchUpInside)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: Actions

    func tryRemoveSkill() {
        if let userSkill = userSkill {
            removeSkillAction?(userSkill)
        }
    }
    
}
