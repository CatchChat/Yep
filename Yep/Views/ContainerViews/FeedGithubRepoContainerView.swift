//
//  FeedGithubRepoContainerView.swift
//  Yep
//
//  Created by nixzhu on 15/12/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class FeedGithubRepoContainerView: UIView {

    var tapAction: (() -> Void)?

    lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_feedContainerBackground
        return imageView
    }()

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_iconRepo
        imageView.tintColor = UIColor.yepIconImageViewTintColor()
        return imageView
    }()

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightGray
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 2
        return label
    }()

    var needShowAccessoryImageView: Bool = true
    lazy var accessoryImageView: UIImageView = {
        let image = UIImage.yep_iconAccessoryMini
        let imageView = UIImageView(image: image)
        imageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
        return imageView
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        let tap = UITapGestureRecognizer(target: self, action: #selector(FeedGithubRepoContainerView.tap(_:)))
        addGestureRecognizer(tap)
    }

    fileprivate func makeUI() {

        backgroundColor = UIColor.white
        tintAdjustmentMode = .normal

        addSubview(backgroundImageView)
        addSubview(iconImageView)
        addSubview(nameLabel)
        addSubview(descriptionLabel)
        addSubview(accessoryImageView)

        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        accessoryImageView.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: AnyObject] = [
            "backgroundImageView": backgroundImageView,
            "iconImageView": iconImageView,
            "nameLabel": nameLabel,
            "descriptionLabel": descriptionLabel,
            "accessoryImageView": accessoryImageView,
        ]

        let backgroundH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[backgroundImageView]|", options: [], metrics: nil, views: views)
        let backgroundV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[backgroundImageView]|", options: [], metrics: nil, views: views)
        NSLayoutConstraint.activate(backgroundH)
        NSLayoutConstraint.activate(backgroundV)

        let constraintsH: [NSLayoutConstraint]
        if needShowAccessoryImageView {
            constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[iconImageView(16)]-10-[nameLabel]-5-[accessoryImageView(8)]-10-|", options: [], metrics: nil, views: views)
        } else {
            accessoryImageView.isHidden = true
            constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[iconImageView(16)]-10-[nameLabel]-10-|", options: [], metrics: nil, views: views)
        }

        iconImageView.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        accessoryImageView.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)

        iconImageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        accessoryImageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)

        let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:[nameLabel]-3-[descriptionLabel]", options: [.alignAllLeading, .alignAllTrailing], metrics: nil, views: views)

        let iconImageViewCenterY = NSLayoutConstraint(item: iconImageView, attribute: .centerY, relatedBy: .equal, toItem: nameLabel, attribute: .centerY, multiplier: 1.0, constant: 0)
        let accessoryImageViewCenterY = NSLayoutConstraint(item: accessoryImageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)

        let helperView = UIView()
        addSubview(helperView)
        helperView.translatesAutoresizingMaskIntoConstraints = false

        let helperViewCenterY = NSLayoutConstraint(item: helperView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)
        let helperViewTop = NSLayoutConstraint(item: helperView, attribute: .top, relatedBy: .equal, toItem: nameLabel, attribute: .top, multiplier: 1.0, constant: 0)
        let helperViewBottom = NSLayoutConstraint(item: helperView, attribute: .bottom, relatedBy: .equal, toItem: descriptionLabel, attribute: .bottom, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activate(constraintsH)
        NSLayoutConstraint.activate(constraintsV)
        NSLayoutConstraint.activate([iconImageViewCenterY, accessoryImageViewCenterY])
        NSLayoutConstraint.activate([helperViewCenterY, helperViewTop, helperViewBottom])
    }

    @objc fileprivate func tap(_ sender: UITapGestureRecognizer) {
        tapAction?()
    }
}

