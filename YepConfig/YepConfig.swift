//
//  YepConfig.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import CoreLocation
import Ruler
import Kingfisher

public let avatarFadeTransitionDuration: NSTimeInterval = 0.0
public let bigAvatarFadeTransitionDuration: NSTimeInterval = 0.15
public let imageFadeTransitionDuration: NSTimeInterval = 0.2

public let MediaOptionsInfos: KingfisherOptionsInfo = [
    .BackgroundDecode,
    .Transition(ImageTransition.Fade(imageFadeTransitionDuration))
]

final public class YepConfig {

    public static let appGroupID: String = "group.Catch-Inc.Yep"
    
    public static let minMessageTextLabelWidth: CGFloat = 20.0
    
    public static let minMessageSampleViewWidth: CGFloat = 25.0
    
    public static let skillHomeHeaderViewHeight: CGFloat = 114.0
    
    public static let skillHomeHeaderButtonHeight: CGFloat = 50.0
    
    public static let maxFeedTextLength: Int = 300
    
    public class func clientType() -> Int {
        // TODO: clientType
        
        #if DEBUG
            return 2
        #else
            return 0
        #endif
    }

    public static let termsURLString = "http://privacy.soyep.com"
    public static let appURLString = "itms-apps://itunes.apple.com/app/id" + "983891256"

    public static let forcedHideActivityIndicatorTimeInterval: NSTimeInterval = 30

    public static let dismissKeyboardDelayTimeInterval : NSTimeInterval = 0.45

    public struct Notification {
        public static let markAsReaded = "YepConfig.Notification.markAsReaded"
        public static let changedConversation = "YepConfig.Notification.changedConversation"
        public static let changedFeedConversation = "YepConfig.Notification.changedFeedConversation"
        public static let newMessages = "YepConfig.Notification.newMessages"
        public static let deletedMessages = "YepConfig.Notification.deletedMessages"
        public static let updatedUser = "YepConfig.Notification.updatedUser"
        public static let OAuthResult = "YepConfig.Notification.OAuthResult"
        public static let createdFeed = "YepConfig.Notification.createdFeed"
        public static let deletedFeed = "YepConfig.Notification.deletedFeed"
        public static let switchedToOthersFromContactsTab = "YepConfig.Notification.switchedToOthersFromContactsTab"
        public static let blockedFeedsByCreator = "YepConfig.Notification.blockedFeedsByCreator"
    }

    public struct Message {
        // 注意：确保 localNewerTimeInterval > sectionOlderTimeInterval
        public static let localNewerTimeInterval: NSTimeInterval = 0.001
        public static let sectionOlderTimeInterval: NSTimeInterval = 0.0005

        public struct Notification {
            public static let MessageStateChanged = "MessageStateChangedNotification"
            public static let MessageBatchMarkAsRead = "MessageBatchMarkAsReadNotification"
        }
    }

    public class func getScreenRect() -> CGRect {
        return UIScreen.mainScreen().bounds
    }

    public class func verifyCodeLength() -> Int {
        return 4
    }

    public class func callMeInSeconds() -> Int {
        return 60
    }

    public class func avatarMaxSize() -> CGSize {
        return CGSize(width: 414, height: 414)
    }

    public class func chatCellAvatarSize() -> CGFloat {
        return 40.0
    }

    public class func chatCellGapBetweenTextContentLabelAndAvatar() -> CGFloat {
        return 23
    }

    public class func chatCellGapBetweenWallAndAvatar() -> CGFloat {
        return 15
    }

    public class func chatTextGapBetweenWallAndContentLabel() -> CGFloat {
        return 50
    }

    public class func avatarCompressionQuality() -> CGFloat {
        return 0.7
    }

    public class func messageImageCompressionQuality() -> CGFloat {
        return 0.95
    }

    public class func audioSampleWidth() -> CGFloat {
        return 2
    }

    public class func audioSampleGap() -> CGFloat {
        return 1
    }

    public class func editProfileAvatarSize() -> CGFloat {
        return 100
    }

    public struct AudioRecord {
        public static let shortestDuration: NSTimeInterval = 1.0
        public static let longestDuration: NSTimeInterval = 60
    }

    public struct Profile {
        public static let leftEdgeInset: CGFloat = Ruler.iPhoneHorizontal(20, 38, 40).value
        public static let rightEdgeInset: CGFloat = leftEdgeInset
        public static let introductionLabelFont = UIFont.systemFontOfSize(14)
    }
    
    public struct Settings {
        public static let userCellAvatarSize: CGFloat = 80

        public static let introFont: UIFont = {
            return UIFont.systemFontOfSize(12, weight: UIFontWeightLight)
        }()

        public static let introInset: CGFloat = 20 + userCellAvatarSize + 20 + 10 + 11 + 20
    }

    public struct EditProfile {

        public static let infoFont: UIFont = {
            return UIFont.systemFontOfSize(15, weight: UIFontWeightLight)
        }()

        public static let infoInset: CGFloat = 20 + 20
    }

    public struct SocialWorkGithub {
        public struct Repo {
            public static let leftEdgeInset: CGFloat = Ruler.iPhoneHorizontal(20, 40, 40).value
            public static let rightEdgeInset: CGFloat = leftEdgeInset
        }
    }

