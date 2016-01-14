//
//  FeedURLContainerView.swift
//  Yep
//
//  Created by nixzhu on 16/1/14.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class FeedURLContainerView: UIView {

    lazy var siteNameLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    private func makeUI() {

        backgroundColor = UIColor.lightGrayColor()

        addSubview(siteNameLabel)
        addSubview(titleLabel)

        let bottomContainerView = UIView()
        addSubview(bottomContainerView)
        bottomContainerView.translatesAutoresizingMaskIntoConstraints = false

        bottomContainerView.addSubview(descriptionLabel)
        bottomContainerView.addSubview(thumbnailImageView)

        siteNameLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "siteNameLabel": siteNameLabel,
            "titleLabel": titleLabel,
            "bottomContainerView": bottomContainerView,
            "descriptionLabel": descriptionLabel,
            "thumbnailImageView": thumbnailImageView,
        ]

        do {
            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-[siteNameLabel]-|", options: [], metrics: nil, views: views)

            let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-[siteNameLabel]-[titleLabel]-[bottomContainerView]-|", options: [.AlignAllLeading, .AlignAllTrailing], metrics: nil, views: views)

            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints(constraintsV)
        }

        do {
            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[descriptionLabel]-[thumbnailImageView(40)]|", options: [.AlignAllTop], metrics: nil, views: views)

            let constraintsV1 = NSLayoutConstraint.constraintsWithVisualFormat("V:|[descriptionLabel]-(>=0)-|", options: [.AlignAllLeading, .AlignAllTrailing], metrics: nil, views: views)

            let constraintsV2 = NSLayoutConstraint.constraintsWithVisualFormat("V:|[thumbnailImageView(40)]", options: [.AlignAllLeading, .AlignAllTrailing], metrics: nil, views: views)

            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints(constraintsV1)
            NSLayoutConstraint.activateConstraints(constraintsV2)
        }
    }
}

