//
//  SkillCategoryButton.swift
//  Yep
//
//  Created by NIX on 15/4/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

@IBDesignable
class SkillCategoryButton: UIButton {

    @IBInspectable var categoryImage: UIImage = UIImage() {
        willSet {
            categoryImageView.image = newValue
        }
    }

    @IBInspectable var catogoryTitle: String = "" {
        willSet {
            catogoryTitleLabel.text = newValue
        }
    }

    lazy var categoryImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .Center
        return imageView
        }()

    lazy var catogoryTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.whiteColor()
        label.font = UIFont(name: "HelveticaNeue-Thin", size: 24)!
        return label
        }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        addSubview(categoryImageView)
        addSubview(catogoryTitleLabel)

        categoryImageView.setTranslatesAutoresizingMaskIntoConstraints(false)
        catogoryTitleLabel.setTranslatesAutoresizingMaskIntoConstraints(false)

        let viewsDictionary = [
            "categoryImageView": categoryImageView,
            "catogoryTitleLabel": catogoryTitleLabel,
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[categoryImageView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-20-[categoryImageView(40)]-20-[catogoryTitleLabel]-40-|", options: .AlignAllCenterY | .AlignAllTop | .AlignAllBottom, metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints(constraintsH)
    }
}
