//
//  Models.swift
//  Yep
//
//  Created by NIX on 15/3/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import RealmSwift


// 总是在这个队列里使用 Realm
let realmQueue = dispatch_queue_create("com.Yep.realmQueue", DISPATCH_QUEUE_SERIAL)


// MARK: User

// 朋友的“状态”, 注意：上线后若要调整，只能增加新状态
enum UserFriendState: Int {
    case Stranger       = 0   // 陌生人
    case IssuedRequest  = 1   // 已对其发出好友请求
    case Normal         = 2   // 正常状态的朋友
    case Blocked        = 3   // 被屏蔽
    case Me             = 4   // 自己
}

class Avatar: Object {
    dynamic var avatarURLString: String = ""
    dynamic var avatarFileName: String = ""

    var user: User? {
        let users = linkingObjects(User.self, forProperty: "avatar")
        return users.first
    }
}

class UserSkillCategory: Object {
    dynamic var skillCategoryID: String = ""
    dynamic var name: String = ""
    dynamic var localName: String = ""

    var skills: [UserSkill] {
        return linkingObjects(UserSkill.self, forProperty: "category")
    }
}

class UserSkill: Object {

    dynamic var category: UserSkillCategory?

    dynamic var skillID: String = ""
    dynamic var name: String = ""
    dynamic var localName: String = ""
    dynamic var coverURLString: String = ""

    var learningUsers: [User] {
        return linkingObjects(User.self, forProperty: "learningSkills")
    }

    var masterUsers: [User] {
        return linkingObjects(User.self, forProperty: "masterSkills")
    }
}

class User: Object {
    dynamic var userID: String = ""
    dynamic var nickname: String = ""
    dynamic var introduction: String = ""
    dynamic var avatarURLString: String = ""
    dynamic var avatar: Avatar?

    dynamic var createdAt: NSDate = NSDate()
    dynamic var lastSignInAt: NSDate = NSDate()

    dynamic var friendState: Int = UserFriendState.Stranger.rawValue
    dynamic var friendshipID: String = ""
    dynamic var isBestfriend: Bool = false
    dynamic var bestfriendIndex: Int = 0

    dynamic var longitude: Double = 0
    dynamic var latitude: Double = 0

    let learningSkills = List<UserSkill>()
    let masterSkills = List<UserSkill>()

    var messages: [Message] {
        return linkingObjects(Message.self, forProperty: "fromFriend")
    }

    var conversation: Conversation? {
        let conversations = linkingObjects(Conversation.self, forProperty: "withFriend")
        return conversations.first
    }

    var ownedGroups: [Group] {
        return linkingObjects(Group.self, forProperty: "owner")
    }

    var belongsToGroups: [Group] {
        return linkingObjects(Group.self, forProperty: "members")
    }
}

// MARK: Group

class Group: Object {
    dynamic var groupID: String = ""
    dynamic var groupName: String = ""

    dynamic var createdAt: NSDate = NSDate()

    dynamic var owner: User?
    let members = List<User>()

    var conversation: Conversation? {
        let conversations = linkingObjects(Conversation.self, forProperty: "withGroup")
        return conversations.first
    }
}

// MARK: Message

class Coordinate: Object {
    dynamic var latitude: Double = 0
    dynamic var longitude: Double = 0
}

enum MessageDownloadState: Int {
    case NoDownload     = 0 // 未下载
    case Downloading    = 1 // 下载中
    case Downloaded     = 2 // 已下载
}

enum MessageMediaType: Int, Printable {
    case Text           = 0
    case Image          = 1
    case Video          = 2
    case Audio          = 3
    case Sticker        = 4
    case Location       = 5
    case SectionDate    = 6

    var description: String {
        get {
            switch self {
            case Text:
                return "text"
            case Image:
                return "image"
            case Video:
                return "video"
            case Audio:
                return "audio"
            case Sticker:
                return "sticker"
            case Location:
                return "location"
            case SectionDate:
                return "sectionDate"
            }
        }
    }

    func mineType() -> String {
        switch self {
        case .Image:
            return "image/jpeg"
        case .Video:
            return "video/mp4"
        case .Audio:
            return "audio/m4a"
        default:
            return "" // TODO: more mineType
        }
    }
}

enum MessageSendState: Int {
    case NotSend    = 0
    case Failed     = 1
    case Successed  = 2
}

class Message: Object {
    dynamic var messageID: String = ""

    dynamic var createdAt: NSDate = NSDate()

    dynamic var mediaType: Int = MessageMediaType.Text.rawValue
    dynamic var textContent: String = ""
    dynamic var coordinate: Coordinate?

    dynamic var attachmentURLString: String = ""
    dynamic var metaData: String = ""
    dynamic var downloadState: Int = MessageDownloadState.NoDownload.rawValue
    dynamic var localAttachmentName: String = ""
    dynamic var thumbnailURLString: String = ""
    dynamic var localThumbnailName: String = ""

    dynamic var sendState: Int = MessageSendState.NotSend.rawValue
    dynamic var readed: Bool = false

