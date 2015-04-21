//
//  MessageTypeButton.swift
//  Yep
//
//  Created by NIX on 15/4/21.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

@IBDesignable
class MessageTypeButton: UIButton {

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

    lazy var typeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .Center
        return imageView
        }()

    lazy var typeTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkGrayColor()
        label.font = UIFont(name: "HelveticaNeue-Thin", size: 15)!
        label.textAlignment = .Center
        return label
        }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        self.addTarget(self, action: "toggleSelectionState", forControlEvents: .TouchUpInside)
    }

    func makeUI() {

        backgroundColor = UIColor.magentaColor()

        addSubview(typeImageView)
        addSubview(typeTitleLabel)

        typeImageView.setTranslatesAutoresizingMaskIntoConstraints(false)
        typeTitleLabel.setTranslatesAutoresizingMaskIntoConstraints(false)

        let viewsDictionary = [
            "typeImageView": typeImageView,
            "typeTitleLabel": typeTitleLabel,
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[typeImageView(60)]-(>=0)-[typeTitleLabel(20)]|", options: .AlignAllCenterX | .AlignAllLeading | .AlignAllTrailing , metrics: nil, views: viewsDictionary)

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[typeImageView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints(constraintsH)
    }

}
