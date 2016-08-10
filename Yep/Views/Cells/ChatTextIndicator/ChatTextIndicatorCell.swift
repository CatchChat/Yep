//
//  ChatTextIndicatorCell.swift
//  Yep
//
//  Created by nixzhu on 16/1/25.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class ChatTextIndicatorCell: UICollectionViewCell {

    lazy var bubbleImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_skillBubble)
        imageView.tintColor = UIColor(white: 0.95, alpha: 1.0)
        imageView.tintAdjustmentMode = .Normal
        return imageView
    }()

    lazy var recallLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(12)
        label.textColor  = UIColor(white: 0.75, alpha: 1.0)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(bubbleImageView)
        contentView.addSubview(recallLabel)
        bubbleImageView.translatesAutoresizingMaskIntoConstraints = false
        recallLabel.translatesAutoresizingMaskIntoConstraints = false

        do {
            let views: [String: AnyObject] = [
                "recallLabel": recallLabel,
            ]

            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-(>=20)-[recallLabel]-(>=20)-|", options: [], metrics: nil, views: views)

            let centerX = NSLayoutConstraint(item: recallLabel, attribute: .CenterX, relatedBy: .Equal, toItem: contentView, attribute: .CenterX, multiplier: 1.0, constant: 0)
            let centerY = NSLayoutConstraint(item: recallLabel, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1.0, constant: 0)

            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints([centerX, centerY])
        }

        do {
            let leading = NSLayoutConstraint(item: bubbleImageView, attribute: .Leading, relatedBy: .Equal, toItem: recallLabel, attribute: .Leading, multiplier: 1.0, constant: -10)
            let trailing = NSLayoutConstraint(item: bubbleImageView, attribute: .Trailing, relatedBy: .Equal, toItem: recallLabel, attribute: .Trailing, multiplier: 1.0, constant: 10)

            let centerX = NSLayoutConstraint(item: bubbleImageView, attribute: .CenterX, relatedBy: .Equal, toItem: recallLabel, attribute: .CenterX, multiplier: 1.0, constant: 0)
            let centerY = NSLayoutConstraint(item: bubbleImageView, attribute: .CenterY, relatedBy: .Equal, toItem: recallLabel, attribute: .CenterY, multiplier: 1.0, constant: 0)

            let height = NSLayoutConstraint(item: bubbleImageView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 24)

            NSLayoutConstraint.activateConstraints([leading, trailing, centerX, centerY, height])
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum IndicateType {
        case RecalledMessage
        case BlockedByRecipient
    }

    func configureWithMessage(message: Message, indicateType: IndicateType) {
        switch indicateType {
        case .RecalledMessage:
            recallLabel.text = message.recalledTextContent
        case .BlockedByRecipient:
            recallLabel.text = message.blockedTextContent
        }
    }
}
