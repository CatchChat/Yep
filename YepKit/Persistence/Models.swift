//
//  Models.swift
//  Yep
//
//  Created by NIX on 15/3/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import MapKit
import YepNetworking
import RealmSwift

// 总是在这个队列里使用 Realm
//let realmQueue = dispatch_queue_create("com.Yep.realmQueue", DISPATCH_QUEUE_SERIAL)
public let realmQueue = dispatch_queue_create("com.Yep.realmQueue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0))

// MARK: User

// 朋友的“状态”, 注意：上线后若要调整，只能增加新状态
public enum UserFriendState: Int {
    case Stranger       = 0   // 陌生人
    case IssuedRequest  = 1   // 已对其发出好友请求
    case Normal         = 2   // 正常状态的朋友
    case Blocked        = 3   // 被屏蔽
    case Me             = 4   // 自己
    case Yep            = 5   // Yep官方账号
}

public class Avatar: Object {
    public dynamic var avatarURLString: String = ""
    public dynamic var avatarFileName: String = ""

    public dynamic var roundMini: NSData = NSData() // 60
    public dynamic var roundNano: NSData = NSData() // 40

    let users = LinkingObjects(fromType: User.self, property: "avatar")
    public var user: User? {
        return users.first
    }
}

public class UserSkillCategory: Object {
    public dynamic var skillCategoryID: String = ""
    public dynamic var name: String = ""
    public dynamic var localName: String = ""

    public let skills = LinkingObjects(fromType: UserSkill.self, property: "category")
}

public class UserSkill: Object {

    public dynamic var category: UserSkillCategory?

    var skillCategory: SkillCellSkill.Category? {
        if let category = category {
            return SkillCellSkill.Category(rawValue: category.name)
        }
        return nil
    }

    public dynamic var skillID: String = ""
    public dynamic var name: String = ""
    public dynamic var localName: String = ""
    public dynamic var coverURLString: String = ""

    public let learningUsers = LinkingObjects(fromType: User.self, property: "learningSkills")
    public let masterUsers = LinkingObjects(fromType: User.self, property: "masterSkills")
}

public class UserSocialAccountProvider: Object {
    public dynamic var name: String = ""
    public dynamic var enabled: Bool = false
}

public class UserDoNotDisturb: Object {
    public dynamic var isOn: Bool = false
    public dynamic var fromHour: Int = 22
    public dynamic var fromMinute: Int = 0
    public dynamic var toHour: Int = 7
    public dynamic var toMinute: Int = 30

    public var hourOffset: Int {
        let localTimeZone = NSTimeZone.localTimeZone()
        let totalSecondsOffset = localTimeZone.secondsFromGMT

        let hourOffset = totalSecondsOffset / (60 * 60)

        return hourOffset
    }

    public var minuteOffset: Int {
        let localTimeZone = NSTimeZone.localTimeZone()
        let totalSecondsOffset = localTimeZone.secondsFromGMT

        let hourOffset = totalSecondsOffset / (60 * 60)
        let minuteOffset = (totalSecondsOffset - hourOffset * (60 * 60)) / 60

        return minuteOffset
    }

    public func serverStringWithHour(hour: Int, minute: Int) -> String {
        if minute - minuteOffset > 0 {
            return String(format: "%02d:%02d", (hour - hourOffset) % 24, (minute - minuteOffset) % 60)
        } else {
            return String(format: "%02d:%02d", (hour - hourOffset - 1) % 24, ((minute + 60) - minuteOffset) % 60)
        }
    }

    public var serverFromString: String {
        return serverStringWithHour(fromHour, minute: fromMinute)
    }

    public var serverToString: String {
        return serverStringWithHour(toHour, minute: toMinute)
    }

    public var localFromString: String {
        return String(format: "%02d:%02d", fromHour, fromMinute)
    }

    public var localToString: String {
        return String(format: "%02d:%02d", toHour, toMinute)
    }
}

public class User: Object {
    public dynamic var userID: String = ""
    public dynamic var username: String = ""
    public dynamic var nickname: String = ""
    public dynamic var introduction: String = ""
    public dynamic var avatarURLString: String = ""
    public dynamic var avatar: Avatar?
    public dynamic var badge: String = ""
    public dynamic var blogURLString: String = ""
    public dynamic var blogTitle: String = ""

    public override class func indexedProperties() -> [String] {
        return ["userID"]
    }

    public dynamic var createdUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970
    public dynamic var lastSignInUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970

    public dynamic var friendState: Int = UserFriendState.Stranger.rawValue
    public dynamic var friendshipID: String = ""
    public dynamic var isBestfriend: Bool = false
    public dynamic var bestfriendIndex: Int = 0

    public var canShowProfile: Bool {
        return friendState != UserFriendState.Yep.rawValue
    }

    public dynamic var longitude: Double = 0
    public dynamic var latitude: Double = 0

    public dynamic var notificationEnabled: Bool = true
    public dynamic var blocked: Bool = false

    public dynamic var doNotDisturb: UserDoNotDisturb?

    public var learningSkills = List<UserSkill>()
    public var masterSkills = List<UserSkill>()
    public var socialAccountProviders = List<UserSocialAccountProvider>()

    public let messages = LinkingObjects(fromType: Message.self, property: "fromFriend")

    let conversations = LinkingObjects(fromType: Conversation.self, property: "withFriend")
    public var conversation: Conversation? {
        return conversations.first
    }

    public let ownedGroups = LinkingObjects(fromType: Group.self, property: "owner")
    public let belongsToGroups = LinkingObjects(fromType: Group.self, property: "members")
    public let createdFeeds = LinkingObjects(fromType: Feed.self, property: "creator")

    public var isMe: Bool {
        if let myUserID = YepUserDefaults.userID.value {
            return userID == myUserID
        }
        
        return false
    }

    public var mentionedUsername: String? {
        if username.isEmpty {
            return nil
        } else {
            return "@\(username)"
        }
    }

    public var compositedName: String {
        if username.isEmpty {
            return nickname
        } else {
            return "\(nickname) @\(username)"
        }
    }

    // 级联删除关联的数据对象

    public func cascadeDeleteInRealm(realm: Realm) {

        if let avatar = avatar {

            if !avatar.avatarFileName.isEmpty {
                NSFileManager.deleteAvatarImageWithName(avatar.avatarFileName)
            }

            realm.delete(avatar)
        }

        if let doNotDisturb = doNotDisturb {
            realm.delete(doNotDisturb)
        }

        socialAccountProviders.forEach({
            realm.delete($0)
        })

        realm.delete(self)
    }
}

// MARK: Group

// Group 类型，注意：上线后若要调整，只能增加新状态
public enum GroupType: Int {
    case Public     = 0
    case Private    = 1
}

public class Group: Object {
    public dynamic var groupID: String = ""
    public dynamic var groupName: String = ""
    public dynamic var notificationEnabled: Bool = true
    public dynamic var createdUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970

    public dynamic var owner: User?
    public var members = List<User>()

    public dynamic var groupType: Int = GroupType.Private.rawValue

    public dynamic var withFeed: Feed?

    public dynamic var includeMe: Bool = false

    let conversations = LinkingObjects(fromType: Conversation.self, property: "withGroup")
    public var conversation: Conversation? {
        return conversations.first
    }

    // 级联删除关联的数据对象

    public func cascadeDeleteInRealm(realm: Realm) {

        withFeed?.cascadeDeleteInRealm(realm)

        if let conversation = conversation {
            realm.delete(conversation)

            SafeDispatch.async {
                NSNotificationCenter.defaultCenter().postNotificationName(Config.Notification.changedConversation, object: nil)
            }
        }

        realm.delete(self)
    }
}

// MARK: Message

public class Coordinate: Object {
    public dynamic var latitude: Double = 0    // 合法范围 (-90, 90)
    public dynamic var longitude: Double = 0   // 合法范围 (-180, 180)

    // NOTICE: always use safe version property
    
    public var safeLatitude: Double {
        return abs(latitude) > 90 ? 0 : latitude
    }
    public var safeLongitude: Double {
        return abs(longitude) > 180 ? 0 : longitude
    }
    public var locationCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: safeLatitude, longitude: safeLongitude)
    }

    public func safeConfigureWithLatitude(latitude: Double, longitude: Double) {
        self.latitude = abs(latitude) > 90 ? 0 : latitude
        self.longitude = abs(longitude) > 180 ? 0 : longitude
    }
}

