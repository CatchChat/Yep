//
//  SkillCategoryCell.swift
//  Yep
//
//  Created by NIX on 15/4/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SkillCategoryCell: UICollectionViewCell {

    @IBOutlet weak var skillCategoryButton: SkillCategoryButton!

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

    override func awakeFromNib() {
        super.awakeFromNib()

        skillCategoryButton.setBackgroundImage(UIImage(named: "button_skill_category_tech")!, forState: .Normal)
    }

}
