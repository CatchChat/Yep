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

class UserSocialAccountProvider: Object {
    dynamic var name: String = ""
    dynamic var enabled: Bool = false
}

class User: Object {
    dynamic var userID: String = ""
    dynamic var nickname: String = ""
    dynamic var introduction: String = ""
    dynamic var avatarURLString: String = ""
    dynamic var avatar: Avatar?
    dynamic var badge: String = ""

    dynamic var createdUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970
    dynamic var lastSignInUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970

    dynamic var friendState: Int = UserFriendState.Stranger.rawValue
    dynamic var friendshipID: String = ""
    dynamic var isBestfriend: Bool = false
    dynamic var bestfriendIndex: Int = 0

    dynamic var longitude: Double = 0
    dynamic var latitude: Double = 0

    dynamic var notificationEnabled: Bool = true
    dynamic var blocked: Bool = false

    let learningSkills = List<UserSkill>()
    let masterSkills = List<UserSkill>()
    let socialAccountProviders = List<UserSocialAccountProvider>()

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

    dynamic var createdUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970

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

enum MessageSendState: Int, Printable {
    case NotSend    = 0
    case Failed     = 1
    case Successed  = 2
    case Read       = 3
    
    var description: String {
        get {
            switch self {
            case NotSend:
                return "NotSend"
            case Failed:
                return "Failed"
            case Successed:
                return "Sent"
            case Read:
                return "Read"
            }
        }
    }
}

class MediaMetaData: Object {
    dynamic var data: NSData = NSData()

    var string: String? {
        return NSString(data: data, encoding: NSUTF8StringEncoding) as? String
    }
}

class Message: Object {
    dynamic var messageID: String = ""

    dynamic var createdUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970
    dynamic var updatedUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970
    dynamic var arrivalUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970

    dynamic var mediaType: Int = MessageMediaType.Text.rawValue
    dynamic var textContent: String = ""
    dynamic var coordinate: Coordinate?

    dynamic var attachmentURLString: String = ""
    dynamic var localAttachmentName: String = ""
    dynamic var thumbnailURLString: String = ""
    dynamic var localThumbnailName: String = ""

    dynamic var downloadState: Int = MessageDownloadState.NoDownload.rawValue

    dynamic var mediaMetaData: MediaMetaData?

    dynamic var sendState: Int = MessageSendState.NotSend.rawValue
    dynamic var readed: Bool = false

    dynamic var fromFriend: User?
    dynamic var conversation: Conversation?
}

class Draft: Object {
    dynamic var messageToolbarState: Int = MessageToolbarState.Default.rawValue

    dynamic var text: String = ""
}

// MARK: Conversation

enum ConversationType: Int {
    case OneToOne   = 0 // 一对一对话
    case Group      = 1 // 群组对话

    var nameForServer: String {
        switch self {
        case .OneToOne:
            return "User"
        case .Group:
            return "Circle"
        }
    }
}

class Conversation: Object {
    dynamic var type: Int = ConversationType.OneToOne.rawValue
    dynamic var updatedUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970

    dynamic var withFriend: User?
    dynamic var withGroup: Group?

    dynamic var draft: Draft?