public enum MessageDownloadState: Int {
    case NoDownload     = 0 // 未下载
    case Downloading    = 1 // 下载中
    case Downloaded     = 2 // 已下载
}

public enum MessageMediaType: Int, CustomStringConvertible {
    case Text           = 0
    case Image          = 1
    case Video          = 2
    case Audio          = 3
    case Sticker        = 4
    case Location       = 5
    case SectionDate    = 6
    case SocialWork     = 7
    case ShareFeed      = 8
    
    public var description: String {
        switch self {
        case .Text:
            return "text"
        case .Image:
            return "image"
        case .Video:
            return "video"
        case .Audio:
            return "audio"
        case .Sticker:
            return "sticker"
        case .Location:
            return "location"
        case .SectionDate:
            return "sectionDate"
        case .SocialWork:
            return "socialWork"
        case .ShareFeed:
            return "shareFeed"
        }
    }

    public var fileExtension: FileExtension? {
        switch self {
        case .Image:
            return .JPEG
        case .Video:
            return .MP4
        case .Audio:
            return .M4A
        default:
            return nil // TODO: more
        }
    }

    public var placeholder: String? {
        switch self {
        case .Text:
            return nil
        case .Image:
            return NSLocalizedString("placeholder.image", comment: "")
        case .Video:
            return NSLocalizedString("placeholder.video", comment: "")
        case .Audio:
            return NSLocalizedString("placeholder.audio", comment: "")
        case .Sticker:
            return NSLocalizedString("placeholder.sticker", comment: "")
        case .Location:
            return NSLocalizedString("placeholder.location", comment: "")
        case .SocialWork:
            return NSLocalizedString("placeholder.socialWork", comment: "")
        default:
            return NSLocalizedString("placeholder.all_messages_read", comment: "")
        }
    }
}

public enum MessageSendState: Int, CustomStringConvertible {
    case NotSend    = 0
    case Failed     = 1
    case Successed  = 2
    case Read       = 3
    