    public struct ContactsCell {
        public static let separatorInset = UIEdgeInsets(top: 0, left: 85, bottom: 0, right: 0)
    }

    public struct SearchTableView {
        public static let separatorColor = UIColor(red: 245/255.0, green: 245/255.0, blue: 245/255.0, alpha: 1)
        public static let backgroundColor = UIColor(red: 250/255.0, green: 250/255.0, blue: 250/255.0, alpha: 1)
    }

    public struct SearchedItemCell {
        public static let separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)

        public static let nicknameFont = UIFont.systemFontOfSize(14, weight: UIFontWeightMedium)
        public static let nicknameColor = UIColor.darkGrayColor()
        public static let usernameFont = UIFont.systemFontOfSize(12)
        public static let usernameColor = UIColor.lightGrayColor()
        public static let messageFont = UIFont.systemFontOfSize(12)
        public static let messageColor = UIColor.yep_mangmorGrayColor()
        public static let logoTintColor = UIColor.yep_mangmorGrayColor()
    }

    public struct ConversationCell {
        public static let avatarSize: CGFloat = 60
    }

    public struct ChatCell {
        
        public static let marginTopForGroup: CGFloat = 22
        public static let nameLabelHeightForGroup: CGFloat = 17

        public static let magicWidth: CGFloat = 4

        public static let lineSpacing: CGFloat = 5

        public static let minTextWidth: CGFloat = 17
        
        public static let gapBetweenDotImageViewAndBubble: CGFloat = 13

        public static let gapBetweenAvatarImageViewAndBubble: CGFloat = 5

        public static let playImageViewXOffset: CGFloat = 3

        public static let locationNameLabelHeight: CGFloat = 20

        public static let mediaPreferredWidth: CGFloat = Ruler.iPhoneHorizontal(192, 225, 250).value
        public static let mediaPreferredHeight: CGFloat = Ruler.iPhoneHorizontal(208, 244, 270).value

        public static let mediaMinWidth: CGFloat = 60
        public static let mediaMinHeight: CGFloat = 45

        public static let imageMaxWidth: CGFloat = Ruler.iPhoneHorizontal(230, 260, 300).value

        public static let centerXOffset: CGFloat = 4
        
        public static let bubbleCornerRadius: CGFloat = 18

        public static let imageAppearDuration: NSTimeInterval = 0.1

        public static let textAttributes:[String: NSObject] = [
            NSFontAttributeName: UIFont.chatTextFont(),
        ]
    }

    public struct FeedMedia {
        public static let backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)
    }

    public struct FeedBasicCell {
        public static let textAttributes:[String: NSObject] = [
            NSFontAttributeName: UIFont.feedMessageFont(),
        ]

        public static let skillTextAttributes:[String: NSObject] = [
            NSFontAttributeName: UIFont.feedSkillFont(),
        ]

        public static let voiceTimeLengthTextAttributes:[String: NSObject] = [
            NSFontAttributeName: UIFont.feedVoiceTimeLengthFont(),
        ]

        public static let bottomLabelsTextAttributes:[String: NSObject] = [
            NSFontAttributeName: UIFont.feedBottomLabelsFont(),
        ]
    }

    public struct FeedBiggerImageCell {
        public static let imageSize: CGSize = CGSize(width: 160, height: 160)
    }

    public struct FeedNormalImagesCell {
        public static let imageSize: CGSize = CGSize(width: 80, height: 80)
    }

    public struct SearchedFeedNormalImagesCell {
        public static let imageSize: CGSize = CGSize(width: 70, height: 70)
    }

    public struct FeedView {
        public static let textAttributes:[String: NSObject] = [
            NSFontAttributeName: UIFont.feedMessageFont(),
        ]
    }

    public struct MetaData {
        public static let audioDuration = "audio_duration"
        public static let audioSamples = "audio_samples"

        public static let imageWidth = "image_width"
        public static let imageHeight = "image_height"

        public static let videoWidth = "video_width"
        public static let videoHeight = "video_height"

        public static let thumbnailString = "thumbnail_string"
        public static let blurredThumbnailString = "blurred_thumbnail_string"

        public static let thumbnailMaxSize: CGFloat = 60
    }

    public struct Media {
        public static let imageWidth: CGFloat = 2048
        public static let imageHeight: CGFloat = 2048

        public static let miniImageWidth: CGFloat = 200
        public static let miniImageHeight: CGFloat = 200
    }

    public struct Feedback {
        public static let bottomMargin: CGFloat = Ruler.iPhoneVertical(10, 20, 40, 40).value
    }

    public struct Location {
        public static let distanceThreshold: CLLocationDistance = 500
    }

    public struct ChinaSocialNetwork {

        public struct WeChat {

            public static let appID = "wx10f099f798871364"

            public static let sessionType = "com.Catch-Inc.Yep.WeChat.Session"
            public static let sessionTitle = NSLocalizedString("WeChat Session", comment: "")
            public static let sessionImage = UIImage(named: "wechat_session")!

            public static let timelineType = "com.Catch-Inc.Yep.WeChat.Timeline"
            public static let timelineTitle = NSLocalizedString("WeChat Timeline", comment: "")
            public static let timelineImage = UIImage(named: "wechat_timeline")!
        }
    }
}