    var messages: [Message] {
        return linkingObjects(Message.self, forProperty: "conversation")
    }
}



// MARK: Helpers

func normalFriends() -> Results<User> {
    let realm = Realm()
    let predicate = NSPredicate(format: "friendState = %d", UserFriendState.Normal.rawValue)
    return realm.objects(User).filter(predicate)
}

func normalUsers() -> Results<User> {
    let realm = Realm()
    let predicate = NSPredicate(format: "friendState = %d OR friendState = %d", UserFriendState.Normal.rawValue, UserFriendState.Me.rawValue)
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

func userWithAvatarURLString(avatarURLString: String, inRealm realm: Realm) -> User? {
    let predicate = NSPredicate(format: "avatarURLString = %@", avatarURLString)
    return realm.objects(User).filter(predicate).first
}

func groupWithGroupID(groupID: String, inRealm realm: Realm) -> Group? {
    let predicate = NSPredicate(format: "groupID = %@", groupID)
    return realm.objects(Group).filter(predicate).first
}

func countOfUnreadMessagesInRealm(realm: Realm) -> Int {
    let predicate = NSPredicate(format: "readed = false AND fromFriend.friendState != %d", UserFriendState.Me.rawValue)
    return realm.objects(Message).filter(predicate).count
}

func countOfUnreadMessagesInConversation(conversation: Conversation) -> Int {
    return conversation.messages.filter({ message in
        if let fromFriend = message.fromFriend {
            return (message.readed == false) && (fromFriend.friendState != UserFriendState.Me.rawValue)
        } else {
            return false
        }
    }).count
}

func messageWithMessageID(messageID: String, inRealm realm: Realm) -> Message? {
    if messageID.isEmpty {
        return nil
    }

    let predicate = NSPredicate(format: "messageID = %@", messageID)
    return realm.objects(Message).filter(predicate).first
}

func deleteMediaFilesOfMessage(message: Message) {

    switch message.mediaType {

    case MessageMediaType.Image.rawValue:
        NSFileManager.removeMessageImageFileWithName(message.localAttachmentName)

    case MessageMediaType.Video.rawValue:
        NSFileManager.removeMessageVideoFilesWithName(message.localAttachmentName, thumbnailName: message.localThumbnailName)

    case MessageMediaType.Audio.rawValue:
        NSFileManager.removeMessageAudioFileWithName(message.localAttachmentName)

    default:
        break // TODO: if have other message media need to delete
    }
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

func mediaMetaDataFromString(metaDataString: String, inRealm realm: Realm) -> MediaMetaData? {

    if let data = metaDataString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
        let mediaMetaData = MediaMetaData()
        mediaMetaData.data = data

        realm.add(mediaMetaData)

        return mediaMetaData
    }

    return nil
}

func messagesInConversation(conversation: Conversation) -> Results<Message> {

    let predicate = NSPredicate(format: "conversation = %@", argumentArray: [conversation])

    if let realm = conversation.realm {
        return realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)

    } else {
        let realm = Realm()
        return realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
    }
}

func messagesOfConversationByMe(conversation: Conversation, inRealm realm: Realm) -> Results<Message> {
    let predicate = NSPredicate(format: "conversation = %@ AND fromFriend.friendState == %d", argumentArray: [conversation, UserFriendState.Me.rawValue])
    let messages = realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
    return messages
}

func messagesUnreadSentByMe(inRealm realm: Realm) -> Results<Message> {
    let predicate = NSPredicate(format: "fromFriend.friendState == %d AND readed = 0 AND sendState == %d", argumentArray: [ UserFriendState.Me.rawValue, MessageSendState.Successed.rawValue])
    let messages = realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
    return messages
}

func messagesOfConversation(conversation: Conversation, inRealm realm: Realm) -> Results<Message> {
    let predicate = NSPredicate(format: "conversation = %@", conversation)
    let messages = realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
    return messages
}

func unReadMessagesOfConversation(conversation: Conversation, inRealm realm: Realm) -> Results<Message> {
    let predicate = NSPredicate(format: "conversation = %@ AND readed = 0", conversation)
    let messages = realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
    return messages
}

func tryCreateSectionDateMessageInConversation(conversation: Conversation, beforeMessage message: Message, inRealm realm: Realm, success: (Message) -> Void) {

    let messages = messagesOfConversation(conversation, inRealm: realm)

    if messages.count > 1 {

        if let prevMessage = messages[safe: (messages.count - 2)] {

            if message.createdUnixTime - prevMessage.createdUnixTime > 180 { // TODO: Time Section

                // insert a new SectionDate Message
                let newSectionDateMessage = Message()
                newSectionDateMessage.conversation = conversation
                newSectionDateMessage.mediaType = MessageMediaType.SectionDate.rawValue
                newSectionDateMessage.createdUnixTime = message.createdUnixTime - 0.001 // 比新消息早一点点即可
                newSectionDateMessage.arrivalUnixTime = message.arrivalUnixTime - 0.001 // 比新消息早一点点即可
                newSectionDateMessage.messageID = "sectionDate-\(newSectionDateMessage.createdUnixTime)"

                success(newSectionDateMessage)
            }
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

    if let lastMessage = messages.last {
        return NSDate(timeIntervalSince1970: lastMessage.createdUnixTime)
    }
    
    return nil
}

func lastSignDateOfConversation(conversation: Conversation) -> NSDate? {
    let messages = messagesInConversation(conversation)

    if let
        lastMessage = messages.last,
        user = lastMessage.fromFriend {
            return NSDate(timeIntervalSince1970: user.lastSignInUnixTime)
    }

    return nil
}

func blurredThumbnailImageOfMessage(message: Message) -> UIImage? {

    if let mediaMetaData = message.mediaMetaData {
        if let metaDataInfo = decodeJSON(mediaMetaData.data) {
            if let blurredThumbnailString = metaDataInfo[YepConfig.MetaData.blurredThumbnailString] as? String {
                if let data = NSData(base64EncodedString: blurredThumbnailString, options: NSDataBase64DecodingOptions(0)) {
                    return UIImage(data: data)
                }
            }
        }
    }

    return nil
}

func audioMetaOfMessage(message: Message) -> (duration: Double, samples: [CGFloat])? {

    if let mediaMetaData = message.mediaMetaData {
        if let metaDataInfo = decodeJSON(mediaMetaData.data) {
            if let
                duration = metaDataInfo[YepConfig.MetaData.audioDuration] as? Double,
                samples = metaDataInfo[YepConfig.MetaData.audioSamples] as? [CGFloat] {
                    return (duration, samples)
            }
        }
    }

    return nil
}

func imageMetaOfMessage(message: Message) -> (width: CGFloat, height: CGFloat)? {

    if let mediaMetaData = message.mediaMetaData {
        if let metaDataInfo = decodeJSON(mediaMetaData.data) {
            if let
                width = metaDataInfo[YepConfig.MetaData.imageWidth] as? CGFloat,
                height = metaDataInfo[YepConfig.MetaData.imageHeight] as? CGFloat {
                    return (width, height)
            }
        }
    }

    return nil
}

func videoMetaOfMessage(message: Message) -> (width: CGFloat, height: CGFloat)? {

    if let mediaMetaData = message.mediaMetaData {
        if let metaDataInfo = decodeJSON(mediaMetaData.data) {
            if let
                width = metaDataInfo[YepConfig.MetaData.videoWidth] as? CGFloat,
                height = metaDataInfo[YepConfig.MetaData.videoHeight] as? CGFloat {
                    return (width, height)
            }
        }
    }

    return nil
}

