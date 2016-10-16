//
//  FeedSkillPickerItemView.swift
//  Yep
//
//  Created by nixzhu on 15/10/22.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class FeedSkillPickerItemView: UIView {

    lazy var bubbleImageView: UIImageView = {
        let view = UIImageView(image: UIImage.yep_skillBubble)
        return view
    }()

    lazy var skillLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor.white
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

    fileprivate func makeUI() {

        addSubview(bubbleImageView)
        bubbleImageView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(skillLabel)
        skillLabel.translatesAutoresizingMaskIntoConstraints = false

        let skillLabelCenterY = NSLayoutConstraint(item: skillLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)

        let skillLabelTrailing = NSLayoutConstraint(item: skillLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -50)

        NSLayoutConstraint.activate([skillLabelCenterY, skillLabelTrailing])

        let bubbleImageViewCenterY = NSLayoutConstraint(item: bubbleImageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)

        let bubbleImageViewLeading = NSLayoutConstraint(item: bubbleImageView, attribute: .leading, relatedBy: .equal, toItem: skillLabel, attribute: .leading, multiplier: 1, constant: -10)

        let bubbleImageViewTrailing = NSLayoutConstraint(item: bubbleImageView, attribute: .trailing, relatedBy: .equal, toItem: skillLabel, attribute: .trailing, multiplier: 1, constant: 10)

        NSLayoutConstraint.activate([bubbleImageViewCenterY, bubbleImageViewLeading, bubbleImageViewTrailing])
    }

    func configureWithSkill(_ skill: Skill) {

        skillLabel.text = skill.localName

        if skill == NewFeedViewController.generalSkill {
            skillLabel.textColor = UIColor.lightGray
            bubbleImageView.image = nil
        } else {
            skillLabel.textColor = UIColor.white
            bubbleImageView.image = UIImage.yep_skillBubble
        }
    }
}