    public var description: String {
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

public class MediaMetaData: Object {
    public dynamic var data: NSData = NSData()

    public var string: String? {
        return NSString(data: data, encoding: NSUTF8StringEncoding) as? String
    }
}

public class SocialWorkGithubRepo: Object {
    public dynamic var repoID: Int = 0
    public dynamic var name: String = ""
    public dynamic var fullName: String = ""
    public dynamic var URLString: String = ""
    public dynamic var repoDescription: String = ""

    public dynamic var createdUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970
    public dynamic var synced: Bool = false

    public class func getWithRepoID(repoID: Int, inRealm realm: Realm) -> SocialWorkGithubRepo? {
        let predicate = NSPredicate(format: "repoID = %d", repoID)
        return realm.objects(SocialWorkGithubRepo).filter(predicate).first
    }

    public func fillWithGithubRepo(githubRepo: GithubRepo) {
        self.repoID = githubRepo.ID
        self.name = githubRepo.name
        self.fullName = githubRepo.fullName
        self.URLString = githubRepo.URLString
        self.repoDescription = githubRepo.description

        self.createdUnixTime = githubRepo.createdAt.timeIntervalSince1970
    }

    public func fillWithFeedGithubRepo(githubRepo: DiscoveredFeed.GithubRepo) {
        self.repoID = githubRepo.ID//(githubRepo.ID as NSString).integerValue
        self.name = githubRepo.name
        self.fullName = githubRepo.fullName
        self.URLString = githubRepo.URLString
        self.repoDescription = githubRepo.description

        self.createdUnixTime = githubRepo.createdUnixTime
    }
}

public class SocialWorkDribbbleShot: Object {
    public dynamic var shotID: Int = 0
    public dynamic var title: String = ""
    public dynamic var htmlURLString: String = ""
    public dynamic var imageURLString: String = ""
    public dynamic var shotDescription: String = ""

    public dynamic var createdUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970
    public dynamic var synced: Bool = false

    public class func getWithShotID(shotID: Int, inRealm realm: Realm) -> SocialWorkDribbbleShot? {
        let predicate = NSPredicate(format: "shotID = %d", shotID)
        return realm.objects(SocialWorkDribbbleShot).filter(predicate).first
    }

    public func fillWithDribbbleShot(dribbbleShot: DribbbleShot) {
        self.shotID = dribbbleShot.ID
        self.title = dribbbleShot.title
        self.htmlURLString = dribbbleShot.htmlURLString
        
        if let hidpi = dribbbleShot.images.hidpi where dribbbleShot.images.normal.contains("gif") {
            self.imageURLString = hidpi
        } else {
            self.imageURLString = dribbbleShot.images.normal
        }
        
        if let description = dribbbleShot.description {
            self.shotDescription = description
        }

        self.createdUnixTime = dribbbleShot.createdAt.timeIntervalSince1970
    }

    public func fillWithFeedDribbbleShot(dribbbleShot: DiscoveredFeed.DribbbleShot) {
        self.shotID = dribbbleShot.ID//(dribbbleShot.ID as NSString).integerValue
        self.title = dribbbleShot.title
        self.htmlURLString = dribbbleShot.htmlURLString
        self.imageURLString = dribbbleShot.imageURLString
        if let description = dribbbleShot.description {
            self.shotDescription = description
        }

        self.createdUnixTime = dribbbleShot.createdUnixTime
    }
}

public class SocialWorkInstagramMedia: Object {
    public dynamic var repoID: String = ""
    public dynamic var linkURLString: String = ""
    public dynamic var imageURLString: String = ""

    public dynamic var createdUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970
    public dynamic var synced: Bool = false
}

public enum MessageSocialWorkType: Int {
    case GithubRepo     = 0
    case DribbbleShot   = 1
    case InstagramMedia = 2

    public var accountName: String {
        switch self {
        case .GithubRepo: return "github"
        case .DribbbleShot: return "dribbble"
        case .InstagramMedia: return "instagram"
        }
    }
}

public class MessageSocialWork: Object {
    public dynamic var type: Int = MessageSocialWorkType.GithubRepo.rawValue

    public dynamic var githubRepo: SocialWorkGithubRepo?
    public dynamic var dribbbleShot: SocialWorkDribbbleShot?
    public dynamic var instagramMedia: SocialWorkInstagramMedia?
}

public class Message: Object {
    public dynamic var messageID: String = ""

    public dynamic var createdUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970
    public dynamic var updatedUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970
    public dynamic var arrivalUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970

    public dynamic var mediaType: Int = MessageMediaType.Text.rawValue

    public dynamic var textContent: String = ""

    public var recalledTextContent: String {
        let nickname = fromFriend?.nickname ?? ""
        return String(format: NSLocalizedString("recalledMessage%@", comment: ""), nickname)
    }

    public var blockedTextContent: String {
        let nickname = fromFriend?.nickname ?? ""
        return String(format: NSLocalizedString("Ooops! You've been blocked.", comment: ""), nickname)
    }

    public dynamic var openGraphDetected: Bool = false
    public dynamic var openGraphInfo: OpenGraphInfo?

    public dynamic var coordinate: Coordinate?

    public dynamic var attachmentURLString: String = ""
    public dynamic var localAttachmentName: String = ""
    public dynamic var thumbnailURLString: String = ""
    public dynamic var localThumbnailName: String = ""
    public dynamic var attachmentID: String = ""
    public dynamic var attachmentExpiresUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970 + (6 * 60 * 60 * 24) // 6天，过期时间s3为7天，客户端防止误差减去1天

    public var imageFileURL: NSURL? {
        if !localAttachmentName.isEmpty {
            return NSFileManager.yepMessageImageURLWithName(localAttachmentName)
        }
        return nil
    }
    
    public var videoFileURL: NSURL? {
        if !localAttachmentName.isEmpty {
            return NSFileManager.yepMessageVideoURLWithName(localAttachmentName)
        }
        return nil
    }

    public var videoThumbnailFileURL: NSURL? {
        if !localThumbnailName.isEmpty {
            return NSFileManager.yepMessageImageURLWithName(localThumbnailName)
        }
        return nil
    }

    public var audioFileURL: NSURL? {
        if !localAttachmentName.isEmpty {
            return NSFileManager.yepMessageAudioURLWithName(localAttachmentName)
        }
        return nil
    }

    public var imageKey: String {
        return "image-\(messageID)-\(localAttachmentName)-\(attachmentURLString)"
    }

    public var mapImageKey: String {
        return "mapImage-\(messageID)"
    }

    public var nicknameWithTextContent: String {
        if let nickname = fromFriend?.nickname {
            return String(format: NSLocalizedString("nicknameWithTextContent_%@_%@", comment: ""), nickname, textContent)
        } else {
            return textContent
        }
    }

    public var thumbnailImage: UIImage? {
        switch mediaType {
        case MessageMediaType.Image.rawValue:
            if let imageFileURL = imageFileURL {
                return UIImage(contentsOfFile: imageFileURL.path!)
            }
        case MessageMediaType.Video.rawValue:
            if let imageFileURL = videoThumbnailFileURL {
                return UIImage(contentsOfFile: imageFileURL.path!)
            }
        default:
            return nil
        }
        return nil
    }

    public dynamic var mediaMetaData: MediaMetaData?

    public dynamic var socialWork: MessageSocialWork?

    public dynamic var downloadState: Int = MessageDownloadState.NoDownload.rawValue
    public dynamic var sendState: Int = MessageSendState.NotSend.rawValue
    public dynamic var readed: Bool = false
    public dynamic var mediaPlayed: Bool = false // 音频播放过，图片查看过等
    public dynamic var hidden: Bool = false // 隐藏对方消息，使之不再显示
    public dynamic var deletedByCreator: Bool = false
    public dynamic var blockedByRecipient: Bool = false
    public var isIndicator: Bool {
        return deletedByCreator || blockedByRecipient
    }

    public dynamic var fromFriend: User?
    public dynamic var conversation: Conversation?

    public var isReal: Bool {

        if socialWork != nil {
            return false
        }

        if mediaType == MessageMediaType.SectionDate.rawValue {
            return false
        }

        return true
    }

    public func deleteAttachmentInRealm(realm: Realm) {

        if let mediaMetaData = mediaMetaData {
            realm.delete(mediaMetaData)
        }

        // 除非没有谁指向 openGraphInfo，不然不能删除它
        if let openGraphInfo = openGraphInfo {
            if openGraphInfo.feeds.isEmpty {
                if openGraphInfo.messages.count == 1, let first = openGraphInfo.messages.first where first == self {
                    realm.delete(openGraphInfo)
                }
            }
        }

        switch mediaType {

        case MessageMediaType.Image.rawValue:
            NSFileManager.removeMessageImageFileWithName(localAttachmentName)

        case MessageMediaType.Video.rawValue:
            NSFileManager.removeMessageVideoFilesWithName(localAttachmentName, thumbnailName: localThumbnailName)

        case MessageMediaType.Audio.rawValue:
            NSFileManager.removeMessageAudioFileWithName(localAttachmentName)

        case MessageMediaType.Location.rawValue:
            NSFileManager.removeMessageImageFileWithName(localAttachmentName)

        case MessageMediaType.SocialWork.rawValue:

            if let socialWork = socialWork {

                if let githubRepo = socialWork.githubRepo {
                    realm.delete(githubRepo)
                }

                if let dribbbleShot = socialWork.dribbbleShot {
                    realm.delete(dribbbleShot)
                }

                if let instagramMedia = socialWork.instagramMedia {
                    realm.delete(instagramMedia)
                }
                
                realm.delete(socialWork)
            }

        default:
            break // TODO: if have other message media need to delete
        }
    }

    public func deleteInRealm(realm: Realm) {
        deleteAttachmentInRealm(realm)
        realm.delete(self)
    }

    public func updateForDeletedFromServerInRealm(realm: Realm) {

        deletedByCreator = true

        // 删除附件
        deleteAttachmentInRealm(realm)

        // 再将其变为文字消息
        sendState = MessageSendState.Read.rawValue
        readed = true
        textContent = "" 
        mediaType = MessageMediaType.Text.rawValue
    }
}

public class Draft: Object {
    public dynamic var messageToolbarState: Int = MessageToolbarState.Default.rawValue

    public dynamic var text: String = ""
}

// MARK: Conversation

public enum ConversationType: Int {
    case OneToOne   = 0 // 一对一对话
    case Group      = 1 // 群组对话

    public var nameForServer: String {
        switch self {
        case .OneToOne:
            return "User"
        case .Group:
            return "Circle"
        }
    }

    public var nameForBatchMarkAsRead: String {
        switch self {
        case .OneToOne:
            return "users"
        case .Group:
            return "circles"
        }
    }
}

public class Conversation: Object {
    
    public var fakeID: String? {

        if invalidated {
            return nil
        }

        switch type {
        case ConversationType.OneToOne.rawValue:
            if let withFriend = withFriend {
                return "user_" + withFriend.userID
            }
        case ConversationType.Group.rawValue:
            if let withGroup = withGroup {
                return "group_" + withGroup.groupID
            }
        default:
            return nil
        }

        return nil
    }

    public var recipientID: String? {

        switch type {
        case ConversationType.OneToOne.rawValue:
            if let withFriend = withFriend {
                return withFriend.userID
            }
        case ConversationType.Group.rawValue:
            if let withGroup = withGroup {
                return withGroup.groupID
            }
        default:
            return nil
        }

        return nil
    }

    public var recipient: Recipient? {

        if let recipientType = ConversationType(rawValue: type), recipientID = recipientID {
            return Recipient(type: recipientType, ID: recipientID)
        }

        return nil
    }

    public var mentionInitUsers: [UsernamePrefixMatchedUser] {

        let users = messages.flatMap({ $0.fromFriend }).filter({ !$0.invalidated }).filter({ !$0.username.isEmpty && !$0.isMe })

        let usernamePrefixMatchedUser = users.map({
            UsernamePrefixMatchedUser(
                userID: $0.userID,
                username: $0.username,
                nickname: $0.nickname,
                avatarURLString: $0.avatarURLString,
                lastSignInUnixTime: $0.lastSignInUnixTime
            )
        })

        let uniqueSortedUsers = Array(Set(usernamePrefixMatchedUser)).sort({
            $0.lastSignInUnixTime > $1.lastSignInUnixTime
        })

        return uniqueSortedUsers
    }

    public dynamic var type: Int = ConversationType.OneToOne.rawValue
    public dynamic var updatedUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970

    public dynamic var withFriend: User?
    public dynamic var withGroup: Group?

    public dynamic var draft: Draft?

    public let messages = LinkingObjects(fromType: Message.self, property: "conversation")

    public dynamic var unreadMessagesCount: Int = 0
    public dynamic var hasUnreadMessages: Bool = false
    public dynamic var mentionedMe: Bool = false
    public dynamic var lastMentionedMeUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970 - 60*60*12 // 默认为此Conversation创建时间之前半天
    public dynamic var hasOlderMessages: Bool = true

    public var latestValidMessage: Message? {
        return messages.filter({ ($0.hidden == false) && ($0.isIndicator == false && ($0.mediaType != MessageMediaType.SectionDate.rawValue)) }).sort({ $0.createdUnixTime > $1.createdUnixTime }).first
    }

    public var latestMessageTextContentOrPlaceholder: String? {

        guard let latestValidMessage = latestValidMessage else {
            return nil
        }

        if let mediaType = MessageMediaType(rawValue: latestValidMessage.mediaType), placeholder = mediaType.placeholder {
            return placeholder
        } else {
            return latestValidMessage.textContent
        }
    }

    public var needDetectMention: Bool {
        return type == ConversationType.Group.rawValue
    }
}

// MARK: Feed

//enum AttachmentKind: String {
//
//    case Image = "image"
//    case Thumbnail = "thumbnail"
//    case Audio = "audio"
//    case Video = "video"
//}

public class Attachment: Object {

    //dynamic var kind: String = ""
    public dynamic var metadata: String = ""
    public dynamic var URLString: String = ""
}

public class FeedAudio: Object {

    public dynamic var feedID: String = ""
    public dynamic var URLString: String = ""
    public dynamic var metadata: NSData = NSData()
    public dynamic var fileName: String = ""

    public var belongToFeed: Feed? {
        return LinkingObjects(fromType: Feed.self, property: "audio").first
    }

    public var audioFileURL: NSURL? {
        if !fileName.isEmpty {
            if let fileURL = NSFileManager.yepMessageAudioURLWithName(fileName) {
                return fileURL
            }
        }
        return nil
    }

    public class func feedAudioWithFeedID(feedID: String, inRealm realm: Realm) -> FeedAudio? {
        let predicate = NSPredicate(format: "feedID = %@", feedID)
        return realm.objects(FeedAudio).filter(predicate).first
    }

    public var audioMetaInfo: (duration: NSTimeInterval, samples: [CGFloat])? {

        if let metaDataInfo = decodeJSON(metadata) {
            if let
                duration = metaDataInfo[Config.MetaData.audioDuration] as? NSTimeInterval,
                samples = metaDataInfo[Config.MetaData.audioSamples] as? [CGFloat] {
                    return (duration, samples)
            }
        }

        return nil
    }

    public func deleteAudioFile() {

        guard !fileName.isEmpty else {
            return
        }

        NSFileManager.removeMessageAudioFileWithName(fileName)
    }
}

public class FeedLocation: Object {

    public dynamic var name: String = ""
    public dynamic var coordinate: Coordinate?
}

public class OpenGraphInfo: Object {

    public dynamic var URLString: String = ""
    public dynamic var siteName: String = ""
    public dynamic var title: String = ""
    public dynamic var infoDescription: String = ""
    public dynamic var thumbnailImageURLString: String = ""

    public let messages = LinkingObjects(fromType: Message.self, property: "openGraphInfo")
    public let feeds = LinkingObjects(fromType: Feed.self, property: "openGraphInfo")

    public override class func primaryKey() -> String? {
        return "URLString"
    }

    public override class func indexedProperties() -> [String] {
        return ["URLString"]
    }

    public convenience init(URLString: String, siteName: String, title: String, infoDescription: String, thumbnailImageURLString: String) {
        self.init()

        self.URLString = URLString
        self.siteName = siteName
        self.title = title
        self.infoDescription = infoDescription
        self.thumbnailImageURLString = thumbnailImageURLString
    }

    public class func withURLString(URLString: String, inRealm realm: Realm) -> OpenGraphInfo? {
        return realm.objects(OpenGraphInfo).filter("URLString = %@", URLString).first
    }
}

extension OpenGraphInfo: OpenGraphInfoType {

    public var URL: NSURL {
        return NSURL(string: URLString)!
    }
}

public class Feed: Object {

    public dynamic var feedID: String = ""
    public dynamic var allowComment: Bool = true

    public dynamic var createdUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970
    public dynamic var updatedUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970

    public dynamic var creator: User?
    public dynamic var distance: Double = 0
    public dynamic var messagesCount: Int = 0
    public dynamic var body: String = ""

    public dynamic var kind: String = FeedKind.Text.rawValue
    public var attachments = List<Attachment>()
    public dynamic var socialWork: MessageSocialWork?
    public dynamic var audio: FeedAudio?
    public dynamic var location: FeedLocation?
    public dynamic var openGraphInfo: OpenGraphInfo?

    public dynamic var skill: UserSkill?

    public dynamic var group: Group?

    public dynamic var deleted: Bool = false // 已被管理员或建立者删除

    // 级联删除关联的数据对象

    public func cascadeDeleteInRealm(realm: Realm) {

        attachments.forEach {
            realm.delete($0)
        }

        if let socialWork = socialWork {

            if let githubRepo = socialWork.githubRepo {
                realm.delete(githubRepo)
            }

            if let dribbbleShot = socialWork.dribbbleShot {
                realm.delete(dribbbleShot)
            }

            if let instagramMedia = socialWork.instagramMedia {
                realm.delete(instagramMedia)
            }

            realm.delete(socialWork)
        }

        if let audio = audio {

            audio.deleteAudioFile()

            realm.delete(audio)
        }

        if let location = location {

            if let coordinate = location.coordinate {
                realm.delete(coordinate)
            }

            realm.delete(location)
        }

        // 除非没有谁指向 openGraphInfo，不然不能删除它
        if let openGraphInfo = openGraphInfo {
            if openGraphInfo.messages.isEmpty {
                if openGraphInfo.feeds.count == 1, let first = openGraphInfo.messages.first where first == self {
                    realm.delete(openGraphInfo)
                }
            }
        }

        realm.delete(self)
    }
}

// MARK: Offline JSON

public enum OfflineJSONName: String {

    case Feeds
    case DiscoveredUsers
    case GeniusInterviews
}

public class OfflineJSON: Object {

    public dynamic var name: String!
    public dynamic var data: NSData!

    public override class func primaryKey() -> String? {
        return "name"
    }

    public convenience init(name: String, data: NSData) {
        self.init()

        self.name = name
        self.data = data
    }

    public var JSON: JSONDictionary? {
        return decodeJSON(data)
    }

    public class func withName(name: OfflineJSONName, inRealm realm: Realm) -> OfflineJSON? {
        return realm.objects(OfflineJSON).filter("name = %@", name.rawValue).first
    }
}

public class UserLocationName: Object {

    public dynamic var userID: String = ""
    public dynamic var locationName: String = ""

    public override class func primaryKey() -> String? {
        return "userID"
    }

    public override class func indexedProperties() -> [String] {
        return ["userID"]
    }

    public convenience init(userID: String, locationName: String) {
        self.init()

        self.userID = userID
        self.locationName = locationName
    }

    public class func withUserID(userID: String, inRealm realm: Realm) -> UserLocationName? {
        return realm.objects(UserLocationName).filter("userID = %@", userID).first
    }
}

public class SubscriptionViewShown: Object {

    public dynamic var groupID: String = ""

    public override class func primaryKey() -> String? {
        return "groupID"
    }

    public override class func indexedProperties() -> [String] {
        return ["groupID"]
    }

    public convenience init(groupID: String) {
        self.init()

        self.groupID = groupID
    }

    public class func canShow(groupID groupID: String) -> Bool {
        guard let realm = try? Realm() else {
            return false
        }
        return realm.objects(SubscriptionViewShown).filter("groupID = %@", groupID).isEmpty
    }
}

// MARK: Helpers

public func normalFriends() -> Results<User> {
    let realm = try! Realm()
    let predicate = NSPredicate(format: "friendState = %d", UserFriendState.Normal.rawValue)
    return realm.objects(User).filter(predicate).sorted("lastSignInUnixTime", ascending: false)
}

public func normalUsers() -> Results<User> {
    let realm = try! Realm()
    let predicate = NSPredicate(format: "friendState != %d", UserFriendState.Blocked.rawValue)
    return realm.objects(User).filter(predicate)
}

public func userSkillWithSkillID(skillID: String, inRealm realm: Realm) -> UserSkill? {
    let predicate = NSPredicate(format: "skillID = %@", skillID)
    return realm.objects(UserSkill).filter(predicate).first
}

public func userSkillCategoryWithSkillCategoryID(skillCategoryID: String, inRealm realm: Realm) -> UserSkillCategory? {
    let predicate = NSPredicate(format: "skillCategoryID = %@", skillCategoryID)
    return realm.objects(UserSkillCategory).filter(predicate).first
}

public func userWithUserID(userID: String, inRealm realm: Realm) -> User? {
    let predicate = NSPredicate(format: "userID = %@", userID)

    #if DEBUG
    let users = realm.objects(User).filter(predicate)
    if users.count > 1 {
        println("Warning: same userID: \(users.count), \(userID)")
    }
    #endif

    return realm.objects(User).filter(predicate).first
}

public func meInRealm(realm: Realm) -> User? {
    guard let myUserID = YepUserDefaults.userID.value else {
        return nil
    }
    return userWithUserID(myUserID, inRealm: realm)
}

public func me() -> User? {
    guard let realm = try? Realm() else {
        return nil
    }
    return meInRealm(realm)
}

public func userWithUsername(username: String, inRealm realm: Realm) -> User? {
    let predicate = NSPredicate(format: "username = %@", username)
    return realm.objects(User).filter(predicate).first
}

public func userWithAvatarURLString(avatarURLString: String, inRealm realm: Realm) -> User? {
    let predicate = NSPredicate(format: "avatarURLString = %@", avatarURLString)
    return realm.objects(User).filter(predicate).first
}

public func conversationWithDiscoveredUser(discoveredUser: DiscoveredUser, inRealm realm: Realm) -> Conversation? {

    var stranger = userWithUserID(discoveredUser.id, inRealm: realm)

    if stranger == nil {
        let newUser = User()

        newUser.userID = discoveredUser.id

        newUser.friendState = UserFriendState.Stranger.rawValue

        realm.add(newUser)

        stranger = newUser
    }

    guard let user = stranger else {
        return nil
    }

    // 更新用户信息

    user.lastSignInUnixTime = discoveredUser.lastSignInUnixTime

    user.username = discoveredUser.username ?? ""

    user.nickname = discoveredUser.nickname

    if let introduction = discoveredUser.introduction {
        user.introduction = introduction
    }

    user.avatarURLString = discoveredUser.avatarURLString

    user.longitude = discoveredUser.longitude

    user.latitude = discoveredUser.latitude

    if let badge = discoveredUser.badge {
        user.badge = badge
    }

    if let blogURLString = discoveredUser.blogURLString {
        user.blogURLString = blogURLString
    }

    // 更新技能

    user.learningSkills.removeAll()
    let learningUserSkills = userSkillsFromSkills(discoveredUser.learningSkills, inRealm: realm)
    user.learningSkills.appendContentsOf(learningUserSkills)

    user.masterSkills.removeAll()
    let masterUserSkills = userSkillsFromSkills(discoveredUser.masterSkills, inRealm: realm)
    user.masterSkills.appendContentsOf(masterUserSkills)

    // 更新 Social Account Provider

    user.socialAccountProviders.removeAll()
    let socialAccountProviders = userSocialAccountProvidersFromSocialAccountProviders(discoveredUser.socialAccountProviders)
    user.socialAccountProviders.appendContentsOf(socialAccountProviders)

    if user.conversation == nil {
        let newConversation = Conversation()

        newConversation.type = ConversationType.OneToOne.rawValue
        newConversation.withFriend = user

        realm.add(newConversation)
    }

    return user.conversation
}

public func groupWithGroupID(groupID: String, inRealm realm: Realm) -> Group? {
    let predicate = NSPredicate(format: "groupID = %@", groupID)
    return realm.objects(Group).filter(predicate).first
}

public func refreshGroupTypeForAllGroups() {
    if let realm = try? Realm() {
        realm.beginWrite()
        realm.objects(Group).forEach({
            if $0.withFeed == nil {
                $0.groupType = GroupType.Private.rawValue
                println("We have group with NO feed")
            }
        })
        let _ = try? realm.commitWrite()
    }
}

public func feedWithFeedID(feedID: String, inRealm realm: Realm) -> Feed? {
    let predicate = NSPredicate(format: "feedID = %@", feedID)

    #if DEBUG
    let feeds = realm.objects(Feed).filter(predicate)
    if feeds.count > 1 {
        println("Warning: same feedID: \(feeds.count), \(feedID)")
    }
    #endif

    return realm.objects(Feed).filter(predicate).first
}

public func filterValidFeeds(feeds: Results<Feed>) -> [Feed] {
    let validFeeds: [Feed] = feeds
        .filter({ $0.deleted == false })
        .filter({ $0.creator != nil})
        .filter({ $0.group?.conversation != nil })
        .filter({ ($0.group?.includeMe ?? false) })

    return validFeeds
}

public func filterValidMessages(messages: Results<Message>) -> [Message] {
    let validMessages: [Message] = messages
        .filter({ $0.hidden == false })
        .filter({ $0.isIndicator == false })
        .filter({ $0.isReal == true })
        .filter({ !($0.fromFriend?.isMe ?? true)})
        .filter({ $0.conversation != nil })

    return validMessages
}

public func filterValidMessages(messages: [Message]) -> [Message] {
    let validMessages: [Message] = messages
        .filter({ $0.hidden == false })
        .filter({ $0.isIndicator == false })
        .filter({ $0.isReal == true })
        .filter({ !($0.fromFriend?.isMe ?? true) })
        .filter({ $0.conversation != nil })

    return validMessages
}

public func feedConversationsInRealm(realm: Realm) -> Results<Conversation> {
    let predicate = NSPredicate(format: "withGroup != nil AND withGroup.includeMe = true AND withGroup.groupType = %d", GroupType.Public.rawValue)
    let a = SortDescriptor(property: "mentionedMe", ascending: false)
    let b = SortDescriptor(property: "hasUnreadMessages", ascending: false)
    let c = SortDescriptor(property: "updatedUnixTime", ascending: false)
    return realm.objects(Conversation).filter(predicate).sorted([a, b, c])
}

public func mentionedMeInFeedConversationsInRealm(realm: Realm) -> Bool {
    let predicate = NSPredicate(format: "withGroup != nil AND withGroup.includeMe = true AND withGroup.groupType = %d AND mentionedMe = true", GroupType.Public.rawValue)
    return realm.objects(Conversation).filter(predicate).count > 0
}

public func countOfConversationsInRealm(realm: Realm) -> Int {
    return realm.objects(Conversation).filter({ !$0.invalidated }).count
}

public func countOfConversationsInRealm(realm: Realm, withConversationType conversationType: ConversationType) -> Int {
    let predicate = NSPredicate(format: "type = %d", conversationType.rawValue)
    return realm.objects(Conversation).filter(predicate).count
}

public func countOfUnreadMessagesInRealm(realm: Realm, withConversationType conversationType: ConversationType) -> Int {

    switch conversationType {

    case .OneToOne:
        let predicate = NSPredicate(format: "readed = false AND fromFriend != nil AND fromFriend.friendState != %d AND conversation != nil AND conversation.type = %d", UserFriendState.Me.rawValue, conversationType.rawValue)
        return realm.objects(Message).filter(predicate).count

    case .Group: // Public for now
        let predicate = NSPredicate(format: "includeMe = true AND groupType = %d", GroupType.Public.rawValue)
        let count = realm.objects(Group).filter(predicate).map({ $0.conversation }).flatMap({ $0 }).filter({ !$0.invalidated }).map({ $0.hasUnreadMessages ? 1 : 0 }).reduce(0, combine: +)

        return count
    }
}

public func countOfUnreadMessagesInConversation(conversation: Conversation) -> Int {

    return conversation.messages.filter({ message in
        if let fromFriend = message.fromFriend {
            return (message.readed == false) && (fromFriend.friendState != UserFriendState.Me.rawValue)
        } else {
            return false
        }
    }).count
}

public func firstValidMessageInMessageResults(results: Results<Message>) -> (message: Message, headInvalidMessageIDSet: Set<String>)? {

    var headInvalidMessageIDSet: Set<String> = []

    for message in results {
        if !message.deletedByCreator && (message.mediaType != MessageMediaType.SectionDate.rawValue) {
            return (message, headInvalidMessageIDSet)
        } else {
            headInvalidMessageIDSet.insert(message.messageID)
        }
    }

    return nil
}

public func latestValidMessageInRealm(realm: Realm) -> Message? {

    let latestGroupMessage = latestValidMessageInRealm(realm, withConversationType: .Group)
    let latestOneToOneMessage = latestValidMessageInRealm(realm, withConversationType: .OneToOne)

    let latestMessage: Message? = [latestGroupMessage, latestOneToOneMessage].flatMap({ $0 }).sort({ $0.createdUnixTime > $1.createdUnixTime }).first

    return latestMessage
}

public func latestValidMessageInRealm(realm: Realm, withConversationType conversationType: ConversationType) -> Message? {

    switch conversationType {

    case .OneToOne:
        let predicate = NSPredicate(format: "hidden = false AND deletedByCreator = false AND blockedByRecipient == false AND mediaType != %d AND fromFriend != nil AND conversation != nil AND conversation.type = %d", MessageMediaType.SocialWork.rawValue, conversationType.rawValue)
        return realm.objects(Message).filter(predicate).sorted("updatedUnixTime", ascending: false).first

    case .Group: // Public for now
        let predicate = NSPredicate(format: "withGroup != nil AND withGroup.includeMe = true AND withGroup.groupType = %d", GroupType.Public.rawValue)
        let messages: [Message]? = realm.objects(Conversation).filter(predicate).sorted("updatedUnixTime", ascending: false).first?.messages.sort({ $0.createdUnixTime > $1.createdUnixTime })

        return messages?.filter({ ($0.hidden == false) && ($0.isIndicator == false) && ($0.mediaType != MessageMediaType.SectionDate.rawValue)}).first
    }
}

public func latestUnreadValidMessageInRealm(realm: Realm, withConversationType conversationType: ConversationType) -> Message? {

    switch conversationType {

    case .OneToOne:
        let predicate = NSPredicate(format: "readed = false AND hidden = false AND deletedByCreator = false AND blockedByRecipient == false AND mediaType != %d AND fromFriend != nil AND conversation != nil AND conversation.type = %d", MessageMediaType.SocialWork.rawValue, conversationType.rawValue)
        return realm.objects(Message).filter(predicate).sorted("updatedUnixTime", ascending: false).first

    case .Group: // Public for now
        let predicate = NSPredicate(format: "withGroup != nil AND withGroup.includeMe = true AND withGroup.groupType = %d", GroupType.Public.rawValue)
        let messages: [Message]? = realm.objects(Conversation).filter(predicate).sorted("updatedUnixTime", ascending: false).first?.messages.filter({ $0.readed == false && $0.fromFriend?.userID != YepUserDefaults.userID.value }).sort({ $0.createdUnixTime > $1.createdUnixTime })

        return messages?.filter({ ($0.hidden == false) && ($0.isIndicator == false) && ($0.mediaType != MessageMediaType.SectionDate.rawValue) }).first
    }
}

public func saveFeedWithDiscoveredFeed(feedData: DiscoveredFeed, group: Group, inRealm realm: Realm) {

    // save feed
    
    var _feed = feedWithFeedID(feedData.id, inRealm: realm)

    if _feed == nil {
        let newFeed = Feed()
        newFeed.feedID = feedData.id
        newFeed.allowComment = feedData.allowComment
        newFeed.createdUnixTime = feedData.createdUnixTime
        newFeed.updatedUnixTime = feedData.updatedUnixTime
        newFeed.creator = getOrCreateUserWithDiscoverUser(feedData.creator, inRealm: realm)
        newFeed.body = feedData.body

        if let feedSkill = feedData.skill {
            newFeed.skill = userSkillsFromSkills([feedSkill], inRealm: realm).first
        }

        realm.add(newFeed)

        _feed = newFeed

    } else {
        #if DEBUG
            if _feed?.group == nil {
                println("feed have not with group, it may old (not deleted with conversation before)")
            }
        #endif
    }

    guard let feed = _feed else {
        return
    }

    // update feed

    println("update feed: \(feedData.kind.rawValue), \(feed.feedID)")

    feed.kind = feedData.kind.rawValue
    feed.deleted = false

    feed.group = group
    group.withFeed = feed

    group.groupType = GroupType.Public.rawValue

    if let distance = feedData.distance {
        feed.distance = distance
    }

    feed.messagesCount = feedData.messagesCount

    if let attachment = feedData.attachment {

        switch attachment {

        case .Images(let attachments):

            guard feed.attachments.isEmpty else {
                break
            }

            feed.attachments.removeAll()
            let attachments = attachmentFromDiscoveredAttachment(attachments)
            feed.attachments.appendContentsOf(attachments)

        case .Github(let repo):

            guard feed.socialWork?.githubRepo == nil else {
                break
            }

            let socialWork = MessageSocialWork()
            socialWork.type = MessageSocialWorkType.GithubRepo.rawValue

            let repoID = repo.ID
            var socialWorkGithubRepo = SocialWorkGithubRepo.getWithRepoID(repoID, inRealm: realm)

            if socialWorkGithubRepo == nil {
                let newSocialWorkGithubRepo = SocialWorkGithubRepo()
                newSocialWorkGithubRepo.fillWithFeedGithubRepo(repo)

                realm.add(newSocialWorkGithubRepo)

                socialWorkGithubRepo = newSocialWorkGithubRepo
            }

            if let socialWorkGithubRepo = socialWorkGithubRepo {
                socialWorkGithubRepo.synced = true
            }

            socialWork.githubRepo = socialWorkGithubRepo

            feed.socialWork = socialWork

        case .Dribbble(let shot):

            guard feed.socialWork?.dribbbleShot == nil else {
                break
            }

            let socialWork = MessageSocialWork()
            socialWork.type = MessageSocialWorkType.DribbbleShot.rawValue

            let shotID = shot.ID
            var socialWorkDribbbleShot = SocialWorkDribbbleShot.getWithShotID(shotID, inRealm: realm)

            if socialWorkDribbbleShot == nil {
                let newSocialWorkDribbbleShot = SocialWorkDribbbleShot()
                newSocialWorkDribbbleShot.fillWithFeedDribbbleShot(shot)

                realm.add(newSocialWorkDribbbleShot)

                socialWorkDribbbleShot = newSocialWorkDribbbleShot
            }

            if let socialWorkDribbbleShot = socialWorkDribbbleShot {
                socialWorkDribbbleShot.synced = true
            }

            socialWork.dribbbleShot = socialWorkDribbbleShot

            feed.socialWork = socialWork

        case .Audio(let audioInfo):

            guard feed.audio == nil else {
                break
            }

            let feedAudio = FeedAudio()
            feedAudio.feedID = audioInfo.feedID
            feedAudio.URLString = audioInfo.URLString
            feedAudio.metadata = audioInfo.metaData

            feed.audio = feedAudio

        case .Location(let locationInfo):

            guard feed.location == nil else {
                break
            }

            let feedLocation = FeedLocation()
            feedLocation.name = locationInfo.name

            let coordinate = Coordinate()
            coordinate.safeConfigureWithLatitude(locationInfo.latitude, longitude:locationInfo.longitude)
            feedLocation.coordinate = coordinate

            feed.location = feedLocation

        case .URL(let info):

            guard feed.openGraphInfo == nil else {
                break
            }

            let openGraphInfo = OpenGraphInfo(URLString: info.URL.absoluteString, siteName: info.siteName, title: info.title, infoDescription: info.infoDescription, thumbnailImageURLString: info.thumbnailImageURLString)

            realm.add(openGraphInfo, update: true)

            feed.openGraphInfo = openGraphInfo
        }
    }
}

public func messageWithMessageID(messageID: String, inRealm realm: Realm) -> Message? {
    if messageID.isEmpty {
        return nil
    }

    let predicate = NSPredicate(format: "messageID = %@", messageID)

    let messages = realm.objects(Message).filter(predicate)

    return messages.first
}

public func avatarWithAvatarURLString(avatarURLString: String, inRealm realm: Realm) -> Avatar? {
    let predicate = NSPredicate(format: "avatarURLString = %@", avatarURLString)
    return realm.objects(Avatar).filter(predicate).first
}

public func tryGetOrCreateMeInRealm(realm: Realm) -> User? {

    guard let userID = YepUserDefaults.userID.value else {
        return nil
    }

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

        let _ = try? realm.write {
            realm.add(me)
        }

        return me
    }
}

public func mediaMetaDataFromString(metaDataString: String, inRealm realm: Realm) -> MediaMetaData? {

    if let data = metaDataString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
        let mediaMetaData = MediaMetaData()
        mediaMetaData.data = data

        realm.add(mediaMetaData)

        return mediaMetaData
    }

