//
//  SkillCategoryButton.swift
//  Yep
//
//  Created by NIX on 15/4/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

@IBDesignable
final class SkillCategoryButton: UIButton {

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

    var toggleSelectionStateAction: ((_ inSelectionState: Bool) -> Void)?

    lazy var categoryImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.tintColor = UIColor.white
        return imageView
    }()

    lazy var categoryTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 24, weight: UIFontWeightThin)
        return label
    }()

    lazy var arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.image = UIImage.yep_iconSkillCategoryArrow
        imageView.tintColor = UIColor.white
        imageView.tintAdjustmentMode = .normal
        return imageView
        }()


    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        self.addTarget(self, action: #selector(SkillCategoryButton.toggleSelectionState), for: .touchUpInside)
    }

    func makeUI() {

        addSubview(categoryImageView)
        addSubview(categoryTitleLabel)
        addSubview(arrowImageView)

        categoryImageView.translatesAutoresizingMaskIntoConstraints = false
        categoryTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: Any] = [
            "categoryImageView": categoryImageView,
            "categoryTitleLabel": categoryTitleLabel,
            "arrowImageView": arrowImageView,
        ]

        let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[categoryImageView]|", options: [], metrics: nil, views: views)

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[categoryImageView(40)]-20-[categoryTitleLabel][arrowImageView(20)]-20-|", options: [.alignAllCenterY, .alignAllTop, .alignAllBottom], metrics: nil, views: views)

        NSLayoutConstraint.activate(constraintsV)
        NSLayoutConstraint.activate(constraintsH)
    }

    func toggleSelectionState() {
        inSelectionState = !inSelectionState

        if let action = toggleSelectionStateAction {
            action(inSelectionState)
        }
    }

    func rotateArrowFromAngle(_ fromAngle: CGFloat, toAngle: CGFloat) {

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.repeatCount = 0
        rotationAnimation.fromValue = fromAngle
        rotationAnimation.toValue = toAngle
        rotationAnimation.duration = 0.25
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        rotationAnimation.isRemovedOnCompletion = false
        rotationAnimation.fillMode = kCAFillModeBoth

        arrowImageView.layer.add(rotationAnimation, forKey: "rotationAnimation")
    }
}

