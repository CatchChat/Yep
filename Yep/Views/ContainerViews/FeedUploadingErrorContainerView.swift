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
        label.textColor = UIColor.red
        return label
    }()

    lazy var retryButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("Retry", comment: ""), for: UIControlState())
        button.setTitleColor(UIColor.yepTintColor(), for: UIControlState())
        button.addTarget(self, action: #selector(FeedUploadingErrorContainerView.retryUploadingFeed(_:)), for: .touchUpInside)
        return button
    }()

    lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.setTitle(String.trans_titleDelete, for: UIControlState())
        button.setTitleColor(UIColor.red, for: UIControlState())
        button.addTarget(self, action: #selector(FeedUploadingErrorContainerView.deleteUploadingFeed(_:)), for: .touchUpInside)
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

            let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[leftContainerView]-15-[deleteButton]-15-|", options: [.alignAllCenterY], metrics: nil, views: views)
            let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[leftContainerView]|", options: [], metrics: nil, views: views)

            NSLayoutConstraint.activate(constraintsH)
            NSLayoutConstraint.activate(constraintsV)
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

            let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[iconImageView]-[errorMessageLabel]-[retryButton]-|", options: [.alignAllCenterY], metrics: nil, views: views)

            iconImageView.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
            iconImageView.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)

            let iconImageViewCenterY = NSLayoutConstraint(item: iconImageView, attribute: .centerY, relatedBy: .equal, toItem: leftContainerView, attribute: .centerY, multiplier: 1.0, constant: 0)

            NSLayoutConstraint.activate(constraintsH)
            NSLayoutConstraint.activate([iconImageViewCenterY])
        }
    }

    @objc fileprivate func retryUploadingFeed(_ sender: UIButton) {
        retryAction?()
    }

    @objc fileprivate func deleteUploadingFeed(_ sender: UIButton) {
        deleteAction?()
    }
}