    return nil
}

public func oneToOneConversationsInRealm(realm: Realm) -> Results<Conversation> {
    let predicate = NSPredicate(format: "type = %d", ConversationType.OneToOne.rawValue)
    return realm.objects(Conversation).filter(predicate).sorted("updatedUnixTime", ascending: false)
}

public func messagesInConversationFromFriend(conversation: Conversation) -> Results<Message> {
    
    let predicate = NSPredicate(format: "conversation = %@ AND fromFriend.friendState != %d", argumentArray: [conversation, UserFriendState.Me.rawValue])
    
    if let realm = conversation.realm {
        return realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
        
    } else {
        let realm = try! Realm()
        return realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
    }
}

public func messagesInConversation(conversation: Conversation) -> Results<Message> {

    let predicate = NSPredicate(format: "conversation = %@", argumentArray: [conversation])

    if let realm = conversation.realm {
        return realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)

    } else {
        let realm = try! Realm()
        return realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
    }
}

public func messagesOfConversation(conversation: Conversation, inRealm realm: Realm) -> Results<Message> {
    let predicate = NSPredicate(format: "conversation = %@ AND hidden = false", argumentArray: [conversation])
    let messages = realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
    return messages
}

public func handleMessageDeletedFromServer(messageID messageID: String) {

    guard let
        realm = try? Realm(),
        message = messageWithMessageID(messageID, inRealm: realm)
    else {
        return
    }

    let _ = try? realm.write {
        message.updateForDeletedFromServerInRealm(realm)
    }

    let messageIDs: [String] = [message.messageID]

    SafeDispatch.async {
        NSNotificationCenter.defaultCenter().postNotificationName(Config.Notification.deletedMessages, object: ["messageIDs": messageIDs])
    }
}

