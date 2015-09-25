//
//  FeedView.swift
//  Yep
//
//  Created by nixzhu on 15/9/25.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedView: UIView {

    static let normalHeight: CGFloat = 200
    static let foldHeight: CGFloat = 60

    weak var heightConstraint: NSLayoutConstraint?

    class func instanceFromNib() -> FeedView {
        return UINib(nibName: "FeedView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! FeedView
    }

    var foldProgress: CGFloat = 0 {
        willSet {
            println(newValue)
            if newValue >= 0 && newValue <= 1 {
                nicknameLabelCenterYConstraint.constant = -10 * newValue
                messageLabelTopConstraint.constant = -25 * newValue + 4

                heightConstraint?.constant = FeedView.foldHeight + (FeedView.normalHeight - FeedView.foldHeight) * (1 - newValue)

                layoutIfNeeded()

                let foldingAlpha = (1 - newValue)
                distanceLabel.alpha = foldingAlpha
                mediaCollectionView.alpha = foldingAlpha
                timeLabel.alpha = foldingAlpha
                messageCountLabel.alpha = foldingAlpha
                messageCountImageView.alpha = foldingAlpha
            }
        }
    }

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var nicknameLabelCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var distanceLabel: UILabel!

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var mediaCollectionView: UICollectionView!

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var messageCountLabel: UILabel!
    @IBOutlet weak var messageCountImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        clipsToBounds = true

        avatarImageView.backgroundColor = UIColor.redColor()
        nicknameLabel.backgroundColor = UIColor.redColor()
        distanceLabel.backgroundColor = UIColor.redColor()
        messageLabel.backgroundColor = UIColor.redColor()
        mediaCollectionView.backgroundColor = UIColor.redColor()
        timeLabel.backgroundColor = UIColor.redColor()
        messageCountLabel.backgroundColor = UIColor.redColor()

        messageLabel.font = UIFont.feedMessageFont()

        //mediaCollectionView.dataSource = self
        //mediaCollectionView.delegate = self

        //mediaCollectionView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    }
}

