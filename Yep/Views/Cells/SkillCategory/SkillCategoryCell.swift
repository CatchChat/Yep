//
//  SkillCategoryCell.swift
//  Yep
//
//  Created by NIX on 15/4/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit


struct SkillCategoryCellConfig {
    static let skillCategoryButtonWidth: CGFloat = CGRectGetWidth(UIScreen.mainScreen().bounds) - 20 * 2
    static let skillCategoryButtonHeight: CGFloat = 60
}

class SkillCategoryCell: UICollectionViewCell {

    @IBOutlet weak var skillCategoryButton: SkillCategoryButton!
    @IBOutlet weak var skillCategoryButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var skillCategoryButtonHeightConstraint: NSLayoutConstraint!

    var categoryImage: UIImage? {
        willSet {
            if let image = newValue {
                skillCategoryButton.categoryImage = image
            }
        }
    }

    var categoryTitle: String? {
        willSet {
            if let title = newValue {
                skillCategoryButton.categoryTitle = title
            }
        }
    }

    var toggleSelectionStateAction: ((inSelectionState: Bool) -> Void)? {
        willSet {
            skillCategoryButton.toggleSelectionStateAction = newValue
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        skillCategoryButtonWidthConstraint.constant = SkillCategoryCellConfig.skillCategoryButtonWidth
        skillCategoryButtonHeightConstraint.constant = SkillCategoryCellConfig.skillCategoryButtonHeight

        skillCategoryButton.setBackgroundImage(UIImage(named: "button_skill_category_tech")!, forState: .Normal)
    }

}
