//
//  MeetGeniusShowView.swift
//  Yep
//
//  Created by NIX on 16/6/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class MeetGeniusShowView: UIView {

    lazy var backgroundImageView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    lazy var showButton: UIButton = {
        let button = UIButton()
        button.setTitle("SHOW", forState: .Normal)
        return button
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Hello World!"
        return label
    }()

    func makeUI() {

        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundImageView)

        let views = [
            "backgroundImageView": backgroundImageView,
            "showButton": showButton,
            "titleLabel": titleLabel,
        ]

        do {
            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[backgroundImageView]|", options: [], metrics: nil, views: views)
            let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[backgroundImageView]|", options: [], metrics: nil, views: views)
            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints(constraintsV)
        }

        do {
            showButton.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.translatesAutoresizingMaskIntoConstraints = false

            let stackView = UIStackView()
            stackView.axis = .Vertical
            stackView.addArrangedSubview(showButton)
            stackView.addArrangedSubview(titleLabel)

            stackView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(stackView)

            let centerX = stackView.centerXAnchor.constraintEqualToAnchor(centerXAnchor)
            let centerY = stackView.centerYAnchor.constraintEqualToAnchor(centerYAnchor)
            NSLayoutConstraint.activateConstraints([centerX, centerY])
        }
    }
}

