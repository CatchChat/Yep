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

    @IBInspectable var categoryTitle: String = "" {
        willSet {
            categoryTitleLabel.text = newValue
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

    var toggleSelectionStateAction: ((inSelectionState: Bool) -> Void)?

    lazy var categoryImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .Center
        imageView.tintColor = UIColor.whiteColor()
        return imageView
    }()

    lazy var categoryTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.whiteColor()
        if #available(iOS 8.2, *) {
            label.font = UIFont.systemFontOfSize(24, weight: UIFontWeightThin)
        } else {
            label.font = UIFont(name: "HelveticaNeue-Thin", size: 24)!
        }
        return label
    }()

    lazy var arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .Center
        imageView.image = UIImage(named: "icon_skill_category_arrow")
        imageView.tintColor = UIColor.whiteColor()
        imageView.tintAdjustmentMode = .Normal
        return imageView
        }()


    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        self.addTarget(self, action: "toggleSelectionState", forControlEvents: .TouchUpInside)
    }

    func makeUI() {

        addSubview(categoryImageView)
        addSubview(categoryTitleLabel)
        addSubview(arrowImageView)

        categoryImageView.translatesAutoresizingMaskIntoConstraints = false
        categoryTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false

        let viewsDictionary = [
            "categoryImageView": categoryImageView,
            "categoryTitleLabel": categoryTitleLabel,
            "arrowImageView": arrowImageView,
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[categoryImageView]|", options: [], metrics: nil, views: viewsDictionary)

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-20-[categoryImageView(40)]-20-[categoryTitleLabel][arrowImageView(20)]-20-|", options: [.AlignAllCenterY, .AlignAllTop, .AlignAllBottom], metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints(constraintsH)
    }

    func toggleSelectionState() {
        inSelectionState = !inSelectionState

        if let action = toggleSelectionStateAction {
            action(inSelectionState: inSelectionState)
        }
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

