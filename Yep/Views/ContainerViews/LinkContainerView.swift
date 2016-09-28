//
//  LinkContainerView.swift
//  Yep
//
//  Created by nixzhu on 15/12/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class LinkContainerView: UIView {

    var tapAction: (() -> Void)?

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_iconLink
        imageView.tintColor = UIColor.yepIconImageViewTintColor()
        return imageView
    }()

    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkGray
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    lazy var accessoryImageView: UIImageView = {
        let image = UIImage.yep_iconAccessoryMini
        let imageView = UIImageView(image: image)
        imageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
        return imageView
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        let tap = UITapGestureRecognizer(target: self, action: #selector(LinkContainerView.tap(_:)))
        addGestureRecognizer(tap)
    }

    fileprivate func makeUI() {

        addSubview(iconImageView)
        addSubview(textLabel)
        addSubview(accessoryImageView)

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        accessoryImageView.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: Any] = [
            "iconImageView": iconImageView,
            "textLabel": textLabel,
            "accessoryImageView": accessoryImageView,
        ]

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[iconImageView(20)]-10-[textLabel]-5-[accessoryImageView(8)]-10-|", options: [.alignAllCenterY], metrics: nil, views: views)

        let iconImageViewCenterY = NSLayoutConstraint(item: iconImageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activate(constraintsH)
        NSLayoutConstraint.activate([iconImageViewCenterY])
    }

    @objc fileprivate func tap(_ sender: UITapGestureRecognizer) {
        tapAction?()
    }
}