    dynamic var fromFriend: User?
    dynamic var conversation: Conversation?
}

// MARK: Conversation

enum ConversationType: Int {
    case OneToOne   = 0 // 一对一对话
    case Group      = 1 // 群组对话
}

class Conversation: Object {
    dynamic var type: Int = ConversationType.OneToOne.rawValue
    dynamic var updatedAt: NSDate = NSDate()

    dynamic var withFriend: User?
    dynamic var withGroup: Group?

    var messages: [Message] {
        return linkingObjects(Message.self, forProperty: "conversation")
    }
}



// MARK: Helpers

func normalUsers() -> Results<User> {
    let realm = Realm()
    let predicate = NSPredicate(format: "friendState = %d", UserFriendState.Normal.rawValue)
    return realm.objects(User).filter(predicate)
}

func userSkillWithSkillID(skillID: String, inRealm realm: Realm) -> UserSkill? {
    let predicate = NSPredicate(format: "skillID = %@", skillID)
    return realm.objects(UserSkill).filter(predicate).first
}

func userSkillCategoryWithSkillCategoryID(skillCategoryID: String, inRealm realm: Realm) -> UserSkillCategory? {
    let predicate = NSPredicate(format: "skillCategoryID = %@", skillCategoryID)
    return realm.objects(UserSkillCategory).filter(predicate).first
}

func userWithUserID(userID: String, inRealm realm: Realm) -> User? {
    let predicate = NSPredicate(format: "userID = %@", userID)
    return realm.objects(User).filter(predicate).first
}

func groupWithGroupID(groupID: String, inRealm realm: Realm) -> Group? {
    let predicate = NSPredicate(format: "groupID = %@", groupID)
    return realm.objects(Group).filter(predicate).first
}

func messageWithMessageID(messageID: String, inRealm realm: Realm) -> Message? {
    if messageID.isEmpty {
        return nil
    }

    let predicate = NSPredicate(format: "messageID = %@", messageID)
    return realm.objects(Message).filter(predicate).first
}

func avatarWithAvatarURLString(avatarURLString: String, inRealm realm: Realm) -> Avatar? {
    let predicate = NSPredicate(format: "avatarURLString = %@", avatarURLString)
    return realm.objects(Avatar).filter(predicate).first
}

func tryGetOrCreateMeInRealm(realm: Realm) -> User? {
    if let userID = YepUserDefaults.userID.value {

        if let me = userWithUserID(userID, inRealm: realm) {
            return me

        } else {

            let me = User()

            me.userID = userID
            me.friendState = UserFriendState.Me.rawValue

            if let nickname = YepUserDefaults.nickname.value {
                me.nickname = nickname
            }

            if let avatarURLString = YepUserDefaults.avatarURLString.value {
                me.avatarURLString = avatarURLString
            }

            realm.write {
                realm.add(me)
            }

            return me
        }
    }

    return nil
}

func messagesInConversation(conversation: Conversation) -> Results<Message> {

    let predicate = NSPredicate(format: "conversation = %@", conversation)

    if let realm = conversation.realm {
        return realm.objects(Message).sorted("createdAt", ascending: true)

    } else {
        let realm = Realm()
        return realm.objects(Message).sorted("createdAt", ascending: true)
    }
}

func messagesOfConversation(conversation: Conversation, inRealm realm: Realm) -> Results<Message> {
    let predicate = NSPredicate(format: "conversation = %@", conversation)
    let messages = realm.objects(Message).sorted("createdAt", ascending: true)
    return messages
}

func tryCreateSectionDateMessageInConversation(conversation: Conversation, beforeMessage message: Message, inRealm realm: Realm, success: (Message) -> Void) {
    let messages = messagesOfConversation(conversation, inRealm: realm)
    if messages.count > 1 {
        let prevMessage = messages[messages.count - 2]
        if message.createdAt.timeIntervalSinceDate(prevMessage.createdAt) > 30 { // TODO: Time Section

            // insert a new SectionDate Message
            let newSectionDateMessage = Message()
            newSectionDateMessage.conversation = conversation
            newSectionDateMessage.mediaType = MessageMediaType.SectionDate.rawValue
            newSectionDateMessage.createdAt = message.createdAt.dateByAddingTimeInterval(-1) // 比新消息早一秒

            success(newSectionDateMessage)
        }
    }
}

func nameOfConversation(conversation: Conversation) -> String? {
    if conversation.type == ConversationType.OneToOne.rawValue {
        if let withFriend = conversation.withFriend {
            return withFriend.nickname
        }

    } else if conversation.type == ConversationType.Group.rawValue {
        if let withGroup = conversation.withGroup {
            return withGroup.groupName
        }
    }

    return nil
}

func lastChatDateOfConversation(conversation: Conversation) -> NSDate? {
    let messages = messagesInConversation(conversation)

    return messages.last?.createdAt
}

func lastSignDateOfConversation(conversation: Conversation) -> NSDate? {
    let messages = messagesInConversation(conversation)

    if let
        lastMessage = messages.last,
        user = lastMessage.fromFriend {
            return user.lastSignInAt
    }

    return nil
}


