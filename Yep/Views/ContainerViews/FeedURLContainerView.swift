//
//  FeedURLContainerView.swift
//  Yep
//
//  Created by nixzhu on 16/1/14.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class FeedURLContainerView: UIView {

    var tapAction: (() -> Void)?
    
    lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "url_container_background")
        return imageView
    }()

    lazy var siteNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(12)
        label.textColor = UIColor.lightGrayColor()
        //label.text = "iTunes"
        //label.backgroundColor = UIColor.greenColor()
        return label
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(12)
        label.textColor = UIColor.blackColor()
        //label.text = "NIX on iTunes"
        //label.backgroundColor = UIColor.greenColor()
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(10)
        label.textColor = UIColor.lightGrayColor()
        label.numberOfLines = 0
        //label.text = "Preview and download songs and albums by NIX, including \"Love you love\", \"Hate you hate\", \"Go home\", etc."
        //label.backgroundColor = UIColor.greenColor()
        return label
    }()

    lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        //imageView.backgroundColor = UIColor.blueColor()
        return imageView
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
        
        let tap = UITapGestureRecognizer(target: self, action: "tap:")
        addGestureRecognizer(tap)
    }

    private func makeUI() {

        addSubview(backgroundImageView)
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(siteNameLabel)
        addSubview(titleLabel)
        siteNameLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let bottomContainerView = UIView()
        addSubview(bottomContainerView)
        bottomContainerView.translatesAutoresizingMaskIntoConstraints = false

        bottomContainerView.addSubview(descriptionLabel)
        bottomContainerView.addSubview(thumbnailImageView)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "backgroundImageView": backgroundImageView,
            "siteNameLabel": siteNameLabel,
            "titleLabel": titleLabel,
            "bottomContainerView": bottomContainerView,
            "descriptionLabel": descriptionLabel,
            "thumbnailImageView": thumbnailImageView,
        ]

        do {
            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[backgroundImageView]|", options: [], metrics: nil, views: views)

            let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[backgroundImageView]|", options: [], metrics: nil, views: views)

            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints(constraintsV)
        }

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

    @objc private func tap(sender: UITapGestureRecognizer) {
        tapAction?()
    }
}

