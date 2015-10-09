//
//  FeedCell.swift
//  Yep
//
//  Created by nixzhu on 15/9/30.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!

    @IBOutlet weak var messageLabel: UILabel!

    @IBOutlet weak var mediaCollectionView: UICollectionView!

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var messageCountLabel: UILabel!


    var tapMediaAction: (() -> Void)?


    var attachmentURLs = [NSURL]() {
        didSet {
            mediaCollectionView.reloadData()
        }
    }

    static let messageLabelMaxWidth: CGFloat = {
        let maxWidth = UIScreen.mainScreen().bounds.width - (15 + 40 + 10 + 15)
        return maxWidth
        }()

    let feedMediaCellID = "FeedMediaCell"

    class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let rect = feed.body.boundingRectWithSize(CGSize(width: FeedCell.messageLabelMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedCell.textAttributes, context: nil)

        let height: CGFloat
        if feed.attachments.isEmpty {
            height = ceil(rect.height) + 10 + 40 + 4 + 15 + 17 + 15
        } else {
            height = ceil(rect.height) + 10 + 40 + 4 + 15 + 80 + 15 + 17 + 15
        }

        return ceil(height)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        nicknameLabel.textColor = UIColor.yepTintColor()
        messageLabel.textColor = UIColor.yepMessageColor()
        distanceLabel.textColor = UIColor.grayColor()
        timeLabel.textColor = UIColor.grayColor()
        messageCountLabel.textColor = UIColor.yepTintColor()

        messageLabel.font = UIFont.feedMessageFont()

        mediaCollectionView.scrollsToTop = false
        mediaCollectionView.contentInset = UIEdgeInsets(top: 0, left: 15 + 40 + 10, bottom: 0, right: 15)
        mediaCollectionView.showsHorizontalScrollIndicator = false
        mediaCollectionView.backgroundColor = UIColor.clearColor()
        mediaCollectionView.registerNib(UINib(nibName: feedMediaCellID, bundle: nil), forCellWithReuseIdentifier: feedMediaCellID)
        mediaCollectionView.dataSource = self
        mediaCollectionView.delegate = self
    }

    func configureWithFeed(feed: DiscoveredFeed) {

        messageLabel.text = feed.body

        let hasMedia = !feed.attachments.isEmpty
        timeLabelTopConstraint.constant = hasMedia ? (15 + 80 + 15) : 15
        mediaCollectionView.hidden = hasMedia ? false : true

        attachmentURLs = feed.attachments.map({ NSURL(string: $0.URLString) }).flatMap({ $0 })

        let avatarURLString = feed.creator.avatarURLString
        let radius = min(CGRectGetWidth(avatarImageView.bounds), CGRectGetHeight(avatarImageView.bounds)) * 0.5
        AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(avatarURLString, withRadius: radius) { [weak self] roundImage in
            dispatch_async(dispatch_get_main_queue()) {
                //if let _ = tableView.cellForRowAtIndexPath(indexPath) {
                self?.avatarImageView.image = roundImage
                //}
            }
        }

        nicknameLabel.text = feed.creator.nickname

        if let distance = feed.distance?.format(".1") {
            distanceLabel.text = "\(distance) km"
        }

        timeLabel.text = "\(NSDate(timeIntervalSince1970: feed.createdUnixTime).timeAgo)"
        messageCountLabel.text = "\(feed.messageCount)"
    }
}

extension FeedCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachmentURLs.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(feedMediaCellID, forIndexPath: indexPath) as! FeedMediaCell

        let imageURL = attachmentURLs[indexPath.item]

        println("attachment imageURL: \(imageURL)")

        cell.configureWithImageURL(imageURL)

        return cell
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        return CGSize(width: 80, height: 80)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        tapMediaAction?()
    }
}

