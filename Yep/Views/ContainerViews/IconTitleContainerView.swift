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
        label.textColor = UIColor.lightGray
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        let tap = UITapGestureRecognizer(target: self, action: #selector(IconTitleContainerView.tap(_:)))
        addGestureRecognizer(tap)
    }

    fileprivate func makeUI() {

        addSubview(iconImageView)
        addSubview(titleLabel)

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: Any] = [
            "iconImageView": iconImageView,
            "titleLabel": titleLabel,
        ]

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[iconImageView(20)]-5-[titleLabel]|", options: [.alignAllCenterY], metrics: nil, views: views)
        let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:[iconImageView(20)]", options: [], metrics: nil, views: views)

        let centerY = NSLayoutConstraint(item: iconImageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activate(constraintsH)
        NSLayoutConstraint.activate(constraintsV)
        NSLayoutConstraint.activate([centerY])
    }

    @objc fileprivate func tap(_ sender: UITapGestureRecognizer) {
        tapAction?()
    }
}
