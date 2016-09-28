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
        imageView.tintAdjustmentMode = .normal
        return imageView
    }()

    lazy var recallLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
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
            let views: [String: Any] = [
                "recallLabel": recallLabel,
            ]

            let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=20)-[recallLabel]-(>=20)-|", options: [], metrics: nil, views: views)

            let centerX = NSLayoutConstraint(item: recallLabel, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1.0, constant: 0)
            let centerY = NSLayoutConstraint(item: recallLabel, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1.0, constant: 0)

            NSLayoutConstraint.activate(constraintsH)
            NSLayoutConstraint.activate([centerX, centerY])
        }

        do {
            let leading = NSLayoutConstraint(item: bubbleImageView, attribute: .leading, relatedBy: .equal, toItem: recallLabel, attribute: .leading, multiplier: 1.0, constant: -10)
            let trailing = NSLayoutConstraint(item: bubbleImageView, attribute: .trailing, relatedBy: .equal, toItem: recallLabel, attribute: .trailing, multiplier: 1.0, constant: 10)

            let centerX = NSLayoutConstraint(item: bubbleImageView, attribute: .centerX, relatedBy: .equal, toItem: recallLabel, attribute: .centerX, multiplier: 1.0, constant: 0)
            let centerY = NSLayoutConstraint(item: bubbleImageView, attribute: .centerY, relatedBy: .equal, toItem: recallLabel, attribute: .centerY, multiplier: 1.0, constant: 0)

            let height = NSLayoutConstraint(item: bubbleImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 24)

            NSLayoutConstraint.activate([leading, trailing, centerX, centerY, height])
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum IndicateType {
        case recalledMessage
        case blockedByRecipient
    }

    func configureWithMessage(_ message: Message, indicateType: IndicateType) {
        switch indicateType {
        case .recalledMessage:
            recallLabel.text = message.recalledTextContent
        case .blockedByRecipient:
            recallLabel.text = message.blockedTextContent
        }
    }
}
