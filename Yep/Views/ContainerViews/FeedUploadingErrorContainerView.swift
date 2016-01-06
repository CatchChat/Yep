//
//  FeedUploadingErrorContainerView.swift
//  Yep
//
//  Created by nixzhu on 16/1/6.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class FeedUploadingErrorContainerView: UIView {

    lazy var leftContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1, green: 56/255.0, blue: 36/255.0, alpha: 0.1)
        view.layer.cornerRadius = 5
        return view
    }()

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "icon_topic_reddot"))
        return imageView
    }()

    lazy var errorMessageLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Upload failed.", comment: "")
        label.textColor = UIColor.redColor()
        return label
    }()

    lazy var retryButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("Retry", comment: ""), forState: .Normal)
        return button
    }()

    lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("Delete", comment: ""), forState: .Normal)
        return button
    }()

    func makeUI() {

        do {
            addSubview(leftContainerView)
            addSubview(deleteButton)

            leftContainerView.translatesAutoresizingMaskIntoConstraints = false
            deleteButton.translatesAutoresizingMaskIntoConstraints = false

            let views = [
                "leftContainerView": leftContainerView,
                "deleteButton": deleteButton,
            ]

            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[leftContainerView][deleteButton]|", options: [.AlignAllCenterY], metrics: nil, views: views)
            let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[leftContainerView]|", options: [], metrics: nil, views: views)

            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints(constraintsV)
        }

        do {
            leftContainerView.addSubview(iconImageView)
            leftContainerView.addSubview(errorMessageLabel)
            leftContainerView.addSubview(retryButton)

            iconImageView.translatesAutoresizingMaskIntoConstraints = false
            errorMessageLabel.translatesAutoresizingMaskIntoConstraints = false
            retryButton.translatesAutoresizingMaskIntoConstraints = false

            let views = [
                "iconImageView": iconImageView,
                "errorMessageLabel": errorMessageLabel,
                "retryButton": retryButton,
            ]

            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[iconImageView][errorMessageLabel][retryButton]|", options: [.AlignAllCenterY], metrics: nil, views: views)

            let iconImageViewCenterY = NSLayoutConstraint(item: iconImageView, attribute: .CenterY, relatedBy: .Equal, toItem: leftContainerView, attribute: .CenterY, multiplier: 1.0, constant: 0)

            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints([iconImageViewCenterY])
        }
    }
}

