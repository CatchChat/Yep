//
//  FeedLocationContainerView.swift
//  Yep
//
//  Created by nixzhu on 15/12/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedLocationContainerView: UIView {

    lazy var mapImageView: UIImageView = {
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

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightGrayColor()
        label.font = UIFont.systemFontOfSize(12)
        return label
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    private func makeUI() {

        addSubview(mapImageView)
        addSubview(horizontalLineView)
        addSubview(nameLabel)

        mapImageView.translatesAutoresizingMaskIntoConstraints = false
        horizontalLineView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "mapImageView": mapImageView,
            "horizontalLineView": horizontalLineView,
            "nameLabel": nameLabel,
        ]

        let constraintsH1 = NSLayoutConstraint.constraintsWithVisualFormat("H:|[mapImageView]|", options: [], metrics: nil, views: views)
        let constraintsH2 = NSLayoutConstraint.constraintsWithVisualFormat("H:|[horizontalLineView]|", options: [], metrics: nil, views: views)
        let constraintsH3 = NSLayoutConstraint.constraintsWithVisualFormat("H:|-10-[nameLabel]-10-|", options: [], metrics: nil, views: views)

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[mapImageView][nameLabel(30)]|", options: [], metrics: nil, views: views)

        let horizontalLineViewH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[horizontalLineView]|", options: [], metrics: nil, views: views)
        let horizontalLineViewV = NSLayoutConstraint.constraintsWithVisualFormat("V:[horizontalLineView(1)]", options: [], metrics: nil, views: views)
        let horizontalLineViewTop = NSLayoutConstraint(item: horizontalLineView, attribute: .Top, relatedBy: .Equal, toItem: nameLabel, attribute: .Top, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activateConstraints(constraintsH1)
        NSLayoutConstraint.activateConstraints(constraintsH2)
        NSLayoutConstraint.activateConstraints(constraintsH3)
        NSLayoutConstraint.activateConstraints(constraintsV)

        NSLayoutConstraint.activateConstraints(horizontalLineViewH)
        NSLayoutConstraint.activateConstraints(horizontalLineViewV)
        NSLayoutConstraint.activateConstraints([horizontalLineViewTop])
    }
}

