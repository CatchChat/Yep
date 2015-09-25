//
//  FeedCell.swift
//  Yep
//
//  Created by nixzhu on 15/9/25.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!

    @IBOutlet weak var nicknameLabel: UILabel!

    @IBOutlet weak var distanceLabel: UILabel!

    @IBOutlet weak var messageLabel: UILabel!

    @IBOutlet weak var mediaCollectionView: UICollectionView!

    @IBOutlet weak var timeLabel: UILabel!

    @IBOutlet weak var messageCountLabel: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageView.backgroundColor = UIColor.redColor()
        nicknameLabel.backgroundColor = UIColor.redColor()
        distanceLabel.backgroundColor = UIColor.redColor()
        messageLabel.backgroundColor = UIColor.redColor()
        mediaCollectionView.backgroundColor = UIColor.redColor()
        timeLabel.backgroundColor = UIColor.redColor()
        messageCountLabel.backgroundColor = UIColor.redColor()
    }
}

