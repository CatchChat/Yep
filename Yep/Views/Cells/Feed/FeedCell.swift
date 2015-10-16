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

    @IBOutlet weak var messageTextView: FeedTextView!
    @IBOutlet weak var messageTextViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var mediaCollectionView: UICollectionView!

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var messageCountLabel: UILabel!

    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!

    var tapAvatarAction: (() -> Void)?
    var tapMediaAction: ((transitionView: UIView, imageURL: NSURL) -> Void)?

    var mediaCollectionViewTouchesBeganAction: (() -> Void)?
    var mediaCollectionViewTouchesEndedAction: (() -> Void)?
    var mediaCollectionViewTouchesCancelledAction: (() -> Void)?

    var attachmentURLs = [NSURL]() {
        didSet {
            if attachmentURLs.count == 1 {
                collectionViewHeight.constant = 160
            } else {
                collectionViewHeight.constant = 80
            }
            contentView.layoutIfNeeded()
            mediaCollectionView.reloadData()
        }
    }

    static let messageTextViewMaxWidth: CGFloat = {
        let maxWidth = UIScreen.mainScreen().bounds.width - (15 + 40 + 10 + 15)
        return maxWidth
        }()

    let feedMediaCellID = "FeedMediaCell"

    class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let rect = feed.body.boundingRectWithSize(CGSize(width: FeedCell.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedCell.textAttributes, context: nil)

        let height: CGFloat
        if feed.attachments.isEmpty {
            height = ceil(rect.height) + 10 + 40 + 4 + 15 + 17 + 15
        } else {
            var imageHeight: CGFloat = 80
            if feed.attachments.count == 1 {
                imageHeight = 160
            }
            height = ceil(rect.height) + 10 + 40 + 4 + 15 + imageHeight + 15 + 17 + 15
        }

        return ceil(height)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        nicknameLabel.textColor = UIColor.yepTintColor()
        messageTextView.textColor = UIColor.yepMessageColor()
        distanceLabel.textColor = UIColor.grayColor()
        timeLabel.textColor = UIColor.grayColor()
        messageCountLabel.textColor = UIColor.yepTintColor()

        messageTextView.font = UIFont.feedMessageFont()
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        mediaCollectionView.scrollsToTop = false
        mediaCollectionView.contentInset = UIEdgeInsets(top: 0, left: 15 + 40 + 10, bottom: 0, right: 15)
        mediaCollectionView.showsHorizontalScrollIndicator = false
        mediaCollectionView.backgroundColor = UIColor.clearColor()
        mediaCollectionView.registerNib(UINib(nibName: feedMediaCellID, bundle: nil), forCellWithReuseIdentifier: feedMediaCellID)
        mediaCollectionView.dataSource = self
        mediaCollectionView.delegate = self

        let tapAvatar = UITapGestureRecognizer(target: self, action: "tapAvatar:")
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapAvatar)

        let backgroundView = TouchClosuresView(frame: mediaCollectionView.bounds)
        backgroundView.touchesBeganAction = { [weak self] in
            self?.mediaCollectionViewTouchesBeganAction?()
        }
        backgroundView.touchesEndedAction = { [weak self] in
            self?.mediaCollectionViewTouchesEndedAction?()
        }
        backgroundView.touchesCancelledAction = { [weak self] in
            self?.mediaCollectionViewTouchesCancelledAction?()
        }
        mediaCollectionView.backgroundView = backgroundView
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        attachmentURLs = []

        messageTextView.text = nil
        messageTextView.attributedText = nil
    }

    func tapAvatar(sender: UITapGestureRecognizer) {

        tapAvatarAction?()
    }

    private func calHeightOfMessageTextView() {

        let rect = messageTextView.text.boundingRectWithSize(CGSize(width: FeedCell.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedCell.textAttributes, context: nil)
        messageTextViewHeightConstraint.constant = ceil(rect.height)
    }

    func configureWithFeed(feed: DiscoveredFeed) {

        messageTextView.text = "\u{200B}\(feed.body)" // ref http://stackoverflow.com/a/25994821

        calHeightOfMessageTextView()

        let hasMedia = !feed.attachments.isEmpty
        
        if feed.attachments.count > 1 {
            timeLabelTopConstraint.constant = hasMedia ? (15 + 80 + 15) : 15
        } else {
            timeLabelTopConstraint.constant = hasMedia ? (15 + 160 + 15) : 15
        }

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

        if let imageURL = attachmentURLs[safe: indexPath.item] {

            //println("attachment imageURL: \(imageURL)")

            cell.configureWithImageURL(imageURL)
        }

        return cell
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        if attachmentURLs.count > 1 {
            return CGSize(width: 80, height: 80)
        } else {
            return CGSize(width: 160, height: 160)
        }

    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! FeedMediaCell

        let transitionView = cell.imageView
        let imageURL = attachmentURLs[indexPath.item]
        tapMediaAction?(transitionView: transitionView, imageURL: imageURL)
    }
}

