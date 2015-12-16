//
//  FeedMediaContainerView.swift
//  Yep
//
//  Created by nixzhu on 15/12/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

class FeedMediaContainerView: UIView {

    lazy var socialWorkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        return imageView
    }()

    lazy var horizontalLineView: HorizontalLineView = {
        let view = HorizontalLineView()
        view.atBottom = false
        view.backgroundColor = UIColor.whiteColor()
        return view
    }()

    lazy var linkContainerView: LinkContainerView = {
        let view = LinkContainerView()
        return view
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    private func makeUI() {

        addSubview(socialWorkImageView)
        addSubview(horizontalLineView)
        addSubview(linkContainerView)

        socialWorkImageView.translatesAutoresizingMaskIntoConstraints = false
        horizontalLineView.translatesAutoresizingMaskIntoConstraints = false
        linkContainerView.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "socialWorkImageView": socialWorkImageView,
            "horizontalLineView": horizontalLineView,
            "linkContainerView": linkContainerView,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[socialWorkImageView]|", options: [], metrics: nil, views: views)

        let linkContainerViewHeight: CGFloat = Ruler.iPhoneHorizontal(44, 50, 50).value

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[socialWorkImageView][linkContainerView(linkContainerViewHeight)]|", options: [.AlignAllLeading, .AlignAllTrailing], metrics: ["linkContainerViewHeight": linkContainerViewHeight], views: views)

        let horizontalLineViewH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[horizontalLineView]|", options: [], metrics: nil, views: views)
        let horizontalLineViewV = NSLayoutConstraint.constraintsWithVisualFormat("V:[horizontalLineView(1)]", options: [], metrics: nil, views: views)
        let horizontalLineViewTop = NSLayoutConstraint(item: horizontalLineView, attribute: .Top, relatedBy: .Equal, toItem: linkContainerView, attribute: .Top, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(constraintsV)

        NSLayoutConstraint.activateConstraints(horizontalLineViewH)
        NSLayoutConstraint.activateConstraints(horizontalLineViewV)
        NSLayoutConstraint.activateConstraints([horizontalLineViewTop])
    }
}