public func tryCreateSectionDateMessageInConversation(conversation: Conversation, beforeMessage message: Message, inRealm realm: Realm, success: (Message) -> Void) {

    let messages = messagesOfConversation(conversation, inRealm: realm)

    if messages.count > 1 {

        guard let index = messages.indexOf(message) else {
            return
        }

        if let prevMessage = messages[safe: (index - 1)] {

            if message.createdUnixTime - prevMessage.createdUnixTime > 180 { // TODO: Time Section

                // 比新消息早一点点即可
                let sectionDateMessageCreatedUnixTime = message.createdUnixTime - Config.Message.sectionOlderTimeInterval
                let sectionDateMessageID = "sectionDate-\(sectionDateMessageCreatedUnixTime)"

                if let _ = messageWithMessageID(sectionDateMessageID, inRealm: realm) {
                    // do nothing

                } else {
                    // create a new SectionDate Message
                    let newSectionDateMessage = Message()
                    newSectionDateMessage.messageID = sectionDateMessageID

                    newSectionDateMessage.conversation = conversation
                    newSectionDateMessage.mediaType = MessageMediaType.SectionDate.rawValue

                    newSectionDateMessage.createdUnixTime = sectionDateMessageCreatedUnixTime
                    newSectionDateMessage.arrivalUnixTime = sectionDateMessageCreatedUnixTime
                    
                    success(newSectionDateMessage)
                }
            }
        }
    }
}

