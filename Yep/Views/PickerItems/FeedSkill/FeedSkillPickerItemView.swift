//
//  FeedSkillPickerItemView.swift
//  Yep
//
//  Created by nixzhu on 15/10/22.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedSkillPickerItemView: UIView {

    lazy var bubbleImageView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "skill_bubble")!)
        return view
    }()

    lazy var skillLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(15)
        label.textColor = UIColor.whiteColor()
        return label
    }()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        makeUI()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        makeUI()
    }

    private func makeUI() {

        addSubview(bubbleImageView)
        bubbleImageView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(skillLabel)
        skillLabel.translatesAutoresizingMaskIntoConstraints = false

        let skillLabelCenterY = NSLayoutConstraint(item: skillLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)

        let skillLabelTrailing = NSLayoutConstraint(item: skillLabel, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: -50)

        NSLayoutConstraint.activateConstraints([skillLabelCenterY, skillLabelTrailing])

        let bubbleImageViewCenterY = NSLayoutConstraint(item: bubbleImageView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)

        let bubbleImageViewLeading = NSLayoutConstraint(item: bubbleImageView, attribute: .Leading, relatedBy: .Equal, toItem: skillLabel, attribute: .Leading, multiplier: 1, constant: -10)

        let bubbleImageViewTrailing = NSLayoutConstraint(item: bubbleImageView, attribute: .Trailing, relatedBy: .Equal, toItem: skillLabel, attribute: .Trailing, multiplier: 1, constant: 10)

        NSLayoutConstraint.activateConstraints([bubbleImageViewCenterY, bubbleImageViewLeading, bubbleImageViewTrailing])
    }

    func configureWithSkill(skill: Skill) {
        skillLabel.text = skill.localName
        if skill.name == generalSkill.name {
            skillLabel.textColor = UIColor.lightGrayColor()
            bubbleImageView.image = nil
        } else {
            skillLabel.textColor = UIColor.whiteColor()
            bubbleImageView.image = UIImage(named: "skill_bubble")
        }
    }
}

