//
//  Config.swift
//  Yep
//
//  Created by NIX on 16/5/24.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

final public class Config {

    public static var updatedAccessTokenAction: (() -> Void)?
    public static var updatedPusherIDAction: ((pusherID: String) -> Void)?

    public static var sentMessageSoundEffectAction: (() -> Void)?

    public static var timeAgoAction: ((date: NSDate) -> String)?

    public static var isAppActive: (() -> Bool)?

    public static let appGroupID: String = "group.Catch-Inc.Yep"

    public class func clientType() -> Int {
        // TODO: clientType

        #if DEBUG
            return 2
        #else
            return 0
        #endif
    }

    public class func avatarCompressionQuality() -> CGFloat {
        return 0.7
    }

    public struct Notification {
        public static let markAsReaded = "YepConfig.Notification.markAsReaded"
        public static let changedConversation = "YepConfig.Notification.changedConversation"
        public static let changedFeedConversation = "YepConfig.Notification.changedFeedConversation"
        public static let newMessages = "YepConfig.Notification.newMessages"
        public static let deletedMessages = "YepConfig.Notification.deletedMessages"
        public static let updatedUser = "YepConfig.Notification.updatedUser"
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
        public static let imageWidth: CGFloat = 1024
        public static let imageHeight: CGFloat = 1024

        public static let miniImageWidth: CGFloat = 200
        public static let miniImageHeight: CGFloat = 200
    }
}

