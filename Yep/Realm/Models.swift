//
//  Models.swift
//  Yep
//
//  Created by NIX on 15/3/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import Crashlytics
import MapKit

// 总是在这个队列里使用 Realm
//let realmQueue = dispatch_queue_create("com.Yep.realmQueue", DISPATCH_QUEUE_SERIAL)
let realmQueue = dispatch_queue_create("com.YourApp.YourQueue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0))

// MARK: User

// 朋友的“状态”, 注意：上线后若要调整，只能增加新状态
enum UserFriendState: Int {
    case Stranger       = 0   // 陌生人
    case IssuedRequest  = 1   // 已对其发出好友请求
    case Normal         = 2   // 正常状态的朋友
    case Blocked        = 3   // 被屏蔽
    case Me             = 4   // 自己
    case Yep            = 5   // Yep官方账号
}

class Avatar: Object {
    dynamic var avatarURLString: String = ""
    dynamic var avatarFileName: String = ""

    dynamic var roundMini: NSData = NSData() // 60
    dynamic var roundNano: NSData = NSData() // 40

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

    var skillCategory: SkillCell.Skill.Category? {
        if let category = category {
            return SkillCell.Skill.Category(rawValue: category.name)
        }
        return nil
    }

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

class UserDoNotDisturb: Object {
    dynamic var isOn: Bool = false
    dynamic var fromHour: Int = 22
    dynamic var fromMinute: Int = 0
    dynamic var toHour: Int = 7
    dynamic var toMinute: Int = 30

    var hourOffset: Int {
        let localTimeZone = NSTimeZone.localTimeZone()
        let totalSecondsOffset = localTimeZone.secondsFromGMT

        let hourOffset = totalSecondsOffset / (60 * 60)

        return hourOffset
    }

    var minuteOffset: Int {
        let localTimeZone = NSTimeZone.localTimeZone()
        let totalSecondsOffset = localTimeZone.secondsFromGMT

        let hourOffset = totalSecondsOffset / (60 * 60)
        let minuteOffset = (totalSecondsOffset - hourOffset * (60 * 60)) / 60

        return minuteOffset
    }

    func serverStringWithHour(hour: Int, minute: Int) -> String {
        if minute - minuteOffset > 0 {
            return String(format: "%02d:%02d", (hour - hourOffset) % 24, (minute - minuteOffset) % 60)
        } else {
            return String(format: "%02d:%02d", (hour - hourOffset - 1) % 24, ((minute + 60) - minuteOffset) % 60)
        }
    }

    var serverFromString: String {
        return serverStringWithHour(fromHour, minute: fromMinute)
    }

    var serverToString: String {
        return serverStringWithHour(toHour, minute: toMinute)
    }

    var localFromString: String {
        return String(format: "%02d:%02d", fromHour, fromMinute)
    }

    var localToString: String {
        return String(format: "%02d:%02d", toHour, toMinute)
    }
}

class User: Object {
    dynamic var userID: String = ""
    dynamic var username: String = ""
    dynamic var nickname: String = ""
    dynamic var introduction: String = ""
    dynamic var avatarURLString: String = ""
    dynamic var avatar: Avatar?
    dynamic var badge: String = ""

    override class func indexedProperties() -> [String] {
        return ["userID"]
    }

    dynamic var createdUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970
    dynamic var lastSignInUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970

    dynamic var friendState: Int = UserFriendState.Stranger.rawValue
    dynamic var friendshipID: String = ""
    dynamic var isBestfriend: Bool = false
    dynamic var bestfriendIndex: Int = 0

    var canShowProfile: Bool {
        return friendState != UserFriendState.Yep.rawValue
    }

    dynamic var longitude: Double = 0
    dynamic var latitude: Double = 0

    dynamic var notificationEnabled: Bool = true
    dynamic var blocked: Bool = false

    dynamic var doNotDisturb: UserDoNotDisturb?

    var learningSkills = List<UserSkill>()
    var masterSkills = List<UserSkill>()
    var socialAccountProviders = List<UserSocialAccountProvider>()

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

    var createdFeeds: [Feed] {
        return linkingObjects(Feed.self, forProperty: "creator")
    }

    var isMe: Bool {
        if let myUserID = YepUserDefaults.userID.value {
            return userID == myUserID
        }
        
        return false
    }

    var chatCellCompositedName: String {
        if username.isEmpty {
            return nickname
        } else {
            return "\(nickname) @\(username)"
        }
    }

    // 级联删除关联的数据对象

    func cascadeDeleteInRealm(realm: Realm) {

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

func ==(lhs: User, rhs: User) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

extension User: Hashable {

    override var hashValue: Int {
        return userID.hashValue
    }
}

// MARK: Group

// Group 类型，注意：上线后若要调整，只能增加新状态
enum GroupType: Int {
    case Public     = 0
    case Private    = 1
}

class Group: Object {
    dynamic var groupID: String = ""
    dynamic var groupName: String = ""
    dynamic var notificationEnabled: Bool = true
    dynamic var createdUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970

    dynamic var owner: User?
    var members = List<User>()

    dynamic var groupType: Int = GroupType.Public.rawValue

    var withFeed: Feed? {
        return linkingObjects(Feed.self, forProperty: "group").first
    }

    dynamic var includeMe: Bool = false

    var conversation: Conversation? {
        let conversations = linkingObjects(Conversation.self, forProperty: "withGroup")
        return conversations.first
    }

    // 级联删除关联的数据对象

    func cascadeDeleteInRealm(realm: Realm) {

        withFeed?.cascadeDeleteInRealm(realm)

        if let conversation = conversation {
            realm.delete(conversation)

            dispatch_async(dispatch_get_main_queue()) {
                NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.changedConversation, object: nil)
            }
        }

        realm.delete(self)
    }
}

// MARK: Message

class Coordinate: Object {
    dynamic var latitude: Double = 0    // 合法范围 (-90, 90)
    dynamic var longitude: Double = 0   // 合法范围 (-180, 180)

    // NOTICE: always use safe version property
    
    var safeLatitude: Double {
        return abs(latitude) > 90 ? 0 : latitude
    }
    var safeLongitude: Double {
        return abs(longitude) > 180 ? 0 : longitude
    }
    var locationCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: safeLatitude, longitude: safeLongitude)
    }

    func safeConfigureWithLatitude(latitude: Double, longitude: Double) {
        self.latitude = abs(latitude) > 90 ? 0 : latitude
        self.longitude = abs(longitude) > 180 ? 0 : longitude
    }
}

enum MessageDownloadState: Int {
    case NoDownload     = 0 // 未下载
    case Downloading    = 1 // 下载中
    case Downloaded     = 2 // 已下载
}

enum MessageMediaType: Int, CustomStringConvertible {
    case Text           = 0
    case Image          = 1
    case Video          = 2
    case Audio          = 3
    case Sticker        = 4
    case Location       = 5
    case SectionDate    = 6
    case SocialWork     = 7

    var description: String {
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
        }
    }

    var fileExtension: FileExtension? {
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

    var placeholder: String? {
        switch self {
        case .Text:
            return nil
        case .Image:
            return NSLocalizedString("[Image]", comment: "")
        case .Video:
            return NSLocalizedString("[Video]", comment: "")
        case .Audio:
            return NSLocalizedString("[Audio]", comment: "")
        case .Sticker:
            return NSLocalizedString("[Sticker]", comment: "")
        case .Location:
            return NSLocalizedString("[Location]", comment: "")
        case .SocialWork:
            return NSLocalizedString("[Social Work]", comment: "")
        default:
            return NSLocalizedString("All message read", comment: "")
        }
    }
}

enum MessageSendState: Int, CustomStringConvertible {
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

class SocialWorkGithubRepo: Object {
    dynamic var repoID: Int = 0
    dynamic var name: String = ""
    dynamic var fullName: String = ""
    dynamic var URLString: String = ""
    dynamic var repoDescription: String = ""

    dynamic var createdUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970
    dynamic var synced: Bool = false

    class func getWithRepoID(repoID: Int, inRealm realm: Realm) -> SocialWorkGithubRepo? {
        let predicate = NSPredicate(format: "repoID = %d", repoID)
        return realm.objects(SocialWorkGithubRepo).filter(predicate).first
    }

    func fillWithGithubRepo(githubRepo: GithubRepo) {
        self.repoID = githubRepo.ID
        self.name = githubRepo.name
        self.fullName = githubRepo.fullName
        self.URLString = githubRepo.URLString
        self.repoDescription = githubRepo.description

        self.createdUnixTime = githubRepo.createdAt.timeIntervalSince1970
    }

    func fillWithFeedGithubRepo(githubRepo: DiscoveredFeed.GithubRepo) {
        self.repoID = githubRepo.ID//(githubRepo.ID as NSString).integerValue
        self.name = githubRepo.name
        self.fullName = githubRepo.fullName
        self.URLString = githubRepo.URLString
        self.repoDescription = githubRepo.description

        self.createdUnixTime = githubRepo.createdUnixTime
    }
}

class SocialWorkDribbbleShot: Object {
    dynamic var shotID: Int = 0
    dynamic var title: String = ""
    dynamic var htmlURLString: String = ""
    dynamic var imageURLString: String = ""
    dynamic var shotDescription: String = ""

    dynamic var createdUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970
    dynamic var synced: Bool = false

    class func getWithShotID(shotID: Int, inRealm realm: Realm) -> SocialWorkDribbbleShot? {
        let predicate = NSPredicate(format: "shotID = %d", shotID)
        return realm.objects(SocialWorkDribbbleShot).filter(predicate).first
    }

    func fillWithDribbbleShot(dribbbleShot: DribbbleShot) {
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

    func fillWithFeedDribbbleShot(dribbbleShot: DiscoveredFeed.DribbbleShot) {
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

class SocialWorkInstagramMedia: Object {
    dynamic var repoID: String = ""
    dynamic var linkURLString: String = ""
    dynamic var imageURLString: String = ""

    dynamic var createdUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970
    dynamic var synced: Bool = false
}

enum MessageSocialWorkType: Int {
    case GithubRepo     = 0
    case DribbbleShot   = 1
    case InstagramMedia = 2

    var accountName: String {
        switch self {
        case .GithubRepo: return "github"
        case .DribbbleShot: return "dribbble"
        case .InstagramMedia: return "instagram"
        }
    }
}

class MessageSocialWork: Object {
    dynamic var type: Int = MessageSocialWorkType.GithubRepo.rawValue

    dynamic var githubRepo: SocialWorkGithubRepo?
    dynamic var dribbbleShot: SocialWorkDribbbleShot?
    dynamic var instagramMedia: SocialWorkInstagramMedia?
}

class Message: Object {
    dynamic var messageID: String = ""

    dynamic var createdUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970
    dynamic var updatedUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970
    dynamic var arrivalUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970

    dynamic var mediaType: Int = MessageMediaType.Text.rawValue

    dynamic var textContent: String = ""

    var recalledTextContent: String {
        let nickname = fromFriend?.nickname ?? ""
        return String(format: NSLocalizedString("%@ recalled a message.", comment: ""), nickname)
    }

    dynamic var openGraphDetected: Bool = false
    dynamic var openGraphInfo: OpenGraphInfo?

    dynamic var coordinate: Coordinate?

    dynamic var attachmentURLString: String = ""
    dynamic var localAttachmentName: String = ""
    dynamic var thumbnailURLString: String = ""
    dynamic var localThumbnailName: String = ""
    dynamic var attachmentID: String = ""
    dynamic var attachmentExpiresUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970 + (6 * 60 * 60 * 24) // 6天，过期时间s3为7天，客户端防止误差减去1天

    var nicknameWithTextContent: String {
        if let nickname = fromFriend?.nickname {
            return String(format: NSLocalizedString("%@: %@", comment: ""), nickname, textContent)
        } else {
            return textContent
        }
    }

    var thumbnailImage: UIImage? {
        switch mediaType {
        case MessageMediaType.Image.rawValue:
            if let imageFileURL = NSFileManager.yepMessageImageURLWithName(localAttachmentName) {
                return UIImage(contentsOfFile: imageFileURL.path!)
            }
        case MessageMediaType.Video.rawValue:
            if let imageFileURL = NSFileManager.yepMessageImageURLWithName(localThumbnailName) {
                return UIImage(contentsOfFile: imageFileURL.path!)
            }
        default:
            return nil
        }
        return nil
    }

    dynamic var mediaMetaData: MediaMetaData?

    dynamic var socialWork: MessageSocialWork?

    dynamic var downloadState: Int = MessageDownloadState.NoDownload.rawValue
    dynamic var sendState: Int = MessageSendState.NotSend.rawValue
    dynamic var readed: Bool = false
    dynamic var mediaPlayed: Bool = false // 音频播放过，图片查看过等
    dynamic var hidden: Bool = false // 隐藏对方消息，使之不再显示
    dynamic var deletedByCreator: Bool = false

    dynamic var fromFriend: User?
    dynamic var conversation: Conversation? {
        willSet {

            // 往大了更新 conversation.updatedUnixTime
            if let _conversation = newValue where createdUnixTime > _conversation.updatedUnixTime {
                //println("set _conversation.updatedUnixTime")
                _conversation.updatedUnixTime = createdUnixTime
            }

            // 新消息且未读，才考虑设置 hasUnreadMessages
            if conversation == nil && readed == false, let _conversation = newValue {
                println("set _conversation.hasUnreadMessages")
                _conversation.hasUnreadMessages = true
            }
        }
    }

    var isReal: Bool {

        if socialWork != nil {
            return false
        }

        if mediaType == MessageMediaType.SectionDate.rawValue {
            return false
        }

        return true
    }

    func deleteAttachmentInRealm(realm: Realm) {

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

    func deleteInRealm(realm: Realm) {
        deleteAttachmentInRealm(realm)
        realm.delete(self)
    }

    func updateForDeletedFromServerInRealm(realm: Realm) {

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

    var nameForBatchMarkAsRead: String {
        switch self {
        case .OneToOne:
            return "users"
        case .Group:
            return "circles"
        }
    }
}

class Conversation: Object {
    
    var fakeID: String? {

        if invalidated {
            return nil
        }

        switch type {
        case ConversationType.OneToOne.rawValue:
            if let withFriend = withFriend {
                return "user" + withFriend.userID
            }
        case ConversationType.Group.rawValue:
            if let withGroup = withGroup {
                return "group" + withGroup.groupID
            }
        default:
            return nil
        }

        return nil
    }

    var recipientID: String? {

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

    var recipient: Recipient? {

        if let recipientType = ConversationType(rawValue: type), recipientID = recipientID {
            return Recipient(type: recipientType, ID: recipientID)
        }

        return nil
    }

    var mentionInitUsers: [UsernamePrefixMatchedUser] {

        let userSet = Set<User>(messages.flatMap({ $0.fromFriend }).filter({ !$0.username.isEmpty && !$0.isMe }) ?? [])

        let users = Array<User>(userSet).sort({ $0.lastSignInUnixTime > $1.lastSignInUnixTime }).map({ UsernamePrefixMatchedUser(userID: $0.userID, username: $0.username, nickname: $0.nickname, avatarURLString: $0.avatarURLString) })

        return users
    }

    dynamic var type: Int = ConversationType.OneToOne.rawValue
    dynamic var updatedUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970

    dynamic var withFriend: User?
    dynamic var withGroup: Group?

    dynamic var draft: Draft?

    var messages: [Message] {
        return linkingObjects(Message.self, forProperty: "conversation")
    }

    dynamic var unreadMessagesCount: Int = 0
    dynamic var hasUnreadMessages: Bool = false
    dynamic var mentionedMe: Bool = false
    dynamic var lastMentionedMeUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970 // 默认为此Conversation创建的时间

    var latestValidMessage: Message? {
        return messages.filter({ ($0.hidden == false) && ($0.deletedByCreator == false && ($0.mediaType != MessageMediaType.SectionDate.rawValue)) }).sort({ $0.createdUnixTime > $1.createdUnixTime }).first
    }

    var needDetectMention: Bool {
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

class Attachment: Object {

    //dynamic var kind: String = ""
    dynamic var metadata: String = ""
    dynamic var URLString: String = ""
}

class FeedAudio: Object {

    dynamic var feedID: String = ""
    dynamic var URLString: String = ""
    dynamic var metadata: NSData = NSData()
    dynamic var fileName: String = ""

    var belongToFeed: Feed? {
        return linkingObjects(Feed.self, forProperty: "audio").first
    }

    class func feedAudioWithFeedID(feedID: String, inRealm realm: Realm) -> FeedAudio? {
        let predicate = NSPredicate(format: "feedID = %@", feedID)
        return realm.objects(FeedAudio).filter(predicate).first
    }

    var audioMetaInfo: (duration: NSTimeInterval, samples: [CGFloat])? {

        if let metaDataInfo = decodeJSON(metadata) {
            if let
                duration = metaDataInfo[YepConfig.MetaData.audioDuration] as? NSTimeInterval,
                samples = metaDataInfo[YepConfig.MetaData.audioSamples] as? [CGFloat] {
                    return (duration, samples)
            }
        }

        return nil
    }

    func deleteAudioFile() {

        guard !fileName.isEmpty else {
            return
        }

        NSFileManager.removeMessageAudioFileWithName(fileName)
    }
}

class FeedLocation: Object {

    dynamic var name: String = ""
    dynamic var coordinate: Coordinate?
}

class OpenGraphInfo: Object {

    dynamic var URLString: String = ""
    dynamic var siteName: String = ""
    dynamic var title: String = ""
    dynamic var infoDescription: String = ""
    dynamic var thumbnailImageURLString: String = ""

    var messages: [Message] {
        return linkingObjects(Message.self, forProperty: "openGraphInfo")
    }
    var feeds: [Feed] {
        return linkingObjects(Feed.self, forProperty: "openGraphInfo")
    }

    override class func primaryKey() -> String? {
        return "URLString"
    }

    override class func indexedProperties() -> [String] {
        return ["URLString"]
    }

    convenience init(URLString: String, siteName: String, title: String, infoDescription: String, thumbnailImageURLString: String) {
        self.init()

        self.URLString = URLString
        self.siteName = siteName
        self.title = title
        self.infoDescription = infoDescription
        self.thumbnailImageURLString = thumbnailImageURLString
    }

    class func withURLString(URLString: String, inRealm realm: Realm) -> OpenGraphInfo? {
        return realm.objects(OpenGraphInfo).filter("URLString = %@", URLString).first
    }
}

extension OpenGraphInfo: OpenGraphInfoType {

    var URL: NSURL {
        return NSURL(string: URLString)!
    }
}

class Feed: Object {

    dynamic var feedID: String = ""
    dynamic var allowComment: Bool = true

    dynamic var createdUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970
    dynamic var updatedUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970

    dynamic var creator: User?
    dynamic var distance: Double = 0
    dynamic var messagesCount: Int = 0
    dynamic var body: String = ""

    dynamic var kind: String = FeedKind.Text.rawValue
    var attachments = List<Attachment>()
    dynamic var socialWork: MessageSocialWork?
    dynamic var audio: FeedAudio?
    dynamic var location: FeedLocation?
    dynamic var openGraphInfo: OpenGraphInfo?

    dynamic var skill: UserSkill?

    dynamic var group: Group?

    dynamic var deleted: Bool = false // 已被管理员或建立者删除

    // 级联删除关联的数据对象

    func cascadeDeleteInRealm(realm: Realm) {

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

enum OfflineJSONName: String {

    case Feeds
    case DiscoveredUsers
}

class OfflineJSON: Object {

    dynamic var name: String!
    dynamic var data: NSData!

    override class func primaryKey() -> String? {
        return "name"
    }

    convenience init(name: String, data: NSData) {
        self.init()

        self.name = name
        self.data = data
    }

    var JSON: JSONDictionary? {
        return decodeJSON(data)
    }

    class func withName(name: OfflineJSONName, inRealm realm: Realm) -> OfflineJSON? {
        return realm.objects(OfflineJSON).filter("name = %@", name.rawValue).first
    }
}

class UserLocationName: Object {

    dynamic var userID: String = ""
    dynamic var locationName: String = ""

    override class func primaryKey() -> String? {
        return "userID"
    }

    override class func indexedProperties() -> [String] {
        return ["userID"]
    }

    convenience init(userID: String, locationName: String) {
        self.init()

        self.userID = userID
        self.locationName = locationName
    }

    class func withUserID(userID: String, inRealm realm: Realm) -> UserLocationName? {
        return realm.objects(UserLocationName).filter("userID = %@", userID).first
    }
}

// MARK: Helpers

func normalFriends() -> Results<User> {
    let realm = try! Realm()
    let predicate = NSPredicate(format: "friendState = %d", UserFriendState.Normal.rawValue)
    return realm.objects(User).filter(predicate).sorted("lastSignInUnixTime", ascending: false)
}

func normalUsers() -> Results<User> {
    let realm = try! Realm()
    let predicate = NSPredicate(format: "friendState != %d", UserFriendState.Blocked.rawValue)
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

    #if DEBUG
    let users = realm.objects(User).filter(predicate)
    if users.count > 1 {
        println("Warning: same userID: \(users.count), \(userID)")
    }
    #endif

    return realm.objects(User).filter(predicate).first
}

func userWithUsername(username: String, inRealm realm: Realm) -> User? {
    let predicate = NSPredicate(format: "username = %@", username)
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

func feedWithFeedID(feedID: String, inRealm realm: Realm) -> Feed? {
    let predicate = NSPredicate(format: "feedID = %@", feedID)

    #if DEBUG
    let feeds = realm.objects(Feed).filter(predicate)
    if feeds.count > 1 {
        println("Warning: same feedID: \(feeds.count), \(feedID)")
    }
    #endif

    return realm.objects(Feed).filter(predicate).first
}

func feedConversationsInRealm(realm: Realm) -> Results<Conversation> {
    let predicate = NSPredicate(format: "withGroup != nil AND withGroup.includeMe = true AND withGroup.groupType = %d", GroupType.Public.rawValue)
    let a = SortDescriptor(property: "hasUnreadMessages", ascending: false)
    let b = SortDescriptor(property: "updatedUnixTime", ascending: false)
    return realm.objects(Conversation).filter(predicate).sorted([a, b])
}

func mentionedMeInFeedConversationsInRealm(realm: Realm) -> Bool {
    let predicate = NSPredicate(format: "withGroup != nil AND withGroup.includeMe = true AND withGroup.groupType = %d AND mentionedMe = true", GroupType.Public.rawValue)
    return realm.objects(Conversation).filter(predicate).count > 0
}

func countOfConversationsInRealm(realm: Realm) -> Int {
    return realm.objects(Conversation).count
}

func countOfConversationsInRealm(realm: Realm, withConversationType conversationType: ConversationType) -> Int {
    let predicate = NSPredicate(format: "type = %d", conversationType.rawValue)
    return realm.objects(Conversation).filter(predicate).count
}

func countOfUnreadMessagesInRealm(realm: Realm, withConversationType conversationType: ConversationType) -> Int {

    switch conversationType {

    case .OneToOne:
        let predicate = NSPredicate(format: "readed = false AND fromFriend != nil AND fromFriend.friendState != %d AND conversation != nil AND conversation.type = %d", UserFriendState.Me.rawValue, conversationType.rawValue)
        return realm.objects(Message).filter(predicate).count

    case .Group:
        let count = realm.objects(Group).filter("includeMe = true").map({ $0.conversation }).flatMap({ $0 }).map({ $0.hasUnreadMessages ? 1 : 0 }).reduce(0, combine: +)

        return count
    }
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

func latestValidMessageInRealm(realm: Realm, withConversationType conversationType: ConversationType) -> Message? {

    switch conversationType {

    case .OneToOne:
        let predicate = NSPredicate(format: "hidden = false AND deletedByCreator = false AND fromFriend != nil AND conversation != nil AND conversation.type = %d", conversationType.rawValue)
        return realm.objects(Message).filter(predicate).sorted("updatedUnixTime", ascending: false).first

    case .Group:
        let predicate = NSPredicate(format: "withGroup != nil AND withGroup.includeMe = true")
        let messages: [Message]? = realm.objects(Conversation).filter(predicate).sorted("updatedUnixTime", ascending: false).first?.messages.sort({ $0.createdUnixTime > $1.createdUnixTime })

        return messages?.filter({ ($0.hidden == false) && ($0.deletedByCreator == false) && ($0.mediaType != MessageMediaType.SectionDate.rawValue)}).first
    }
}

func latestUnreadValidMessageInRealm(realm: Realm, withConversationType conversationType: ConversationType) -> Message? {

    switch conversationType {

    case .OneToOne:
        let predicate = NSPredicate(format: "readed = false AND hidden = false AND deletedByCreator = false AND fromFriend != nil AND conversation != nil AND conversation.type = %d", conversationType.rawValue)
        return realm.objects(Message).filter(predicate).sorted("updatedUnixTime", ascending: false).first

    case .Group:
        let predicate = NSPredicate(format: "withGroup != nil AND withGroup.includeMe = true")
        let messages: [Message]? = realm.objects(Conversation).filter(predicate).sorted("updatedUnixTime", ascending: false).first?.messages.filter({ $0.readed == false && $0.fromFriend?.userID != YepUserDefaults.userID.value }).sort({ $0.createdUnixTime > $1.createdUnixTime })

        return messages?.filter({ ($0.hidden == false) && ($0.deletedByCreator == false) && ($0.mediaType != MessageMediaType.SectionDate.rawValue) }).first
    }
}

func saveFeedWithDiscoveredFeed(feedData: DiscoveredFeed, group: Group, inRealm realm: Realm) {

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

    //println("update feed: \(feedData.kind.rawValue), \(feed.feedID)")

    feed.kind = feedData.kind.rawValue
    feed.deleted = false

    feed.group = group

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

func messageWithMessageID(messageID: String, inRealm realm: Realm) -> Message? {
    if messageID.isEmpty {
        return nil
    }

    let predicate = NSPredicate(format: "messageID = %@", messageID)

    let messages = realm.objects(Message).filter(predicate)

    return messages.first
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

            let _ = try? realm.write {
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

func messagesInConversationFromFriend(conversation: Conversation) -> Results<Message> {
    
    let predicate = NSPredicate(format: "conversation = %@ AND fromFriend.friendState != %d", argumentArray: [conversation, UserFriendState.Me.rawValue])
    
    if let realm = conversation.realm {
        return realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
        
    } else {
        let realm = try! Realm()
        return realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
    }
}

func messagesInConversation(conversation: Conversation) -> Results<Message> {

    let predicate = NSPredicate(format: "conversation = %@", argumentArray: [conversation])

    if let realm = conversation.realm {
        return realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)

    } else {
        let realm = try! Realm()
        return realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
    }
}

func messagesOfConversation(conversation: Conversation, inRealm realm: Realm) -> Results<Message> {
    let predicate = NSPredicate(format: "conversation = %@ AND hidden = false", argumentArray: [conversation])
    let messages = realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
    return messages
}

func handleMessageDeletedFromServer(messageID messageID: String) {

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

    dispatch_async(dispatch_get_main_queue()) {
        NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.deletedMessages, object: ["messageIDs": messageIDs])
    }
}

func tryCreateSectionDateMessageInConversation(conversation: Conversation, beforeMessage message: Message, inRealm realm: Realm, success: (Message) -> Void) {

    let messages = messagesOfConversation(conversation, inRealm: realm)

    if messages.count > 1 {

        guard let index = messages.indexOf(message) else {
            return
        }

        if let prevMessage = messages[safe: (index - 1)] {

            if message.createdUnixTime - prevMessage.createdUnixTime > 180 { // TODO: Time Section

                // 比新消息早一点点即可
                let sectionDateMessageCreatedUnixTime = message.createdUnixTime - YepConfig.Message.sectionOlderTimeInterval
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

    let messages = messagesInConversationFromFriend(conversation)

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
                if let data = NSData(base64EncodedString: blurredThumbnailString, options: NSDataBase64DecodingOptions(rawValue: 0)) {
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

// MARK: Update with info

func updateUserWithUserID(userID: String, useUserInfo userInfo: JSONDictionary, inRealm realm: Realm) {

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
        messages = conversation.messages
    }

    // delete attachments of messages

    messages.forEach { $0.deleteAttachmentInRealm(realm) }

    // delete all messages in conversation

    realm.delete(messages)
}

func deleteConversation(conversation: Conversation, inRealm realm: Realm, needLeaveGroup: Bool = true, afterLeaveGroup: (() -> Void)? = nil) {

    clearMessagesOfConversation(conversation, inRealm: realm, keepHiddenMessages: false)

    // delete conversation, finally

    if let group = conversation.withGroup {

        if let feed = conversation.withGroup?.withFeed {

            feed.cascadeDeleteInRealm(realm)
        }

        let groupID = group.groupID

        FayeService.sharedManager.unsubscribeGroup(groupID: groupID)

        if needLeaveGroup {
            leaveGroup(groupID: groupID, failureHandler: nil, completion: {
                println("leaved group: \(groupID)")

                afterLeaveGroup?()
            })

        } else {
            println("deleteConversation, not need leave group: \(groupID)")
        }

        realm.delete(group)
    }

    realm.delete(conversation)
}

func tryDeleteOrClearHistoryOfConversation(conversation: Conversation, inViewController vc: UIViewController, whenAfterClearedHistory afterClearedHistory: () -> Void, afterDeleted: () -> Void, orCanceled cancelled: () -> Void) {

    guard let realm = conversation.realm else {
        cancelled()
        return
    }

    let clearMessages: () -> Void = {
        realm.beginWrite()
        clearMessagesOfConversation(conversation, inRealm: realm, keepHiddenMessages: true)
        let _ = try? realm.commitWrite()
    }

    let delete: () -> Void = {
        realm.beginWrite()
        deleteConversation(conversation, inRealm: realm)
        let _ = try? realm.commitWrite()
    }

    // show ActionSheet before delete

    let deleteAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

    let clearHistoryAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Clear history", comment: ""), style: .Default) { _ in

        clearMessages()

        afterClearedHistory()
    }
    deleteAlertController.addAction(clearHistoryAction)

    let deleteAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .Destructive) { _ in

        delete()

        afterDeleted()
    }
    deleteAlertController.addAction(deleteAction)

    let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel) { _ in

        cancelled()
    }
    deleteAlertController.addAction(cancelAction)
    
    vc.presentViewController(deleteAlertController, animated: true, completion: nil)
}

func clearUselessRealmObjects() {

    guard let realm = try? Realm() else {
        return
    }

    println("do clearUselessRealmObjects")

    realm.beginWrite()

    // Message

    do {
        // 7天前
        let oldThresholdUnixTime = NSDate(timeIntervalSinceNow: -(60 * 60 * 24 * 7)).timeIntervalSince1970

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

