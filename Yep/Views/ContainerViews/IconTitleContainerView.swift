//
//  IconTitleContainerView.swift
//  Yep
//
//  Created by NIX on 16/4/19.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

final class IconTitleContainerView: UIView {

    var tapAction: (() -> Void)?
    
    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_iconLink
        imageView.tintColor = UIColor.yep_mangmorGrayColor()
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightGrayColor()
        label.font = UIFont.systemFontOfSize(15)
        return label
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        let tap = UITapGestureRecognizer(target: self, action: #selector(IconTitleContainerView.tap(_:)))
        addGestureRecognizer(tap)
    }

    private func makeUI() {

        addSubview(iconImageView)
        addSubview(titleLabel)

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: AnyObject] = [
            "iconImageView": iconImageView,
            "titleLabel": titleLabel,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[iconImageView(20)]-5-[titleLabel]|", options: [.AlignAllCenterY], metrics: nil, views: views)
        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:[iconImageView(20)]", options: [], metrics: nil, views: views)

        let centerY = NSLayoutConstraint(item: iconImageView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints([centerY])
    }

    @objc private func tap(sender: UITapGestureRecognizer) {
        tapAction?()
    }
}
