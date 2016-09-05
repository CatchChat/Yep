//
//  SwipeUpPromptView.swift
//  Yep
//
//  Created by NIX on 16/9/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

final class SwipeUpPromptView: UIView {

    private lazy var arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_swipeUp
        return imageView
    }()

    private lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.redColor()
        label.font = UIFont.systemFontOfSize(15)
        return label
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    private func makeUI() {

        do {
            addSubview(promptLabel)
            promptLabel.translatesAutoresizingMaskIntoConstraints = false

            promptLabel.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor, constant: 20).active = true
            promptLabel.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor).active = true
        }

        do {
            addSubview(arrowImageView)
            arrowImageView.translatesAutoresizingMaskIntoConstraints = false

            arrowImageView.bottomAnchor.constraintEqualToAnchor(promptLabel.bottomAnchor, constant: 10)
            arrowImageView.centerXAnchor.constraintEqualToAnchor(promptLabel.centerXAnchor)
        }
    }
}

