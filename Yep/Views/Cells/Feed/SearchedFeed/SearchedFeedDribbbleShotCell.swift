//
//  SearchedFeedDribbbleShotCell.swift
//  Yep
//
//  Created by NIX on 16/4/19.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Ruler

private let screenWidth: CGFloat = UIScreen.mainScreen().bounds.width

final class SearchedFeedDribbbleShotCell: SearchedFeedBasicCell {

    static let dribbbleShotHeight: CGFloat = Ruler.iPhoneHorizontal(160, 200, 220).value

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + (10 + dribbbleShotHeight)

        return ceil(height)
    }

    var tapDribbbleShotLinkAction: (NSURL -> Void)?
    var tapDribbbleShotMediaAction: ((transitionView: UIView, image: UIImage?, imageURL: NSURL, linkURL: NSURL) -> Void)?

    lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: SocialAccount.Dribbble.iconName)
        imageView.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        imageView.tintColor = YepConfig.SearchedItemCell.logoTintColor
        return imageView
    }()

    lazy var mediaContainerView: FeedMediaContainerView = {
        let view = FeedMediaContainerView()
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        return view
    }()

    lazy var socialWorkBorderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_socialWorkBorder
        return imageView
    }()

    lazy var halfMaskImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_socialMediaImageMask)
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

    override func configureWithFeed(feed: DiscoveredFeed, layout: SearchedFeedCellLayout, keyword: String?) {

        super.configureWithFeed(feed, layout: layout, keyword: keyword)

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

        if let _ = feed.skill {
            logoImageView.frame.origin.x = skillButton.frame.origin.x - 10 - 18
            logoImageView.frame.origin.y = nicknameLabel.frame.origin.y

        } else {
            logoImageView.frame.origin.x = screenWidth - 18 - 15
            logoImageView.frame.origin.y = nicknameLabel.frame.origin.y
        }
        nicknameLabel.frame.size.width -= logoImageView.bounds.width + 10

        let dribbbleShotLayout = layout.dribbbleShotLayout!
        mediaContainerView.frame = dribbbleShotLayout.dribbbleShotContainerViewFrame
        socialWorkBorderImageView.frame = mediaContainerView.frame
        mediaContainerView.layoutIfNeeded()

        halfMaskImageView.frame = mediaContainerView.mediaImageView.bounds
        mediaContainerView.mediaImageView.maskView = halfMaskImageView
    }
}

