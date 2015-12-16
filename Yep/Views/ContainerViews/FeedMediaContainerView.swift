//
//  FeedMediaContainerView.swift
//  Yep
//
//  Created by nixzhu on 15/12/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedMediaContainerView: UIView {

    lazy var socialWorkImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    lazy var horizontalLineView: HorizontalLineView = {
        let view = HorizontalLineView()
        view.atBottom = false
        return view
    }()

    lazy var linkContainerView: UIView = {
        let view = UIView()
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

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[socialWorkImageView][horizontalLineView(1)][linkContainerView(44)]|", options: [.AlignAllLeading, .AlignAllTrailing], metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(constraintsV)
    }
}

