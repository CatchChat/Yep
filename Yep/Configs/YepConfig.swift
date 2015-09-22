//
//  YepConfig.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler
import CoreLocation

class YepConfig {

    static let appGroupID: String = "group.Catch-Inc.Yep"
    
    static let minMessageTextLabelWidth: CGFloat = 20.0
    
    static let minMessageSampleViewWidth: CGFloat = 25.0
    
    static let skillHomeHeaderViewHeight: CGFloat = 250.0
    
    static let skillHomeHeaderButtonHeight: CGFloat = 50.0
    
    class func clientType() -> Int {
        // TODO: clientType
        
        #if DEBUG
            return 2
        #else
            return 0
        #endif
    }

    static let termsURLString = "http://privacy.soyep.com"
    static let appURLString = "itms-apps://itunes.apple.com/app/id" + "983891256"

    static let forcedHideActivityIndicatorTimeInterval: NSTimeInterval = 30

    static let dismissKeyboardDelayTimeInterval : NSTimeInterval = 0.45

    struct Message {
        // 注意：确保 localNewerTimeInterval > sectionOlderTimeInterval
        static let localNewerTimeInterval: NSTimeInterval = 0.001
        static let sectionOlderTimeInterval: NSTimeInterval = 0.0005
    }

    class func getScreenRect() -> CGRect {
        return UIScreen.mainScreen().bounds
    }

    class func verifyCodeLength() -> Int {
        return 4
    }

    class func callMeInSeconds() -> Int {
        return 60
    }

    class func avatarMaxSize() -> CGSize {
        return CGSize(width: 600, height: 600)
    }

    class func chatCellAvatarSize() -> CGFloat {
        return 40.0
    }

    class func chatCellGapBetweenTextContentLabelAndAvatar() -> CGFloat {
        return 23
    }

    class func chatCellGapBetweenWallAndAvatar() -> CGFloat {
        return 15
    }

    class func chatTextGapBetweenWallAndContentLabel() -> CGFloat {
        return 50
    }

    class func avatarCompressionQuality() -> CGFloat {
        return 0.7
    }

    class func messageImageCompressionQuality() -> CGFloat {
        return 0.8
    }

    class func audioSampleWidth() -> CGFloat {
        return 2
    }

    class func audioSampleGap() -> CGFloat {
        return 1
    }

    class func editProfileAvatarSize() -> CGFloat {
        return 100
    }

    struct AudioRecord {
        static let shortestDuration: NSTimeInterval = 1.0
        static let longestDuration: NSTimeInterval = 60
    }

    struct Profile {
        static let leftEdgeInset: CGFloat = Ruler.iPhoneHorizontal(20, 38, 40).value
        static let rightEdgeInset: CGFloat = leftEdgeInset
        static let introductionLabelFont = UIFont(name: "Helvetica-Light", size: 14)!
    }
    
    struct Settings {
        static let userCellAvatarSize: CGFloat = 80

        static let introFont = UIFont(name: "Helvetica-Light", size: 12)!
        static let introInset: CGFloat = 20 + userCellAvatarSize + 20 + 10 + 11 + 20
    }

    struct EditProfile {
        static let introFont = UIFont(name: "Helvetica-Light", size: 15)!
        static let introInset: CGFloat = 20 + 20
    }

    struct SocialWorkGithub {
        struct Repo {
            static let leftEdgeInset: CGFloat = Ruler.iPhoneHorizontal(20, 40, 40).value
            static let rightEdgeInset: CGFloat = leftEdgeInset
        }
    }

    struct ContactsCell {
        static let separatorInset = UIEdgeInsets(top: 0, left: 90, bottom: 0, right: 0) 
    }

    struct ConversationCell {
        static let avatarSize: CGFloat = 60
    }

    struct ChatCell {

        static let magicWidth: CGFloat = 4

        static let lineSpacing: CGFloat = 5

        static let minTextWidth: CGFloat = 17
        
        static let gapBetweenDotImageViewAndBubble: CGFloat = 5

        static let gapBetweenAvatarImageViewAndBubble: CGFloat = 5

        static let playImageViewXOffset: CGFloat = 3

        static let locationNameLabelHeight: CGFloat = 20

        static let mediaPreferredWidth: CGFloat = Ruler.iPhoneHorizontal(192, 225, 250).value
        static let mediaPreferredHeight: CGFloat = Ruler.iPhoneHorizontal(208, 244, 270).value

        static let mediaMinWidth: CGFloat = 60
        static let mediaMinHeight: CGFloat = 30

        static let centerXOffset: CGFloat = 4

        static let imageAppearDuration: NSTimeInterval = 0.1

        static let textAttributes:[String: NSObject] = [
            NSFontAttributeName: UIFont.chatTextFont(),
        ]
//        static let textAttributes: [String: NSObject] = [
//            NSFontAttributeName: UIFont.chatTextFont(),
//            NSKernAttributeName: 0.5,
//            NSParagraphStyleAttributeName: NSParagraphStyle.chatTextParagraphStyle(),
//        ]
    }

    struct MetaData {
        static let audioDuration = "audio_duration"
        static let audioSamples = "audio_samples"

        static let imageWidth = "image_width"
        static let imageHeight = "image_height"

        static let videoWidth = "video_width"
        static let videoHeight = "video_height"

        static let blurredThumbnailString = "blurred_thumbnail_string"

        static let thumbnailMaxSize: CGFloat = 100
    }

    struct Media {
        static let imageWidth: CGFloat = 1024
        static let imageHeight: CGFloat = 1024
    }

    struct Feedback {
        static let bottomMargin: CGFloat = Ruler.iPhoneVertical(10, 20, 40, 40).value
    }

    struct Location {
        static let distanceThreshold: CLLocationDistance = 500
    }

    struct ChinaSocialNetwork {

        struct WeChat {

            static let appID = "wx10f099f798871364"

            static let sessionType = "com.Catch-Inc.Yep.WeChat.Session"
            static let sessionTitle = NSLocalizedString("WeChat Session", comment: "")
            static let sessionImage = UIImage(named: "wechat_session")!

            static let timelineType = "com.Catch-Inc.Yep.WeChat.Timeline"
            static let timelineTitle = NSLocalizedString("WeChat Timeline", comment: "")
            static let timelineImage = UIImage(named: "wechat_timeline")!
        }
    }

}

