//
//  FeedDribbbleShotCell.swift
//  Yep
//
//  Created by nixzhu on 15/12/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepPreview
import Ruler

private let screenWidth: CGFloat = UIScreen.main.bounds.width
private let dribbbleShotHeight: CGFloat = Ruler.iPhoneHorizontal(160, 200, 220).value

final class FeedDribbbleShotCell: FeedBasicCell {

    override class func heightOfFeed(_ feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + (dribbbleShotHeight + 15)

        return ceil(height)
    }

    var tapDribbbleShotLinkAction: ((URL) -> Void)?
    var tapDribbbleShotMediaAction: ((_ transitionReference: Reference, _ image: UIImage?, _ imageURL: URL, _ linkURL: URL) -> Void)?
    
    lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: SocialAccount.dribbble.iconName)
        imageView.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        imageView.tintColor = SocialAccount.dribbble.tintColor
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

    override func prepareForReuse() {
        super.prepareForReuse()

        mediaContainerView.mediaImageView.image = nil
    }

    override func configureWithFeed(_ feed: DiscoveredFeed, layout: FeedCellLayout, needShowSkill: Bool) {

        super.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

        if let attachment = feed.attachment {
            if case let .dribbble(dribbbleShot) = attachment {
                if let url = URL(string: dribbbleShot.imageURLString) {
                    //mediaContainerView.mediaImageView.kf_showIndicatorWhenLoading = true
                    mediaContainerView.mediaImageView.kf.setImage(with: url, placeholder: nil, options: MediaOptionsInfos)
                }

                mediaContainerView.linkContainerView.textLabel.text = dribbbleShot.title
            }
        }

        mediaContainerView.tapMediaAction = { [weak self] transitionReference in

            guard let attachment = feed.attachment else {
                return
            }

            if case .dribbbleShot = feed.kind {
                if case let .dribbble(shot) = attachment, let imageURL = URL(string: shot.imageURLString), let linkURL = URL(string: shot.htmlURLString) {
                    self?.tapDribbbleShotMediaAction?(transitionReference, transitionReference.image, imageURL, linkURL)
                }
            }
        }

        mediaContainerView.linkContainerView.tapAction = { [weak self] in

            guard let attachment = feed.attachment else {
                return
            }

            if case .dribbbleShot = feed.kind {
                if case let .dribbble(shot) = attachment, let url = URL(string: shot.htmlURLString) {
                    self?.tapDribbbleShotLinkAction?(url)
                }
            }
        }

        if needShowSkill, let _ = feed.skill {
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
        mediaContainerView.mediaImageView.mask = halfMaskImageView
    }
}

