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

    var inSelectionState: Bool = false {
        willSet {
            if inSelectionState != newValue {
                if newValue {
                    let toAngle = CGFloat(M_PI * 0.5)
                    rotateArrowFromAngle(0, toAngle: toAngle)

                } else {
                    let fromAngle = CGFloat(M_PI * 0.5)
                    rotateArrowFromAngle(fromAngle, toAngle: 0)
                }
            }
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

    lazy var arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .Center
        imageView.image = UIImage(named: "icon_skill_category_arrow")
        return imageView
        }()


    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        self.addTarget(self, action: "toggleSelectionState", forControlEvents: .TouchUpInside)
    }

    func makeUI() {

        addSubview(categoryImageView)
        addSubview(catogoryTitleLabel)
        addSubview(arrowImageView)

        categoryImageView.setTranslatesAutoresizingMaskIntoConstraints(false)
        catogoryTitleLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        arrowImageView.setTranslatesAutoresizingMaskIntoConstraints(false)

        let viewsDictionary = [
            "categoryImageView": categoryImageView,
            "catogoryTitleLabel": catogoryTitleLabel,
            "arrowImageView": arrowImageView,
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[categoryImageView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-20-[categoryImageView(40)]-20-[catogoryTitleLabel][arrowImageView(20)]-20-|", options: .AlignAllCenterY | .AlignAllTop | .AlignAllBottom, metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints(constraintsH)
    }

    func toggleSelectionState() {
        inSelectionState = !inSelectionState
    }

    func rotateArrowFromAngle(fromAngle: CGFloat, toAngle: CGFloat) {

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.repeatCount = 0
        rotationAnimation.fromValue = fromAngle
        rotationAnimation.toValue = toAngle
        rotationAnimation.duration = 0.25
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        rotationAnimation.removedOnCompletion = false
        rotationAnimation.fillMode = kCAFillModeBoth

        arrowImageView.layer.addAnimation(rotationAnimation, forKey: "rotationAnimation")
    }
}
