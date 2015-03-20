//
//  Models.swift
//  Yep
//
//  Created by NIX on 15/3/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Realm

// MARK: User

// 朋友的“状态”, 注意：上线后若要调整，只能增加新状态
enum UserFriendState: Int {
    case Stranger       = 0   // 陌生人
    case IssuedRequest  = 1   // 已对其发出好友请求
    case Normal         = 2   // 正常状态的朋友
    case Blocked        = 3   // 被屏蔽
    case Me             = 4   // 自己
}

class User: RLMObject {
    dynamic var userID: String = ""
    dynamic var nickname: String = ""

    dynamic var createdAt: NSDate = NSDate()

    dynamic var friendState: Int = UserFriendState.Stranger.rawValue
    dynamic var friendshipID: String?
    dynamic var isBestfriend: Bool = false
    dynamic var bestfriendIndex: Int = 0

    dynamic var messages = RLMArray(objectClassName: Message.className())

    dynamic var conversation: Conversation?

    dynamic var ownedGroups = RLMArray(objectClassName: Group.className())
    dynamic var belongsToGroups = RLMArray(objectClassName: Group.className())
}

// MARK: Group

class Group: RLMObject {
    dynamic var groupID: String = ""
    dynamic var groupName: String = ""

    dynamic var createdAt: NSDate = NSDate()

    dynamic var owner: User?
    dynamic var members = RLMArray(objectClassName: User.className())

    dynamic var conversation: Conversation?
}

// MARK: Message

class Coordinate: RLMObject {
    dynamic var latitude: Double = 0
    dynamic var longitude: Double = 0
}

enum MessageDownloadState: Int {
    case NoDownload     = 0 // 未下载
    case Downloading    = 1 // 下载中
    case Downloaded     = 2 // 已下载
}

enum MessageMediaType: String {
    case Text   = "text"
    case Image  = "image"
    case Video  = "video"
    case Audio  = "audio"
}

class Message: RLMObject {
    dynamic var messageID: String = ""

    dynamic var createdAt: NSDate = NSDate()

    dynamic var mediaType: String = ""
    dynamic var textContent: String = ""
    dynamic var coordinate: Coordinate?

    dynamic var attachment: String?
    dynamic var downloadState: Int = MessageDownloadState.NoDownload.rawValue
    dynamic var localAttachmentName: String?
    dynamic var thumbnail: String?
    dynamic var localThumbnailName: String?

    dynamic var readed: Bool = false

    dynamic var fromFriend: User?
    dynamic var conversation: Conversation?
}

// MARK: Conversation

enum ConversationType: Int {
    case OneToOne   = 0 // 一对一对话
    case Group      = 1 // 群组对话
}

class Conversation: RLMObject {
    dynamic var type: Int = ConversationType.OneToOne.rawValue
    dynamic var updatedAt: NSDate = NSDate()

    dynamic var withFriend: User?
    dynamic var withGroup: Group?
    dynamic var messages = RLMArray(objectClassName: Message.className())
}

