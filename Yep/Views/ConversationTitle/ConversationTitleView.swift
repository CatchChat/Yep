//
//  ConversationTitleView.swift
//  Yep
//
//  Created by NIX on 15/4/30.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ConversationTitleView: UIView {

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .Center

        if #available(iOS 8.2, *) {
            label.font = UIFont.systemFontOfSize(15, weight: UIFontWeightBold)
        } else {
            label.font = UIFont(name: "HelveticaNeue-Bold", size: 15)!
        }

        return label
    }()

    lazy var stateInfoLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .Center
        if #available(iOS 8.2, *) {
            label.font = UIFont.systemFontOfSize(10, weight: UIFontWeightLight)
        } else {
            label.font = UIFont(name: "HelveticaNeue-Light", size: 10)!
        }
        label.textColor = UIColor.grayColor()
        return label
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    func makeUI() {
        addSubview(nameLabel)
        addSubview(stateInfoLabel)

        let helperView = UIView()

        addSubview(helperView)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        stateInfoLabel.translatesAutoresizingMaskIntoConstraints = false

        helperView.translatesAutoresizingMaskIntoConstraints = false

        let viewsDictionary = [
            "nameLabel": nameLabel,
            "stateInfoLabel": stateInfoLabel,
            "helperView": helperView,
        ]

        let helperViewCenterX = NSLayoutConstraint(item: helperView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0)
        let helperViewCenterY = NSLayoutConstraint(item: helperView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)
        let helperViewTop = NSLayoutConstraint(item: helperView, attribute: .Top, relatedBy: .Equal, toItem: nameLabel, attribute: .Top, multiplier: 1, constant: 0)
        let helperViewBottom = NSLayoutConstraint(item: helperView, attribute: .Bottom, relatedBy: .Equal, toItem: stateInfoLabel, attribute: .Bottom, multiplier: 1, constant: 0)

        NSLayoutConstraint.activateConstraints([helperViewCenterX, helperViewCenterY, helperViewTop, helperViewBottom])

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:[nameLabel(24)][stateInfoLabel(12)]", options: [.AlignAllCenterX, .AlignAllLeading, .AlignAllTrailing], metrics: nil, views: viewsDictionary)

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[nameLabel]|", options: [], metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints(constraintsH)
    }
}

