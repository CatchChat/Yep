//
//  GeniusInterviewActionView.swift
//  Yep
//
//  Created by NIX on 16/6/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

class GeniusInterviewActionView: UIView {

    var tapAvatarAction: (() -> Void)?
    var sayHiAction: (() -> Void)?
    var shareAction: (() -> Void)?

    lazy var toolbar = UIToolbar()

    lazy var avatarImageView: UIImageView = {

        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))

        view.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(GeniusInterviewActionView.tapAvatar(_:)))
        view.addGestureRecognizer(tap)

        return view
    }()

    lazy var sayHiButton: UIButton = {

        let width: CGFloat = Ruler.iPhoneHorizontal(150, 185, 185).value
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: width, height: 30))
        button.titleLabel?.font = UIFont.systemFontOfSize(14)
        button.setTitle(NSLocalizedString("Say Hi", comment: ""), forState: .Normal)
        button.backgroundColor = UIColor.yepTintColor()
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.layer.cornerRadius = 5

        button.addTarget(self, action: #selector(GeniusInterviewActionView.sayHi(_:)), forControlEvents: UIControlEvents.TouchUpInside)

        return button
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
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

            let gap1Item = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)

            let sayHiItem = UIBarButtonItem(customView: sayHiButton)

            let gap2Item = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)

            let shareItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: #selector(GeniusInterviewActionView.share(_:)))

            toolbar.setItems([avatarItem, gap1Item, sayHiItem, gap2Item, shareItem], animated: false)
        }
    }

    @objc private func tapAvatar(sender: UITapGestureRecognizer) {

        tapAvatarAction?()
    }

    @objc private func sayHi(sender: UIButton) {

        sayHiAction?()
    }

    @objc private func share(sender: UIBarButtonItem) {

        shareAction?()
    }
}

