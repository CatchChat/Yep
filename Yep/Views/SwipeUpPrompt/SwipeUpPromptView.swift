//
//  SwipeUpPromptView.swift
//  Yep
//
//  Created by NIX on 16/9/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

final class SwipeUpPromptView: UIView {

    var text: String? {
        didSet {
            promptLabel.text = text
        }
    }

    private lazy var arrowImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_swipeUp)
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

            promptLabel.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor, constant: -20).active = true
            promptLabel.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor).active = true
        }

        do {
            addSubview(arrowImageView)
            arrowImageView.translatesAutoresizingMaskIntoConstraints = false

            promptLabel.topAnchor.constraintEqualToAnchor(arrowImageView.bottomAnchor, constant: 10).active = true
            arrowImageView.centerXAnchor.constraintEqualToAnchor(promptLabel.centerXAnchor).active = true
        }
    }
}

