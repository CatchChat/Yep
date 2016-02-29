//
//  FeedCellLayout.swift
//  Yep
//
//  Created by nixzhu on 15/12/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

private let screenWidth: CGFloat = UIScreen.mainScreen().bounds.width

struct FeedCellLayout {

    typealias Update = (layout: FeedCellLayout) -> Void
    typealias Cache = (layout: FeedCellLayout?, update: Update)

    let height: CGFloat

    struct BasicLayout {

        func nicknameLabelFrameWhen(hasLogo hasLogo: Bool, hasSkill: Bool) -> CGRect {

            var frame = nicknameLabelFrame
            frame.size.width -= hasLogo ? (18 + 10) : 0
            frame.size.width -= hasSkill ? (skillButtonFrame.width + 10) : 0

            return frame
        }

        let avatarImageViewFrame: CGRect
        private let nicknameLabelFrame: CGRect
        let skillButtonFrame: CGRect

        let messageTextViewFrame: CGRect

        let leftBottomLabelFrame: CGRect
        let messageCountLabelFrame: CGRect
        let discussionImageViewFrame: CGRect

        init(avatarImageViewFrame: CGRect,
            nicknameLabelFrame: CGRect,
            skillButtonFrame: CGRect,
            messageTextViewFrame: CGRect,
            leftBottomLabelFrame: CGRect,
            messageCountLabelFrame: CGRect,
            discussionImageViewFrame: CGRect) {
                self.avatarImageViewFrame = avatarImageViewFrame
                self.nicknameLabelFrame = nicknameLabelFrame
                self.skillButtonFrame = skillButtonFrame

                self.messageTextViewFrame = messageTextViewFrame

                self.leftBottomLabelFrame = leftBottomLabelFrame
                self.messageCountLabelFrame = messageCountLabelFrame
                self.discussionImageViewFrame = discussionImageViewFrame
        }
    }
    let basicLayout: BasicLayout

    struct BiggerImageLayout {
        let biggerImageViewFrame: CGRect

        init(biggerImageViewFrame: CGRect) {
            self.biggerImageViewFrame = biggerImageViewFrame
        }
    }
    var biggerImageLayout: BiggerImageLayout?

    struct NormalImagesLayout {

        let imageView1Frame: CGRect
        let imageView2Frame: CGRect
        let imageView3Frame: CGRect

        init(imageView1Frame: CGRect, imageView2Frame: CGRect, imageView3Frame: CGRect) {
            self.imageView1Frame = imageView1Frame
            self.imageView2Frame = imageView2Frame
            self.imageView3Frame = imageView3Frame
        }
    }
    var normalImagesLayout: NormalImagesLayout?

    struct AnyImagesLayout {

        let mediaCollectionViewFrame: CGRect

        init(mediaCollectionViewFrame: CGRect) {
            self.mediaCollectionViewFrame = mediaCollectionViewFrame
        }
    }
    var anyImagesLayout: AnyImagesLayout?

    struct GithubRepoLayout {
        let githubRepoContainerViewFrame: CGRect
    }
    var githubRepoLayout: GithubRepoLayout?

    struct DribbbleShotLayout {
        let dribbbleShotContainerViewFrame: CGRect
    }
    var dribbbleShotLayout: DribbbleShotLayout?

    struct AudioLayout {
        let voiceContainerViewFrame: CGRect
    }
    var audioLayout: AudioLayout?

    struct LocationLayout {
        let locationContainerViewFrame: CGRect
    }
    var locationLayout: LocationLayout?

    struct URLLayout {
        let URLContainerViewFrame: CGRect
    }
    var _URLLayout: URLLayout?

    // MARK: - Init

    init(height: CGFloat, basicLayout: BasicLayout) {
        self.height = height
        self.basicLayout = basicLayout
    }

