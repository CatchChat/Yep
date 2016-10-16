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

    fileprivate lazy var arrowImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_swipeUp)
        return imageView
    }()

    fileprivate lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.red
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    fileprivate func makeUI() {

        do {
            addSubview(promptLabel)
            promptLabel.translatesAutoresizingMaskIntoConstraints = false

            promptLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20).isActive = true
            promptLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        }

        do {
            addSubview(arrowImageView)
            arrowImageView.translatesAutoresizingMaskIntoConstraints = false

            promptLabel.topAnchor.constraint(equalTo: arrowImageView.bottomAnchor, constant: 10).isActive = true
            arrowImageView.centerXAnchor.constraint(equalTo: promptLabel.centerXAnchor).isActive = true
        }
    }
}

