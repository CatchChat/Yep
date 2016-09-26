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
    public static var updatedPusherIDAction: ((_ pusherID: String) -> Void)?

    public static var sentMessageSoundEffectAction: (() -> Void)?

    public static var timeAgoAction: ((_ date: Date) -> String)?

    public static var isAppActive: (() -> Bool)?

    public static let appGroupID: String = "group.Catch-Inc.Yep"

    public static var clientType: Int {
        #if DEBUG
            return 2
        #else
            return 0
        #endif
    }

    public static var avatarCompressionQuality: CGFloat = 0.7

    public struct NotificationName {
        public static let markAsReaded = Notification.Name(rawValue: "YepConfig.Notification.markAsReaded"
        public static let changedConversation = Notification.Name(rawValue: "YepConfig.Notification.changedConversation")
        public static let changedFeedConversation = Notification.Name(rawValue: "YepConfig.Notification.changedFeedConversation")
        public static let newMessages = Notification.Name(rawValue: "YepConfig.Notification.newMessages")
        public static let deletedMessages = Notification.Name(rawValue: "YepConfig.Notification.deletedMessages")
        public static let updatedUser = Notification.Name(rawValue: "YepConfig.Notification.updatedUser")
    }
    
    public struct Message {
        // 注意：确保 localNewerTimeInterval > sectionOlderTimeInterval
        public static let localNewerTimeInterval: TimeInterval = 0.001
        public static let sectionOlderTimeInterval: TimeInterval = 0.0005

        public struct NotificationName {
            public static let MessageStateChanged = Notification.Name(rawValue: "MessageStateChangedNotification")
            public static let MessageBatchMarkAsRead = Notification.Name(rawValue: "MessageBatchMarkAsReadNotification")
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

    struct SocialWork {
        static let syncCountMax: Int = 5
    }
}