    init(feed: DiscoveredFeed) {

        let height: CGFloat

        switch feed.kind {

        case .Text:
            height = FeedBasicCell.heightOfFeed(feed)

        case .URL:
            height = FeedURLCell.heightOfFeed(feed)

        case .Image:
            if feed.imageAttachmentsCount == 1 {
                height = FeedBiggerImageCell.heightOfFeed(feed)

            } else if feed.imageAttachmentsCount <= 3 {
                height = FeedNormalImagesCell.heightOfFeed(feed)

            } else {
                height = FeedAnyImagesCell.heightOfFeed(feed)
            }

        case .GithubRepo:
            height = FeedGithubRepoCell.heightOfFeed(feed)

        case .DribbbleShot:
            height = FeedDribbbleShotCell.heightOfFeed(feed)

        case .Audio:
            height = FeedVoiceCell.heightOfFeed(feed)

        case .Location:
            height = FeedLocationCell.heightOfFeed(feed)

        default:
            height = FeedBasicCell.heightOfFeed(feed)
        }

        self.height = height

        let avatarImageViewFrame = CGRect(x: 15, y: 10, width: 40, height: 40)

        let nicknameLabelFrame: CGRect
        let skillButtonFrame: CGRect
        
        if let skill = feed.skill {

            let rect = skill.localName.boundingRectWithSize(CGSize(width: 320, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedBasicCell.skillTextAttributes, context: nil)

            let skillButtonWidth = ceil(rect.width) + 20

            skillButtonFrame = CGRect(x: screenWidth - skillButtonWidth - 15, y: 19, width: skillButtonWidth, height: 22)

            let nicknameLabelWidth = screenWidth - 65 - 15
            nicknameLabelFrame = CGRect(x: 65, y: 21, width: nicknameLabelWidth, height: 18)

        } else {
            let nicknameLabelWidth = screenWidth - 65 - 15
            nicknameLabelFrame = CGRect(x: 65, y: 21, width: nicknameLabelWidth, height: 18)
            skillButtonFrame = CGRectZero
        }

        let _rect1 = feed.body.boundingRectWithSize(CGSize(width: FeedBasicCell.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedBasicCell.textAttributes, context: nil)

        let messageTextViewHeight = ceil(_rect1.height)
        let messageTextViewFrame = CGRect(x: 65, y: 54, width: screenWidth - 65 - 15, height: messageTextViewHeight)

        let leftBottomLabelOriginY = height - 17 - 15
        let leftBottomLabelFrame = CGRect(x: 65, y: leftBottomLabelOriginY, width: screenWidth - 65 - 85, height: 17)

        //let messagesCountString = feed.messagesCount > 99 ? "99+" : "\(feed.messagesCount)"

        //let _rect2 = messagesCountString.boundingRectWithSize(CGSize(width: 320, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedBasicCell.bottomLabelsTextAttributes, context: nil)

        //let _width = ceil(_rect2.width)
        let _width: CGFloat = 30
        let messageCountLabelFrame = CGRect(x: screenWidth - _width - 45 - 8, y: leftBottomLabelOriginY, width: _width, height: 19)

        let discussionImageViewFrame = CGRect(x: screenWidth - 30 - 15, y: leftBottomLabelOriginY - 1, width: 30, height: 19)

        let basicLayout = FeedCellLayout.BasicLayout(
            avatarImageViewFrame: avatarImageViewFrame,
            nicknameLabelFrame: nicknameLabelFrame,
            skillButtonFrame: skillButtonFrame,
            messageTextViewFrame: messageTextViewFrame,
            leftBottomLabelFrame: leftBottomLabelFrame,
            messageCountLabelFrame: messageCountLabelFrame,
            discussionImageViewFrame: discussionImageViewFrame
        )

        self.basicLayout = basicLayout

        let beginY = messageTextViewFrame.origin.y + messageTextViewFrame.height + 15

        switch feed.kind {

        case .Text:
            break

        case .URL:

            let height: CGFloat = leftBottomLabelFrame.origin.y - beginY - 15
            let URLContainerViewFrame = CGRect(x: 65, y: beginY, width: screenWidth - 65 - 60, height: height)

            let _URLLayout = FeedCellLayout.URLLayout(URLContainerViewFrame: URLContainerViewFrame)

            self._URLLayout = _URLLayout
            
        case .Image:

            if feed.imageAttachmentsCount == 1 {

                let biggerImageViewFrame = CGRect(origin: CGPoint(x: 65, y: beginY), size: YepConfig.FeedBiggerImageCell.imageSize)

                let biggerImageLayout = FeedCellLayout.BiggerImageLayout(biggerImageViewFrame: biggerImageViewFrame)

                self.biggerImageLayout = biggerImageLayout

            } else if feed.imageAttachmentsCount <= 3 {

                let x1 = 65 + (YepConfig.FeedNormalImagesCell.imageSize.width + 5) * 0
                let imageView1Frame = CGRect(origin: CGPoint(x: x1, y: beginY), size: YepConfig.FeedNormalImagesCell.imageSize)

                let x2 = 65 + (YepConfig.FeedNormalImagesCell.imageSize.width + 5) * 1
                let imageView2Frame = CGRect(origin: CGPoint(x: x2, y: beginY), size: YepConfig.FeedNormalImagesCell.imageSize)

                let x3 = 65 + (YepConfig.FeedNormalImagesCell.imageSize.width + 5) * 2
                let imageView3Frame = CGRect(origin: CGPoint(x: x3, y: beginY), size: YepConfig.FeedNormalImagesCell.imageSize)

                let normalImagesLayout = FeedCellLayout.NormalImagesLayout(imageView1Frame: imageView1Frame, imageView2Frame: imageView2Frame, imageView3Frame: imageView3Frame)

                self.normalImagesLayout = normalImagesLayout

            } else {
                let height = feedAttachmentImageSize.height
                let mediaCollectionViewFrame = CGRect(x: 0, y: beginY, width: screenWidth, height: height)

                let anyImagesLayout = FeedCellLayout.AnyImagesLayout(mediaCollectionViewFrame: mediaCollectionViewFrame)

                self.anyImagesLayout = anyImagesLayout
            }

        case .GithubRepo:

            let height: CGFloat = leftBottomLabelFrame.origin.y - beginY - 15
            let githubRepoContainerViewFrame = CGRect(x: 65, y: beginY, width: screenWidth - 65 - 60, height: height)

            let githubRepoLayout = FeedCellLayout.GithubRepoLayout(githubRepoContainerViewFrame: githubRepoContainerViewFrame)

            self.githubRepoLayout = githubRepoLayout

        case .DribbbleShot:

            let height: CGFloat = leftBottomLabelFrame.origin.y - beginY - 15
            let dribbbleShotContainerViewFrame = CGRect(x: 65, y: beginY, width: screenWidth - 65 - 60, height: height)

            let dribbbleShotLayout = FeedCellLayout.DribbbleShotLayout(dribbbleShotContainerViewFrame: dribbbleShotContainerViewFrame)

            self.dribbbleShotLayout = dribbbleShotLayout

        case .Audio:

            if let attachment = feed.attachment {
                if case let .Audio(audioInfo) = attachment {
                    let timeLengthString = audioInfo.duration.yep_feedAudioTimeLengthString
                    let width = FeedVoiceContainerView.fullWidthWithSampleValuesCount(audioInfo.sampleValues.count, timeLengthString: timeLengthString)
                    let y = beginY + 2
                    let voiceContainerViewFrame = CGRect(x: 65, y: y, width: width, height: 50)

                    let audioLayout = FeedCellLayout.AudioLayout(voiceContainerViewFrame: voiceContainerViewFrame)

                    self.audioLayout = audioLayout
                }
            }

        case .Location:

            let height: CGFloat = leftBottomLabelFrame.origin.y - beginY - 15
            let locationContainerViewFrame = CGRect(x: 65, y: beginY, width: screenWidth - 65 - 60, height: height)

            let locationLayout = FeedCellLayout.LocationLayout(locationContainerViewFrame: locationContainerViewFrame)

            self.locationLayout = locationLayout

        default:
            break
        }
    }
}

