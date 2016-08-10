//
//  FeedUploadingErrorContainerView.swift
//  Yep
//
//  Created by nixzhu on 16/1/6.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

final class FeedUploadingErrorContainerView: UIView {

    var retryAction: (() -> Void)?
    var deleteAction: (() -> Void)?

    lazy var leftContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1, green: 56/255.0, blue: 36/255.0, alpha: 0.1)
        view.layer.cornerRadius = 5
        return view
    }()

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_iconTopicReddot)
        return imageView
    }()

    lazy var errorMessageLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Upload failed!", comment: "")
        label.textColor = UIColor.redColor()
        return label
    }()

    lazy var retryButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("Retry", comment: ""), forState: .Normal)
        button.setTitleColor(UIColor.yepTintColor(), forState: .Normal)
        button.addTarget(self, action: #selector(FeedUploadingErrorContainerView.retryUploadingFeed(_:)), forControlEvents: .TouchUpInside)
        return button
    }()

    lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("Delete", comment: ""), forState: .Normal)
        button.setTitleColor(UIColor.redColor(), forState: .Normal)
        button.addTarget(self, action: #selector(FeedUploadingErrorContainerView.deleteUploadingFeed(_:)), forControlEvents: .TouchUpInside)
        return button
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    func makeUI() {

        //backgroundColor = UIColor.whiteColor()

        do {
            addSubview(leftContainerView)
            addSubview(deleteButton)

            leftContainerView.translatesAutoresizingMaskIntoConstraints = false
            deleteButton.translatesAutoresizingMaskIntoConstraints = false

            let views: [String: AnyObject] = [
                "leftContainerView": leftContainerView,
                "deleteButton": deleteButton,
            ]

            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[leftContainerView]-15-[deleteButton]-15-|", options: [.AlignAllCenterY], metrics: nil, views: views)
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

            let views: [String: AnyObject] = [
                "iconImageView": iconImageView,
                "errorMessageLabel": errorMessageLabel,
                "retryButton": retryButton,
            ]

            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-[iconImageView]-[errorMessageLabel]-[retryButton]-|", options: [.AlignAllCenterY], metrics: nil, views: views)

            iconImageView.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
            iconImageView.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)

            let iconImageViewCenterY = NSLayoutConstraint(item: iconImageView, attribute: .CenterY, relatedBy: .Equal, toItem: leftContainerView, attribute: .CenterY, multiplier: 1.0, constant: 0)

            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints([iconImageViewCenterY])
        }
    }

    @objc private func retryUploadingFeed(sender: UIButton) {
        retryAction?()
    }

    @objc private func deleteUploadingFeed(sender: UIButton) {
        deleteAction?()
    }
}

