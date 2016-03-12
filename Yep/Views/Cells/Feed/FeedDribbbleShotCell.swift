//
//  FeedDribbbleShotCell.swift
//  Yep
//
//  Created by nixzhu on 15/12/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

private let screenWidth: CGFloat = UIScreen.mainScreen().bounds.width
private let dribbbleShotHeight: CGFloat = Ruler.iPhoneHorizontal(160, 200, 220).value

class FeedDribbbleShotCell: FeedBasicCell {

    var tapDribbbleShotLinkAction: (NSURL -> Void)?
    var tapDribbbleShotMediaAction: ((transitionView: UIView, image: UIImage?, imageURL: NSURL, linkURL: NSURL) -> Void)?
    
    lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: SocialAccount.Dribbble.iconName)
        imageView.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        imageView.tintColor = SocialAccount.Dribbble.tintColor
        return imageView
    }()

    lazy var mediaContainerView: FeedMediaContainerView = {
        let view = FeedMediaContainerView()
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        return view
    }()

    lazy var socialWorkBorderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "social_work_border")
//        imageView.backgroundColor = UIColor.redColor()
        return imageView
    }()

    lazy var halfMaskImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "social_media_image_mask"))
        return imageView
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(logoImageView)
        contentView.addSubview(mediaContainerView)
        contentView.addSubview(socialWorkBorderImageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + (dribbbleShotHeight + 15)

        return ceil(height)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        mediaContainerView.mediaImageView.image = nil
    }

    override func configureWithFeed(feed: DiscoveredFeed, layoutCache: FeedCellLayout.Cache, needShowSkill: Bool) {

        var _newLayout: FeedCellLayout?
        super.configureWithFeed(feed, layoutCache: (layout: layoutCache.layout, update: { newLayout in
            _newLayout = newLayout
        }), needShowSkill: needShowSkill)
        // MARK: Test

        if needShowSkill, let _ = feed.skill {
            logoImageView.frame.origin.x = skillButton.frame.origin.x - 10 - 18
            logoImageView.frame.origin.y = nicknameLabel.frame.origin.y

        } else {
            logoImageView.frame.origin.x = detailViewColumnWidth - feedTextFixedSpace - logoImageView.frame.width
            logoImageView.frame.origin.y = nicknameLabel.frame.origin.y
        }
        nicknameLabel.frame.size.width -= logoImageView.bounds.width + 10

        if let attachment = feed.attachment {
            if case let .Dribbble(dribbbleShot) = attachment {
                if let URL = NSURL(string: dribbbleShot.imageURLString) {
                    mediaContainerView.mediaImageView.kf_showIndicatorWhenLoading = true
                    mediaContainerView.mediaImageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: MediaOptionsInfos)
                }

                mediaContainerView.linkContainerView.textLabel.text = dribbbleShot.title
            }
        }

        mediaContainerView.tapMediaAction = { [weak self] mediaImageView in

            guard let attachment = feed.attachment else {
                return
            }

            if case .DribbbleShot = feed.kind {
                if case let .Dribbble(shot) = attachment, let imageURL = NSURL(string: shot.imageURLString), let linkURL = NSURL(string: shot.htmlURLString) {
                    self?.tapDribbbleShotMediaAction?(transitionView: mediaImageView, image: mediaImageView.image, imageURL: imageURL, linkURL: linkURL)
                }
            }
        }

        mediaContainerView.linkContainerView.tapAction = { [weak self] in

            guard let attachment = feed.attachment else {
                return
            }

            if case .DribbbleShot = feed.kind {
                if case let .Dribbble(shot) = attachment, let URL = NSURL(string: shot.htmlURLString) {
                    self?.tapDribbbleShotLinkAction?(URL)
                }
            }
        }

//        if let dribbbleShotLayout = layoutCache.layout?.dribbbleShotLayout {
//            mediaContainerView.frame = dribbbleShotLayout.dribbbleShotContainerViewFrame
//            socialWorkBorderImageView.frame = mediaContainerView.frame
//
//        } else {
            let y = messageTextView.frame.origin.y + messageTextView.frame.height + 15
            let height: CGFloat = leftBottomLabel.frame.origin.y - y - 15
            mediaContainerView.frame = CGRect(x: feedTextFixedSpace, y: y, width: feedTextMaxWidth, height: height)
            socialWorkBorderImageView.frame = mediaContainerView.frame
//        }
        mediaContainerView.layoutIfNeeded()

        halfMaskImageView.frame = mediaContainerView.mediaImageView.bounds
        mediaContainerView.mediaImageView.maskView = halfMaskImageView

        if layoutCache.layout == nil {

            let dribbbleShotLayout = FeedCellLayout.DribbbleShotLayout(dribbbleShotContainerViewFrame: mediaContainerView.frame)
            _newLayout?.dribbbleShotLayout = dribbbleShotLayout

            if let newLayout = _newLayout {
                layoutCache.update(layout: newLayout)
            }
        }
    }
}

