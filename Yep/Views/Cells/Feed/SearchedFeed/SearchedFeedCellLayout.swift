//
//  SearchedFeedCellLayout.swift
//  Yep
//
//  Created by NIX on 16/4/19.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

private let screenWidth: CGFloat = UIScreen.mainScreen().bounds.width

struct SearchedFeedCellLayout {

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

        init(avatarImageViewFrame: CGRect,
             nicknameLabelFrame: CGRect,
             skillButtonFrame: CGRect,
             messageTextViewFrame: CGRect) {
            self.avatarImageViewFrame = avatarImageViewFrame
            self.nicknameLabelFrame = nicknameLabelFrame
            self.skillButtonFrame = skillButtonFrame

            self.messageTextViewFrame = messageTextViewFrame
        }
    }
    let basicLayout: BasicLayout

    struct NormalImagesLayout {

        let imageView1Frame: CGRect
        let imageView2Frame: CGRect
        let imageView3Frame: CGRect
        let imageView4Frame: CGRect

        init(imageView1Frame: CGRect, imageView2Frame: CGRect, imageView3Frame: CGRect, imageView4Frame: CGRect) {
            self.imageView1Frame = imageView1Frame
            self.imageView2Frame = imageView2Frame
            self.imageView3Frame = imageView3Frame
            self.imageView4Frame = imageView4Frame
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
            height = SearchedFeedBasicCell.heightOfFeed(feed)

        case .URL:
            height = SearchedFeedURLCell.heightOfFeed(feed)

        case .Image:
            if feed.imageAttachmentsCount <= SearchFeedsViewController.feedNormalImagesCountThreshold {
                height = SearchedFeedNormalImagesCell.heightOfFeed(feed)

            } else {
                height = SearchedFeedAnyImagesCell.heightOfFeed(feed)
            }

        case .GithubRepo:
            height = SearchedFeedGithubRepoCell.heightOfFeed(feed)

        case .DribbbleShot:
            height = SearchedFeedDribbbleShotCell.heightOfFeed(feed)

        case .Audio:
            height = SearchedFeedVoiceCell.heightOfFeed(feed)

        case .Location:
            height = SearchedFeedLocationCell.heightOfFeed(feed)

        default:
            height = SearchedFeedBasicCell.heightOfFeed(feed)
        }

        self.height = height

        let avatarImageViewFrame = CGRect(x: 10, y: 15, width: 30, height: 30)

        let nicknameLabelFrame: CGRect
        let skillButtonFrame: CGRect

        if let skill = feed.skill {

            let rect = skill.localName.boundingRectWithSize(CGSize(width: 320, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedBasicCell.skillTextAttributes, context: nil)

            let skillButtonWidth = ceil(rect.width) + 20

            skillButtonFrame = CGRect(x: screenWidth - skillButtonWidth - 10, y: 18, width: skillButtonWidth, height: 22)

            let nicknameLabelWidth = screenWidth - 50 - 10
            nicknameLabelFrame = CGRect(x: 50, y: 20, width: nicknameLabelWidth, height: 18)

        } else {
            let nicknameLabelWidth = screenWidth - 50 - 10
            nicknameLabelFrame = CGRect(x: 50, y: 20, width: nicknameLabelWidth, height: 18)
            skillButtonFrame = CGRectZero
        }

        let _rect1 = feed.body.boundingRectWithSize(CGSize(width: SearchedFeedBasicCell.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedBasicCell.textAttributes, context: nil)

        let messageTextViewHeight = ceil(_rect1.height)
        let messageTextViewFrame = CGRect(x: 50, y: 15 + 30 + 4, width: screenWidth - 50 - 10, height: messageTextViewHeight)

        let basicLayout = SearchedFeedCellLayout.BasicLayout(
            avatarImageViewFrame: avatarImageViewFrame,
            nicknameLabelFrame: nicknameLabelFrame,
            skillButtonFrame: skillButtonFrame,
            messageTextViewFrame: messageTextViewFrame
        )

        self.basicLayout = basicLayout

        let beginY = messageTextViewFrame.origin.y + messageTextViewFrame.height + 10

        switch feed.kind {

        case .Text:
            break

        case .URL:

            let height: CGFloat = 20
            let URLContainerViewFrame = CGRect(x: 50, y: beginY, width: screenWidth - 50 - 60, height: height)

            let _URLLayout = SearchedFeedCellLayout.URLLayout(URLContainerViewFrame: URLContainerViewFrame)

            self._URLLayout = _URLLayout

        case .Image:

            if feed.imageAttachmentsCount <= SearchFeedsViewController.feedNormalImagesCountThreshold {
                let x1 = 50 + (YepConfig.SearchedFeedNormalImagesCell.imageSize.width + 5) * 0
                let imageView1Frame = CGRect(origin: CGPoint(x: x1, y: beginY), size: YepConfig.SearchedFeedNormalImagesCell.imageSize)

                let x2 = 50 + (YepConfig.SearchedFeedNormalImagesCell.imageSize.width + 5) * 1
                let imageView2Frame = CGRect(origin: CGPoint(x: x2, y: beginY), size: YepConfig.SearchedFeedNormalImagesCell.imageSize)

                let x3 = 50 + (YepConfig.SearchedFeedNormalImagesCell.imageSize.width + 5) * 2
                let imageView3Frame = CGRect(origin: CGPoint(x: x3, y: beginY), size: YepConfig.SearchedFeedNormalImagesCell.imageSize)

                let x4 = 50 + (YepConfig.SearchedFeedNormalImagesCell.imageSize.width + 5) * 3
                let imageView4Frame = CGRect(origin: CGPoint(x: x4, y: beginY), size: YepConfig.SearchedFeedNormalImagesCell.imageSize)

                let normalImagesLayout = SearchedFeedCellLayout.NormalImagesLayout(imageView1Frame: imageView1Frame, imageView2Frame: imageView2Frame, imageView3Frame: imageView3Frame, imageView4Frame: imageView4Frame)
                
                self.normalImagesLayout = normalImagesLayout

            } else {
                let height = YepConfig.FeedNormalImagesCell.imageSize.height
                let mediaCollectionViewFrame = CGRect(x: 0, y: beginY, width: screenWidth, height: height)

                let anyImagesLayout = SearchedFeedCellLayout.AnyImagesLayout(mediaCollectionViewFrame: mediaCollectionViewFrame)

                self.anyImagesLayout = anyImagesLayout
            }

        case .GithubRepo:

            let height: CGFloat = 80
            let githubRepoContainerViewFrame = CGRect(x: 50, y: beginY, width: screenWidth - 50 - 60, height: height)

            let githubRepoLayout = SearchedFeedCellLayout.GithubRepoLayout(githubRepoContainerViewFrame: githubRepoContainerViewFrame)

            self.githubRepoLayout = githubRepoLayout

        case .DribbbleShot:

            let height: CGFloat = SearchedFeedDribbbleShotCell.dribbbleShotHeight
            let dribbbleShotContainerViewFrame = CGRect(x: 50, y: beginY, width: screenWidth - 50 - 60, height: height)

            let dribbbleShotLayout = SearchedFeedCellLayout.DribbbleShotLayout(dribbbleShotContainerViewFrame: dribbbleShotContainerViewFrame)

            self.dribbbleShotLayout = dribbbleShotLayout

        case .Audio:

            if let attachment = feed.attachment {
                if case let .Audio(audioInfo) = attachment {
                    let timeLengthString = audioInfo.duration.yep_feedAudioTimeLengthString
                    let width = FeedVoiceContainerView.fullWidthWithSampleValuesCount(audioInfo.sampleValues.count, timeLengthString: timeLengthString)
                    let y = beginY + 2
                    let voiceContainerViewFrame = CGRect(x: 50, y: y, width: width, height: 50)
                    
                    let audioLayout = SearchedFeedCellLayout.AudioLayout(voiceContainerViewFrame: voiceContainerViewFrame)
                    
                    self.audioLayout = audioLayout
                }
            }
            
        case .Location:
            
            let height: CGFloat = 20
            let locationContainerViewFrame = CGRect(x: 50, y: beginY, width: screenWidth - 50 - 60, height: height)
            
            let locationLayout = SearchedFeedCellLayout.LocationLayout(locationContainerViewFrame: locationContainerViewFrame)
            
            self.locationLayout = locationLayout
            
        default:
            break
        }
    }
}
