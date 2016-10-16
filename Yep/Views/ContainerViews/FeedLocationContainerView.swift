//
//  FeedLocationContainerView.swift
//  Yep
//
//  Created by nixzhu on 15/12/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class FeedLocationContainerView: UIView {

    var tapAction: (() -> Void)?

    lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_feedContainerBackground
        return imageView
    }()

    lazy var mapImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    lazy var pinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_iconPinShadow
        return imageView
    }()

    lazy var horizontalLineView: HorizontalLineView = {
        let view = HorizontalLineView()
        view.atBottom = false
        view.backgroundColor = UIColor.white
        return view
    }()

    var needCompressNameLabel: Bool = false
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightGray
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        let tap = UITapGestureRecognizer(target: self, action: #selector(FeedLocationContainerView.tap(_:)))
        addGestureRecognizer(tap)
    }

    fileprivate func makeUI() {

        addSubview(backgroundImageView)
        addSubview(mapImageView)
        addSubview(pinImageView)
        addSubview(horizontalLineView)
        addSubview(nameLabel)

        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        mapImageView.translatesAutoresizingMaskIntoConstraints = false
        pinImageView.translatesAutoresizingMaskIntoConstraints = false
        horizontalLineView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: Any] = [
            "backgroundImageView": backgroundImageView,
            "mapImageView": mapImageView,
            "horizontalLineView": horizontalLineView,
            "nameLabel": nameLabel,
        ]

        let backgroundH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[backgroundImageView]|", options: [], metrics: nil, views: views)
        let backgroundV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[backgroundImageView]|", options: [], metrics: nil, views: views)
        NSLayoutConstraint.activate(backgroundH)
        NSLayoutConstraint.activate(backgroundV)

        let constraintsH1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|[mapImageView]|", options: [], metrics: nil, views: views)
        let constraintsH2 = NSLayoutConstraint.constraints(withVisualFormat: "H:|[horizontalLineView]|", options: [], metrics: nil, views: views)
        let constraintsH3 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[nameLabel]-10-|", options: [], metrics: nil, views: views)

        let constraintsV: [NSLayoutConstraint]
        if needCompressNameLabel {
            constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[mapImageView][nameLabel(20)]|", options: [], metrics: nil, views: views)
        } else {
            constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[mapImageView][nameLabel(30)]|", options: [], metrics: nil, views: views)
        }

        let horizontalLineViewH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[horizontalLineView]|", options: [], metrics: nil, views: views)
        let horizontalLineViewV = NSLayoutConstraint.constraints(withVisualFormat: "V:[horizontalLineView(1)]", options: [], metrics: nil, views: views)
        let horizontalLineViewTop = NSLayoutConstraint(item: horizontalLineView, attribute: .top, relatedBy: .equal, toItem: nameLabel, attribute: .top, multiplier: 1.0, constant: 0)

        let pinImageViewCenterX = NSLayoutConstraint(item: pinImageView, attribute: .centerX, relatedBy: .equal, toItem: mapImageView, attribute: .centerX, multiplier: 1.0, constant: 0)
        let pinImageViewCenterY = NSLayoutConstraint(item: pinImageView, attribute: .centerY, relatedBy: .equal, toItem: mapImageView, attribute: .centerY, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activate(constraintsH1)
        NSLayoutConstraint.activate(constraintsH2)
        NSLayoutConstraint.activate(constraintsH3)
        NSLayoutConstraint.activate(constraintsV)

        NSLayoutConstraint.activate(horizontalLineViewH)
        NSLayoutConstraint.activate(horizontalLineViewV)
        NSLayoutConstraint.activate([horizontalLineViewTop])

        NSLayoutConstraint.activate([pinImageViewCenterX, pinImageViewCenterY])
    }

    @objc fileprivate func tap(_ sender: UITapGestureRecognizer) {
        tapAction?()
    }
}

