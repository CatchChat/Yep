//
//  ChatLeftRecallCell.swift
//  Yep
//
//  Created by nixzhu on 16/1/25.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class ChatLeftRecallCell: UICollectionViewCell {

    lazy var recallLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.blueColor()
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(recallLabel)
        recallLabel.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "recallLabel": recallLabel,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-65-[recallLabel]-(>=20)-|", options: [], metrics: nil, views: views)
        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[recallLabel]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(constraintsV)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureWithMessage(message: Message) {
        recallLabel.text = message.recalledTextContent
    }
}
