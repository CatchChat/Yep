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
    @IBOutlet weak var messageLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var mediaCollectionView: UICollectionView!

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageCountLabel: UILabel!

    static let messageLabelMaxWidth: CGFloat = {
        let maxWidth = UIScreen.mainScreen().bounds.width - (60 + 10)
        return maxWidth
        }()

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageView.backgroundColor = UIColor.redColor()
        nicknameLabel.backgroundColor = UIColor.redColor()
        distanceLabel.backgroundColor = UIColor.redColor()
        messageLabel.backgroundColor = UIColor.redColor()
        mediaCollectionView.backgroundColor = UIColor.redColor()
        timeLabel.backgroundColor = UIColor.redColor()
        messageCountLabel.backgroundColor = UIColor.redColor()

        messageLabel.font = UIFont.feedMessageFont()
        
        mediaCollectionView.dataSource = self
        mediaCollectionView.delegate = self

        mediaCollectionView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    }

    func configureWithFeed(feed: FeedsViewController.FakeFeed) {
        messageLabel.text = feed.message

        let hasMedia = feed.mediaCount > 0
        messageLabelTopConstraint.constant = hasMedia ? 100 : 10
        mediaCollectionView.hidden = hasMedia ? false : true
    }
}

extension FeedCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 15
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath)
        cell.backgroundColor = UIColor.greenColor()
        return cell
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        return CGSize(width: 80, height: 80)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

