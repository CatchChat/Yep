//
//  FeedView.swift
//  Yep
//
//  Created by nixzhu on 15/9/25.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedView: UIView {

    var feed: ConversationFeed? {
        willSet {
            if let feed = newValue {
                configureWithFeed(feed)
            }
        }
    }

    var tapMediaAction: ((transitionView: UIView, imageURL: NSURL) -> Void)?

    static let foldHeight: CGFloat = 60

    weak var heightConstraint: NSLayoutConstraint?

    class func instanceFromNib() -> FeedView {
        return UINib(nibName: "FeedView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! FeedView
    }

    var foldProgress: CGFloat = 0 {
        willSet {
            if newValue >= 0 && newValue <= 1 {

                let normalHeight = self.normalHeight

                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.0, options: UIViewAnimationOptions(rawValue: 0), animations: { [weak self] in

                    self?.nicknameLabelCenterYConstraint.constant = -10 * newValue
                    self?.messageLabelTopConstraint.constant = -25 * newValue + 4

                    if newValue == 1.0 {
                        self?.messageLabelTrailingConstraint.constant = -(40 + 10)
                        self?.messageLabel.numberOfLines = 1
                    }

                    if newValue == 0.0 {
                        self?.messageLabelTrailingConstraint.constant = 0
                        self?.messageLabel.numberOfLines = 0
                    }

                    self?.heightConstraint?.constant = FeedView.foldHeight + (normalHeight - FeedView.foldHeight) * (1 - newValue)

                    self?.layoutIfNeeded()

                    let foldingAlpha = (1 - newValue)
                    self?.distanceLabel.alpha = foldingAlpha
                    self?.mediaCollectionView.alpha = foldingAlpha
                    self?.timeLabel.alpha = foldingAlpha

                    self?.mediaView.alpha = newValue

                }, completion: nil)

                if newValue == 1.0 {
                    foldAction?()
                }

                if newValue == 0.0 {
                    unfoldAction?(self)
                }
            }
        }
    }

    var foldAction: (() -> Void)?
    var unfoldAction: (FeedView -> Void)?

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var nicknameLabelCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var distanceLabel: UILabel!

    @IBOutlet weak var mediaView: FeedMediaView!

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabelTrailingConstraint: NSLayoutConstraint!

    @IBOutlet weak var mediaCollectionView: UICollectionView!

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeLabelTopConstraint: NSLayoutConstraint!

    var attachmentURLs = [NSURL]() {
        didSet {
            mediaCollectionView.reloadData()
            mediaView.setImagesWithURLs(attachmentURLs)
        }
    }

    static let messageLabelMaxWidth: CGFloat = {
        let maxWidth = UIScreen.mainScreen().bounds.width - (15 + 40 + 10 + 15)
        return maxWidth
        }()

    let feedMediaCellID = "FeedMediaCell"

    override func awakeFromNib() {
        super.awakeFromNib()

        clipsToBounds = true

        nicknameLabel.textColor = UIColor.yepTintColor()
        messageLabel.textColor = UIColor.darkGrayColor()
        distanceLabel.textColor = UIColor.grayColor()
        timeLabel.textColor = UIColor.grayColor()

        messageLabel.font = UIFont.feedMessageFont()

        mediaView.alpha = 0

        mediaCollectionView.contentInset = UIEdgeInsets(top: 0, left: 15 + 40 + 10, bottom: 0, right: 15)
        mediaCollectionView.showsHorizontalScrollIndicator = false
        mediaCollectionView.backgroundColor = UIColor.clearColor()
        mediaCollectionView.registerNib(UINib(nibName: feedMediaCellID, bundle: nil), forCellWithReuseIdentifier: feedMediaCellID)
        mediaCollectionView.dataSource = self
        mediaCollectionView.delegate = self

        let tap = UITapGestureRecognizer(target: self, action: "unfold:")
        mediaView.addGestureRecognizer(tap)
    }

    func unfold(sender: UITapGestureRecognizer) {
        foldProgress = 0
    }

    var normalHeight: CGFloat {

        guard let feed = feed else {
            return 220
        }

        let rect = feed.body.boundingRectWithSize(CGSize(width: FeedView.messageLabelMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedView.textAttributes, context: nil)

        let height: CGFloat
        
        if feed.attachments.isEmpty {
            height = ceil(rect.height) + 10 + 40 + 4 + 15 + 17 + 15
        } else {
            height = ceil(rect.height) + 10 + 40 + 4 + 15 + 80 + 15 + 17 + 15
        }

        return ceil(height)
    }

    private func configureWithFeed(feed: ConversationFeed) {

        messageLabel.text = feed.body

        let hasMedia = !feed.attachments.isEmpty
        timeLabelTopConstraint.constant = hasMedia ? (15 + 80 + 15) : 15
        mediaCollectionView.hidden = hasMedia ? false : true

        attachmentURLs = feed.attachments.map({ NSURL(string: $0.URLString) }).flatMap({ $0 })

        if let creator = feed.creator {
            let avatarURLString = creator.avatarURLString
            let radius = min(CGRectGetWidth(avatarImageView.bounds), CGRectGetHeight(avatarImageView.bounds)) * 0.5
            AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(avatarURLString, withRadius: radius) { [weak self] roundImage in
                dispatch_async(dispatch_get_main_queue()) {
                    self?.avatarImageView.image = roundImage
                }
            }
            
            nicknameLabel.text = creator.nickname
        }
        

        if let distance = feed.distance?.format(".1") {
            distanceLabel.text = "\(distance) km"
        }

        timeLabel.text = "\(NSDate(timeIntervalSince1970: feed.createdUnixTime).timeAgo)"
    }
}

extension FeedView: UICollectionViewDataSource, UICollectionViewDelegate {

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

        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! FeedMediaCell

        let transitionView = cell.imageView
        let imageURL = attachmentURLs[indexPath.item]
        tapMediaAction?(transitionView: transitionView, imageURL: imageURL)
    }
}

