//
//  FeedURLContainerView.swift
//  Yep
//
//  Created by nixzhu on 16/1/14.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class FeedURLContainerView: UIView {

    var tapAction: (() -> Void)?

    private var needMakeUI: Bool = true
    var directionLeading = true { // set before compressionMode
        didSet {
            if directionLeading {
                backgroundImageView.image = UIImage.yep_urlContainerLeftBackground
            } else {
                backgroundImageView.image = UIImage.yep_urlContainerRightBackground
            }
        }
    }
    var compressionMode: Bool = false {
        didSet {
            if needMakeUI {
                makeUI()

                needMakeUI = false
            }
        }
    }
    
    lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_urlContainerLeftBackground
        return imageView
    }()

    lazy var siteNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(12)
        label.textColor = UIColor.lightGrayColor()
        return label
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(12)
        label.textColor = UIColor.blackColor()
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(10)
        label.textColor = UIColor.lightGrayColor()
        label.numberOfLines = 0
        return label
    }()

    lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        let tap = UITapGestureRecognizer(target: self, action: #selector(FeedURLContainerView.tap(_:)))
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

        let views: [String: AnyObject] = [
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

            let metrics: [String: AnyObject] = [
                "top": compressionMode ? 4 : 8,
                "gap": compressionMode ? 4 : 8,
                "bottom": compressionMode ? 4 : 8,
            ]
            let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(top)-[siteNameLabel(15)]-(gap)-[titleLabel(15)]-(gap)-[bottomContainerView]-(bottom)-|", options: [.AlignAllLeading, .AlignAllTrailing], metrics: metrics, views: views)

            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints(constraintsV)
        }

        do {
            let metrics: [String: AnyObject] = [
                "imageSize": compressionMode ? 35 : 40,
            ]

            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[descriptionLabel]-[thumbnailImageView(imageSize)]|", options: [.AlignAllTop], metrics: metrics, views: views)

            let constraintsV1 = NSLayoutConstraint.constraintsWithVisualFormat("V:|[descriptionLabel]-(>=0)-|", options: [.AlignAllLeading, .AlignAllTrailing], metrics: nil, views: views)

            let constraintsV2 = NSLayoutConstraint.constraintsWithVisualFormat("V:|[thumbnailImageView(imageSize)]", options: [.AlignAllLeading, .AlignAllTrailing], metrics: metrics, views: views)

            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints(constraintsV1)
            NSLayoutConstraint.activateConstraints(constraintsV2)
        }
    }

    @objc private func tap(sender: UITapGestureRecognizer) {
        tapAction?()
    }

    func configureWithOpenGraphInfoType(openGraphInfo: OpenGraphInfoType) {

        siteNameLabel.text = openGraphInfo.siteName
        titleLabel.text = openGraphInfo.title
        descriptionLabel.text = openGraphInfo.infoDescription

        if let thumbnailImageURL = NSURL(string: openGraphInfo.thumbnailImageURLString) {
            thumbnailImageView.kf_setImageWithURL(thumbnailImageURL, placeholderImage: nil)
        } else {
            thumbnailImageView.image = nil
            thumbnailImageView.backgroundColor = UIColor.lightGrayColor()
        }
    }
}

