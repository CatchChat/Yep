//
//  ConversationTitleView.swift
//  Yep
//
//  Created by NIX on 15/4/30.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class ConversationTitleView: UIView {

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15, weight: UIFontWeightBold)
        return label
    }()

    lazy var stateInfoLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10, weight: UIFontWeightLight)
        label.textColor = UIColor.gray
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

        let views: [String: Any] = [
            "nameLabel": nameLabel,
            "stateInfoLabel": stateInfoLabel,
            "helperView": helperView,
        ]

        let helperViewCenterX = NSLayoutConstraint(item: helperView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let helperViewCenterY = NSLayoutConstraint(item: helperView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        let helperViewTop = NSLayoutConstraint(item: helperView, attribute: .top, relatedBy: .equal, toItem: nameLabel, attribute: .top, multiplier: 1, constant: 0)
        let helperViewBottom = NSLayoutConstraint(item: helperView, attribute: .bottom, relatedBy: .equal, toItem: stateInfoLabel, attribute: .bottom, multiplier: 1, constant: 0)

        NSLayoutConstraint.activate([helperViewCenterX, helperViewCenterY, helperViewTop, helperViewBottom])

        let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:[nameLabel(24)][stateInfoLabel(12)]", options: [.alignAllCenterX, .alignAllLeading, .alignAllTrailing], metrics: nil, views: views)

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[nameLabel]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activate(constraintsV)
        NSLayoutConstraint.activate(constraintsH)
    }
}

