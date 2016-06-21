//
//  OverlayActionView.swift
//  Yep
//
//  Created by NIX on 16/6/21.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class OverlayActionView: UIView {

    var shareAction: (() -> Void)?

    private lazy var backgroundImageView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    private lazy var shareButton: UIButton = {
        let button = UIButton()
        button.setTitle("Share", forState: .Normal)
        button.addTarget(self, action: #selector(OverlayActionView.share(_:)), forControlEvents: .TouchUpInside)
        return button
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    private func makeUI() {

        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false

        addSubview(backgroundImageView)
        addSubview(shareButton)

        let views = [
            "backgroundImageView": backgroundImageView,
            "shareButton": shareButton,
        ]

        do {
            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[backgroundImageView]|", options: [], metrics: nil, views: views)
            let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("H:|[backgroundImageView]|", options: [], metrics: nil, views: views)

            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints(constraintsV)
        }

        do {
            let trailing = shareButton.trailingAnchor.constraintEqualToAnchor(self.trailingAnchor, constant: -20)
            let bottom = shareButton.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor, constant: -20)

            NSLayoutConstraint.activateConstraints([trailing, bottom])
        }
    }

    @objc private func share(sender: UIButton) {
        shareAction?()
    }
}

