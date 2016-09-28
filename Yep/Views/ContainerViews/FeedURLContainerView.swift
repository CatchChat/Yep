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

    fileprivate var needMakeUI: Bool = true
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
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.lightGray
        return label
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.black
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = UIColor.lightGray
        label.numberOfLines = 0
        return label
    }()

    lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        let tap = UITapGestureRecognizer(target: self, action: #selector(FeedURLContainerView.tap(_:)))
        addGestureRecognizer(tap)
    }

    fileprivate func makeUI() {

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

        let views: [String: Any] = [
            "backgroundImageView": backgroundImageView,
            "siteNameLabel": siteNameLabel,
            "titleLabel": titleLabel,
            "bottomContainerView": bottomContainerView,
            "descriptionLabel": descriptionLabel,
            "thumbnailImageView": thumbnailImageView,
        ]

        do {
            let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[backgroundImageView]|", options: [], metrics: nil, views: views)

            let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[backgroundImageView]|", options: [], metrics: nil, views: views)

            NSLayoutConstraint.activate(constraintsH)
            NSLayoutConstraint.activate(constraintsV)
        }

        do {
            let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[siteNameLabel]-|", options: [], metrics: nil, views: views)

            let metrics: [String: CGFloat] = [
                "top": compressionMode ? 4 : 8,
                "gap": compressionMode ? 4 : 8,
                "bottom": compressionMode ? 4 : 8,
            ]
            let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(top)-[siteNameLabel(15)]-(gap)-[titleLabel(15)]-(gap)-[bottomContainerView]-(bottom)-|", options: [.alignAllLeading, .alignAllTrailing], metrics: metrics, views: views)

            NSLayoutConstraint.activate(constraintsH)
            NSLayoutConstraint.activate(constraintsV)
        }

        do {
            let metrics: [String: CGFloat] = [
                "imageSize": compressionMode ? 35 : 40,
            ]

            let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[descriptionLabel]-[thumbnailImageView(imageSize)]|", options: [.alignAllTop], metrics: metrics, views: views)

            let constraintsV1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|[descriptionLabel]-(>=0)-|", options: [.alignAllLeading, .alignAllTrailing], metrics: nil, views: views)

            let constraintsV2 = NSLayoutConstraint.constraints(withVisualFormat: "V:|[thumbnailImageView(imageSize)]", options: [.alignAllLeading, .alignAllTrailing], metrics: metrics, views: views)

            NSLayoutConstraint.activate(constraintsH)
            NSLayoutConstraint.activate(constraintsV1)
            NSLayoutConstraint.activate(constraintsV2)
        }
    }

    @objc fileprivate func tap(_ sender: UITapGestureRecognizer) {
        tapAction?()
    }

    func configureWithOpenGraphInfoType(_ openGraphInfo: OpenGraphInfoType) {

        siteNameLabel.text = openGraphInfo.siteName
        titleLabel.text = openGraphInfo.title
        descriptionLabel.text = openGraphInfo.infoDescription

        if let url = URL(string: openGraphInfo.thumbnailImageURLString) {
            thumbnailImageView.kf.setImage(with: url, placeholder: nil)
        } else {
            thumbnailImageView.image = nil
            thumbnailImageView.backgroundColor = UIColor.lightGray
        }
    }
}

