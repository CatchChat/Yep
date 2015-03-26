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

class Avatar: RLMObject {
    dynamic var avatarURLString: String = ""
    dynamic var imageData: NSData = NSData()

    var user: User? {
        let users = linkingObjectsOfClass("User", forProperty: "avatar") as! [User]
        return users.first
    }
}

class User: RLMObject {
    dynamic var userID: String = ""
    dynamic var nickname: String = ""
    dynamic var avatarURLString: String = ""
    dynamic var avatar: Avatar?

    dynamic var createdAt: NSDate = NSDate()

    dynamic var friendState: Int = UserFriendState.Stranger.rawValue
    dynamic var friendshipID: String = ""
    dynamic var isBestfriend: Bool = false
    dynamic var bestfriendIndex: Int = 0

    var messages: [Message] {
        return linkingObjectsOfClass("Message", forProperty: "fromFriend") as! [Message]
    }

    var conversation: Conversation? {
        let conversations = linkingObjectsOfClass("Conversation", forProperty: "withFriend") as! [Conversation]
        return conversations.first
    }

    var ownedGroups: [Group] {
        return linkingObjectsOfClass("Group", forProperty: "owner") as! [Group]
    }

    var belongsToGroups: [Group] {
        return linkingObjectsOfClass("Group", forProperty: "members") as! [Group]
    }
}

// MARK: Group

class Group: RLMObject {
    dynamic var groupID: String = ""
    dynamic var groupName: String = ""

    dynamic var createdAt: NSDate = NSDate()

    dynamic var owner: User?
    dynamic var members = RLMArray(objectClassName: User.className())

    var conversation: Conversation? {
        let conversations = linkingObjectsOfClass("Conversation", forProperty: "withGroup") as! [Conversation]
        return conversations.first
    }
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

enum MessageMediaType: Int {
    case Text   = 0
    case Image  = 1
    case Video  = 2
    case Audio  = 3
}

class Message: RLMObject {
    dynamic var messageID: String = ""

    dynamic var createdAt: NSDate = NSDate()

    dynamic var mediaType: Int = MessageMediaType.Text.rawValue
    dynamic var textContent: String = ""
    dynamic var coordinate: Coordinate?

    dynamic var attachmentURLString: String = ""
    dynamic var downloadState: Int = MessageDownloadState.NoDownload.rawValue
    dynamic var localAttachmentName: String = ""
    dynamic var thumbnailURLString: String = ""
    dynamic var localThumbnailName: String = ""

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

    var messages: [Message] {
        return linkingObjectsOfClass("Message", forProperty: "conversation") as! [Message]
    }
}



// MARK: Helpers

func userWithUserID(userID: String) -> User? {
    let predicate = NSPredicate(format: "userID = %@", userID)
    return User.objectsWithPredicate(predicate).firstObject() as? User
}

func groupWithGroupID(groupID: String) -> Group? {
    let predicate = NSPredicate(format: "groupID = %@", groupID)
    return Group.objectsWithPredicate(predicate).firstObject() as? Group
}

func tryGetOrCreateMe() -> User? {
    if let userID = YepUserDefaults.userID() {
        if let me = userWithUserID(userID) {
            return me

        } else {
            let realm = RLMRealm.defaultRealm()

            realm.beginWriteTransaction()
            
            let me = User()

            me.userID = userID
            me.friendState = UserFriendState.Me.rawValue

            if let nickname = YepUserDefaults.nickname() {
                me.nickname = nickname
            }

            if let avatarURLString = YepUserDefaults.avatarURLString() {
                me.avatarURLString = avatarURLString
            }

            realm.addObject(me)

            realm.commitWriteTransaction()

            return me
        }
    }

    return nil
}

func messagesInConversation(conversation: Conversation) -> RLMResults {
    let predicate = NSPredicate(format: "conversation = %@", conversation)
    let messages = Message.objectsWithPredicate(predicate).sortedResultsUsingProperty("createdAt", ascending: true)
    return messages
}