public func nameOfConversation(conversation: Conversation) -> String? {

    guard !conversation.invalidated else {
        return nil
    }

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

public func lastChatDateOfConversation(conversation: Conversation) -> NSDate? {

    guard !conversation.invalidated else {
        return nil
    }

    let messages = messagesInConversation(conversation)

    if let lastMessage = messages.last {
        return NSDate(timeIntervalSince1970: lastMessage.createdUnixTime)
    }
    
    return nil
}

public func lastSignDateOfConversation(conversation: Conversation) -> NSDate? {

    guard !conversation.invalidated else {
        return nil
    }

    let messages = messagesInConversationFromFriend(conversation)

    if let
        lastMessage = messages.last,
        user = lastMessage.fromFriend {
            return NSDate(timeIntervalSince1970: user.lastSignInUnixTime)
    }

    return nil
}

public func blurredThumbnailImageOfMessage(message: Message) -> UIImage? {

    guard !message.invalidated else {
        return nil
    }

    if let mediaMetaData = message.mediaMetaData {
        if let metaDataInfo = decodeJSON(mediaMetaData.data) {
            if let blurredThumbnailString = metaDataInfo[Config.MetaData.blurredThumbnailString] as? String {
                if let data = NSData(base64EncodedString: blurredThumbnailString, options: NSDataBase64DecodingOptions(rawValue: 0)) {
                    return UIImage(data: data)
                }
            }
        }
    }

    return nil
}

public func audioMetaOfMessage(message: Message) -> (duration: Double, samples: [CGFloat])? {

    guard !message.invalidated else {
        return nil
    }

    if let mediaMetaData = message.mediaMetaData {
        if let metaDataInfo = decodeJSON(mediaMetaData.data) {
            if let
                duration = metaDataInfo[Config.MetaData.audioDuration] as? Double,
                samples = metaDataInfo[Config.MetaData.audioSamples] as? [CGFloat] {
                    return (duration, samples)
            }
        }
    }

    return nil
}

public func imageMetaOfMessage(message: Message) -> (width: CGFloat, height: CGFloat)? {

    guard !message.invalidated else {
        return nil
    }

    if let mediaMetaData = message.mediaMetaData {
        if let metaDataInfo = decodeJSON(mediaMetaData.data) {
            if let
                width = metaDataInfo[Config.MetaData.imageWidth] as? CGFloat,
                height = metaDataInfo[Config.MetaData.imageHeight] as? CGFloat {
                    return (width, height)
            }
        }
    }

    return nil
}

public func videoMetaOfMessage(message: Message) -> (width: CGFloat, height: CGFloat)? {

    guard !message.invalidated else {
        return nil
    }

    if let mediaMetaData = message.mediaMetaData {
        if let metaDataInfo = decodeJSON(mediaMetaData.data) {
            if let
                width = metaDataInfo[Config.MetaData.videoWidth] as? CGFloat,
                height = metaDataInfo[Config.MetaData.videoHeight] as? CGFloat {
                    return (width, height)
            }
        }
    }

    return nil
}

// MARK: Update with info

public func updateUserWithUserID(userID: String, useUserInfo userInfo: [String: AnyObject], inRealm realm: Realm) {

    if let user = userWithUserID(userID, inRealm: realm) {

        // 更新用户信息

        if let lastSignInUnixTime = userInfo["last_sign_in_at"] as? NSTimeInterval {
            user.lastSignInUnixTime = lastSignInUnixTime
        }

        if let username = userInfo["username"] as? String {
            user.username = username
        }

        if let nickname = userInfo["nickname"] as? String {
            user.nickname = nickname
        }

        if let introduction = userInfo["introduction"] as? String {
            user.introduction = introduction
        }

        if let avatarInfo = userInfo["avatar"] as? JSONDictionary, avatarURLString = avatarInfo["url"] as? String {
            user.avatarURLString = avatarURLString
        }

        if let longitude = userInfo["longitude"] as? Double {
            user.longitude = longitude
        }

        if let latitude = userInfo["latitude"] as? Double {
            user.latitude = latitude
        }

        if let badge = userInfo["badge"] as? String {
            user.badge = badge
        }

        if let blogURLString = userInfo["website_url"] as? String {
            user.blogURLString = blogURLString
        }

        if let blogTitle = userInfo["website_title"] as? String {
            user.blogTitle = blogTitle
        }

        // 更新技能

        if let learningSkillsData = userInfo["learning_skills"] as? [JSONDictionary] {
            user.learningSkills.removeAll()
            let userSkills = userSkillsFromSkillsData(learningSkillsData, inRealm: realm)
            user.learningSkills.appendContentsOf(userSkills)
        }

        if let masterSkillsData = userInfo["master_skills"] as? [JSONDictionary] {
            user.masterSkills.removeAll()
            let userSkills = userSkillsFromSkillsData(masterSkillsData, inRealm: realm)
            user.masterSkills.appendContentsOf(userSkills)
        }

        // 更新 Social Account Provider

        if let providersInfo = userInfo["providers"] as? [String: Bool] {

            user.socialAccountProviders.removeAll()

            for (name, enabled) in providersInfo {
                let provider = UserSocialAccountProvider()
                provider.name = name
                provider.enabled = enabled

                user.socialAccountProviders.append(provider)
            }
        }
    }
}

// MARK: Delete

private func clearMessagesOfConversation(conversation: Conversation, inRealm realm: Realm, keepHiddenMessages: Bool) {

    let messages: [Message]
    if keepHiddenMessages {
        messages = conversation.messages.filter({ $0.hidden == false })
    } else {
        messages = conversation.messages.map({ $0 })
    }

    // delete attachments of messages

    messages.forEach { $0.deleteAttachmentInRealm(realm) }

    // delete all messages in conversation

    realm.delete(messages)
}

public func deleteConversation(conversation: Conversation, inRealm realm: Realm, needLeaveGroup: Bool = true, afterLeaveGroup: (() -> Void)? = nil) {

    defer {
        realm.refresh()
    }

    clearMessagesOfConversation(conversation, inRealm: realm, keepHiddenMessages: false)

    // delete conversation from server

    let recipient = conversation.recipient

    if let recipient = recipient where recipient.type == .OneToOne {
        deleteConversationWithRecipient(recipient, failureHandler: nil, completion: {
            println("deleteConversationWithRecipient \(recipient)")
        })
    }

    // delete conversation, finally

    if let group = conversation.withGroup {

        if let feed = conversation.withGroup?.withFeed {

            feed.cascadeDeleteInRealm(realm)
        }

        let groupID = group.groupID

        if needLeaveGroup {
            leaveGroup(groupID: groupID, failureHandler: nil, completion: {
                println("leaved group: \(groupID)")

                afterLeaveGroup?()
            })

        } else {
            println("deleteConversation, not need leave group: \(groupID)")

            if let recipient = recipient where recipient.type == .Group {
                deleteConversationWithRecipient(recipient, failureHandler: nil, completion: {
                    println("deleteConversationWithRecipient \(recipient)")
                })
            }
        }

        realm.delete(group)
    }

    realm.delete(conversation)
}

public func tryDeleteOrClearHistoryOfConversation(conversation: Conversation, inViewController vc: UIViewController, whenAfterClearedHistory afterClearedHistory: () -> Void, afterDeleted: () -> Void, orCanceled cancelled: () -> Void) {

    guard let realm = conversation.realm else {
        cancelled()
        return
    }

    let clearMessages: () -> Void = {

        // clear from server
        if let recipient = conversation.recipient {
            clearHistoryOfConversationWithRecipient(recipient, failureHandler: nil, completion: {
                println("clearHistoryOfConversationWithRecipient \(recipient)")
            })
        }

        realm.beginWrite()
        clearMessagesOfConversation(conversation, inRealm: realm, keepHiddenMessages: true)
        _ = try? realm.commitWrite()
    }

    let delete: () -> Void = {
        realm.beginWrite()
        deleteConversation(conversation, inRealm: realm)
        _ = try? realm.commitWrite()

        realm.refresh()
    }

    // show ActionSheet before delete

    let deleteAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

    let clearHistoryAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("title.clear_history", comment: ""), style: .Default) { _ in

        clearMessages()

        afterClearedHistory()
    }
    deleteAlertController.addAction(clearHistoryAction)

    let deleteAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .Destructive) { _ in

        delete()

        afterDeleted()
    }
    deleteAlertController.addAction(deleteAction)

    let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .Cancel) { _ in

        cancelled()
    }
    deleteAlertController.addAction(cancelAction)
    
    vc.presentViewController(deleteAlertController, animated: true, completion: nil)
}

