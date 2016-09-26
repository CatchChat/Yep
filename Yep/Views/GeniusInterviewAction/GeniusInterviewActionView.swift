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

        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(GeniusInterviewActionView.tapAvatar(_:)))
        view.addGestureRecognizer(tap)

        return view
    }()

    lazy var sayHiButton: UIButton = {

        let width: CGFloat = Ruler.iPhoneHorizontal(150, 185, 185).value
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: width, height: 30))
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitle(NSLocalizedString("Say Hi", comment: ""), for: UIControlState())
        button.backgroundColor = UIColor.yepTintColor()
        button.setTitleColor(UIColor.white, for: UIControlState())
        button.layer.cornerRadius = 5

        button.addTarget(self, action: #selector(GeniusInterviewActionView.sayHi(_:)), for: UIControlEvents.touchUpInside)

        return button
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    fileprivate func makeUI() {

        do {
            toolbar.translatesAutoresizingMaskIntoConstraints = false
            addSubview(toolbar)

            let leading = toolbar.leadingAnchor.constraint(equalTo: leadingAnchor)
            let trailing = toolbar.trailingAnchor.constraint(equalTo: trailingAnchor)
            let top = toolbar.topAnchor.constraint(equalTo: topAnchor)
            let bottom = toolbar.bottomAnchor.constraint(equalTo: bottomAnchor)
            NSLayoutConstraint.activate([leading, trailing, top, bottom])
        }

        do {
            let avatarItem = UIBarButtonItem(customView: avatarImageView)

            let gap1Item = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

            let sayHiItem = UIBarButtonItem(customView: sayHiButton)

            let gap2Item = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

            let shareItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(GeniusInterviewActionView.share(_:)))

            toolbar.setItems([avatarItem, gap1Item, sayHiItem, gap2Item, shareItem], animated: false)
        }
    }

    @objc fileprivate func tapAvatar(_ sender: UITapGestureRecognizer) {

        tapAvatarAction?()
    }

    @objc fileprivate func sayHi(_ sender: UIButton) {

        sayHiAction?()
    }

    @objc fileprivate func share(_ sender: UIBarButtonItem) {

        shareAction?()
    }
}

