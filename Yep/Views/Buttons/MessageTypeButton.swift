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
        imageView.contentMode = .center
        return imageView
    }()

    lazy var typeTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkGray
        label.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightLight)
        label.textAlignment = .center
        return label
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        self.addTarget(self, action: #selector(MessageTypeButton.tryTapAction), for: .touchUpInside)
    }

    func makeUI() {

        addSubview(typeImageView)
        addSubview(typeTitleLabel)

        typeImageView.translatesAutoresizingMaskIntoConstraints = false
        typeTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: Any] = [
            "typeImageView": typeImageView,
            "typeTitleLabel": typeTitleLabel,
        ]

        let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[typeImageView]-(>=0)-[typeTitleLabel(20)]|", options: [.alignAllCenterX, .alignAllLeading, .alignAllTrailing], metrics: nil, views: views)

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[typeImageView]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activate(constraintsV)
        NSLayoutConstraint.activate(constraintsH)
    }

    func tryTapAction() {
        if let action = tapAction {
            action()
        }
    }
}