public func clearUselessRealmObjects() {

    dispatch_async(realmQueue) {

        guard let realm = try? Realm() else {
            return
        }

        defer {
            realm.refresh()
        }

        println("do clearUselessRealmObjects")

        realm.beginWrite()

        // Message

        do {
            // 7天前
            let oldThresholdUnixTime = NSDate(timeIntervalSinceNow: -(60 * 60 * 24 * 7)).timeIntervalSince1970
            //let oldThresholdUnixTime = NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970 // for test

            let predicate = NSPredicate(format: "createdUnixTime < %f", oldThresholdUnixTime)
            let oldMessages = realm.objects(Message).filter(predicate)

            println("oldMessages.count: \(oldMessages.count)")

            oldMessages.forEach({
                $0.deleteAttachmentInRealm(realm)
                realm.delete($0)
            })
        }

        // Feed

        do {
            let predicate = NSPredicate(format: "group == nil")
            let noGroupFeeds = realm.objects(Feed).filter(predicate)

            println("noGroupFeeds.count: \(noGroupFeeds.count)")

            noGroupFeeds.forEach({
                if let group = $0.group {
                    group.cascadeDeleteInRealm(realm)
                } else {
                    $0.cascadeDeleteInRealm(realm)
                }
            })
        }

        do {
            // 2天前
            let oldThresholdUnixTime = NSDate(timeIntervalSinceNow: -(60 * 60 * 24 * 2)).timeIntervalSince1970
            //let oldThresholdUnixTime = NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970 // for test

            let predicate = NSPredicate(format: "group != nil AND group.includeMe = false AND createdUnixTime < %f", oldThresholdUnixTime)
            let notJoinedFeeds = realm.objects(Feed).filter(predicate)

            println("notJoinedFeeds.count: \(notJoinedFeeds.count)")

            notJoinedFeeds.forEach({
                if let group = $0.group {
                    group.cascadeDeleteInRealm(realm)
                } else {
                    $0.cascadeDeleteInRealm(realm)
                }
            })
        }

        // User

        do {
            // 7天前
            let oldThresholdUnixTime = NSDate(timeIntervalSinceNow: -(60 * 60 * 24 * 7)).timeIntervalSince1970
            //let oldThresholdUnixTime = NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970 // for test
            let predicate = NSPredicate(format: "friendState == %d AND createdUnixTime < %f", UserFriendState.Stranger.rawValue, oldThresholdUnixTime)
            //let predicate = NSPredicate(format: "friendState == %d ", UserFriendState.Stranger.rawValue)

            let strangers = realm.objects(User).filter(predicate)

            // 再仔细过滤，避免把需要的去除了（参与对话的，有Group的，Feed创建着，关联有消息的）
            let realStrangers = strangers.filter({
                if $0.conversation == nil && $0.belongsToGroups.isEmpty && $0.ownedGroups.isEmpty && $0.createdFeeds.isEmpty && $0.messages.isEmpty {
                    return true
                }

                return false
            })

            println("realStrangers.count: \(realStrangers.count)")

            realStrangers.forEach({
                $0.cascadeDeleteInRealm(realm)
            })
        }

        // Group

        let _ = try? realm.commitWrite()
    }
}

