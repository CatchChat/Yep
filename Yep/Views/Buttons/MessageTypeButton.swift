//
//  MessageTypeButton.swift
//  Yep
//
//  Created by NIX on 15/4/21.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

@IBDesignable
final class MessageTypeButton: TouchZoomButton {

    @IBInspectable
    var image: UIImage = UIImage() {
        willSet {
            typeImageView.image = newValue
        }
    }

    @IBInspectable
    var title: String = "" {
        willSet {
            typeTitleLabel.text = newValue
        }
    }

    var tapAction: (() -> Void)?

    lazy var typeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .Center
        return imageView
    }()

    lazy var typeTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkGrayColor()
        label.font = UIFont.systemFontOfSize(12, weight: UIFontWeightLight)
        label.textAlignment = .Center
        return label
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        self.addTarget(self, action: #selector(MessageTypeButton.tryTapAction), forControlEvents: .TouchUpInside)
    }

    func makeUI() {

        addSubview(typeImageView)
        addSubview(typeTitleLabel)

        typeImageView.translatesAutoresizingMaskIntoConstraints = false
        typeTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let viewsDictionary: [String: AnyObject] = [
            "typeImageView": typeImageView,
            "typeTitleLabel": typeTitleLabel,
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[typeImageView]-(>=0)-[typeTitleLabel(20)]|", options: [.AlignAllCenterX, .AlignAllLeading, .AlignAllTrailing] , metrics: nil, views: viewsDictionary)

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[typeImageView]|", options: [], metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints(constraintsH)
    }

    func tryTapAction() {
        if let action = tapAction {
            action()
        }
    }
}

