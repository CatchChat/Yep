//
//  SkillCategoryCell.swift
//  Yep
//
//  Created by NIX on 15/4/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class SkillCategoryCell: UICollectionViewCell {

    static let skillCategoryButtonWidth: CGFloat = 280//CGRectGetWidth(UIScreen.mainScreen().bounds) - 20 * 2
    static let skillCategoryButtonHeight: CGFloat = 60

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

        skillCategoryButtonWidthConstraint.constant = SkillCategoryCell.skillCategoryButtonWidth
        skillCategoryButtonHeightConstraint.constant = SkillCategoryCell.skillCategoryButtonHeight
    }
}

