//
//  FeedView.swift
//  Yep
//
//  Created by nixzhu on 15/9/25.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedView: UIView {

    var feed: DiscoveredFeed? {
        willSet {
            if let feed = newValue {
                configureWithFeed(feed)
            }
        }
    }

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
                    self?.messageCountLabel.alpha = foldingAlpha
                    self?.messageCountImageView.alpha = foldingAlpha

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

    @IBOutlet weak var messageCountLabel: UILabel!
    @IBOutlet weak var messageCountImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        clipsToBounds = true

        /*
        avatarImageView.backgroundColor = UIColor.redColor()
        nicknameLabel.backgroundColor = UIColor.redColor()
        distanceLabel.backgroundColor = UIColor.redColor()
        messageLabel.backgroundColor = UIColor.redColor()
        mediaCollectionView.backgroundColor = UIColor.redColor()
        timeLabel.backgroundColor = UIColor.redColor()
        messageCountLabel.backgroundColor = UIColor.redColor()
        */

        messageLabel.font = UIFont.feedMessageFont()

        mediaView.alpha = 0

        //mediaCollectionView.dataSource = self
        //mediaCollectionView.delegate = self

        //mediaCollectionView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")

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

        let rect = feed.body.boundingRectWithSize(CGSize(width: FeedCell.messageLabelMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.ChatCell.textAttributes, context: nil)

        let height: CGFloat
        if feed.attachments.isEmpty {
            height = ceil(rect.height) + 10 + 40 + 4 + 10 + 20.5 + 10
        } else {
            height = ceil(rect.height) + 10 + 40 + 4 + 10 + 80 + 10 + 20.5 + 10
        }

        return ceil(height)
    }

    private func configureWithFeed(feed: DiscoveredFeed) {

        messageLabel.text = feed.body

        let hasMedia = !feed.attachments.isEmpty
        timeLabelTopConstraint.constant = hasMedia ? 100 : 10
        mediaCollectionView.hidden = hasMedia ? false : true

        let URLs = feed.attachments.map({ NSURL(string: $0.URLString) }).flatMap({ $0 })

        mediaView.setImagesWithURLs(URLs)

        let avatarURLString = feed.creator.avatarURLString
        let radius = min(CGRectGetWidth(avatarImageView.bounds), CGRectGetHeight(avatarImageView.bounds)) * 0.5
        AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(avatarURLString, withRadius: radius) { [weak self] roundImage in
            dispatch_async(dispatch_get_main_queue()) {
                self?.avatarImageView.image = roundImage
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

