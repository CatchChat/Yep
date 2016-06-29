//
//  GeniusInterviewActionView.swift
//  Yep
//
//  Created by NIX on 16/6/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class GeniusInterviewActionView: UIView {

    lazy var toolbar = UIToolbar()

    lazy var avatarImageView: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        view.backgroundColor = UIColor.redColor()
        return view
    }()

    lazy var sayHiButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFontOfSize(14)
        button.setTitle(NSLocalizedString("Say Hi", comment: ""), forState: .Normal)
        button.backgroundColor = UIColor.yepTintColor()
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(GeniusInterviewActionView.sayHi(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        return button
    }()

    @objc private func sayHi(sender: UIButton) {
        println("Say Hi")
    }

    private func makeUI() {

        do {
            toolbar.translatesAutoresizingMaskIntoConstraints = false
            addSubview(toolbar)

            let leading = toolbar.leadingAnchor.constraintEqualToAnchor(leadingAnchor)
            let trailing = toolbar.trailingAnchor.constraintEqualToAnchor(trailingAnchor)
            let top = toolbar.topAnchor.constraintEqualToAnchor(topAnchor)
            let bottom = toolbar.bottomAnchor.constraintEqualToAnchor(bottomAnchor)
            NSLayoutConstraint.activateConstraints([leading, trailing, top, bottom])
        }

        do {
            let avatarItem = UIBarButtonItem(customView: avatarImageView)
            let sayHiItem = UIBarButtonItem(customView: sayHiButton)
            let shareItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: #selector(GeniusInterviewActionView.share(_:)))

            toolbar.setItems([avatarItem, sayHiItem, shareItem], animated: false)
        }
    }

    @objc private func share(sender: UIBarButtonItem) {
        println("share")
    }
}

