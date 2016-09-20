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
public let realmQueue = DispatchQueue(label: "com.Yep.realmQueue", attributes: dispatch_queue_attr_make_with_qos_class(DispatchQueue.Attributes(), DispatchQoS.QoSClass.utility, 0))

// MARK: User

// 朋友的“状态”, 注意：上线后若要调整，只能增加新状态
public enum UserFriendState: Int {
    case stranger       = 0   // 陌生人
    case issuedRequest  = 1   // 已对其发出好友请求
    case normal         = 2   // 正常状态的朋友
    case blocked        = 3   // 被屏蔽
    case me             = 4   // 自己
    case yep            = 5   // Yep官方账号
}

open class Avatar: Object {
    open dynamic var avatarURLString: String = ""
    open dynamic var avatarFileName: String = ""

    open dynamic var roundMini: Data = Data() // 60
    open dynamic var roundNano: Data = Data() // 40

    let users = LinkingObjects(fromType: User.self, property: "avatar")
    open var user: User? {
        return users.first
    }
}

open class UserSkillCategory: Object {
    open dynamic var skillCategoryID: String = ""
    open dynamic var name: String = ""
    open dynamic var localName: String = ""

    open let skills = LinkingObjects(fromType: UserSkill.self, property: "category")
}

open class UserSkill: Object {

    open dynamic var category: UserSkillCategory?

    var skillCategory: SkillCellSkill.Category? {
        if let category = category {
            return SkillCellSkill.Category(rawValue: category.name)
        }
        return nil
    }

    open dynamic var skillID: String = ""
    open dynamic var name: String = ""
    open dynamic var localName: String = ""
    open dynamic var coverURLString: String = ""

    open let learningUsers = LinkingObjects(fromType: User.self, property: "learningSkills")
    open let masterUsers = LinkingObjects(fromType: User.self, property: "masterSkills")
}

open class UserSocialAccountProvider: Object {
    open dynamic var name: String = ""
    open dynamic var enabled: Bool = false
}

open class UserDoNotDisturb: Object {
    open dynamic var isOn: Bool = false
    open dynamic var fromHour: Int = 22
    open dynamic var fromMinute: Int = 0
    open dynamic var toHour: Int = 7
    open dynamic var toMinute: Int = 30

    open var hourOffset: Int {
        let localTimeZone = TimeZone.autoupdatingCurrent
        let totalSecondsOffset = localTimeZone.secondsFromGMT()

        let hourOffset = totalSecondsOffset / (60 * 60)

        return hourOffset
    }

    open var minuteOffset: Int {
        let localTimeZone = TimeZone.autoupdatingCurrent
        let totalSecondsOffset = localTimeZone.secondsFromGMT()

        let hourOffset = totalSecondsOffset / (60 * 60)
        let minuteOffset = (totalSecondsOffset - hourOffset * (60 * 60)) / 60

        return minuteOffset
    }

    open func serverStringWithHour(_ hour: Int, minute: Int) -> String {
        if minute - minuteOffset > 0 {
            return String(format: "%02d:%02d", (hour - hourOffset) % 24, (minute - minuteOffset) % 60)
        } else {
            return String(format: "%02d:%02d", (hour - hourOffset - 1) % 24, ((minute + 60) - minuteOffset) % 60)
        }
    }

    open var serverFromString: String {
        return serverStringWithHour(fromHour, minute: fromMinute)
    }

    open var serverToString: String {
        return serverStringWithHour(toHour, minute: toMinute)
    }

    open var localFromString: String {
        return String(format: "%02d:%02d", fromHour, fromMinute)
    }

    open var localToString: String {
        return String(format: "%02d:%02d", toHour, toMinute)
    }
}

open class User: Object {
    open dynamic var userID: String = ""
    open dynamic var username: String = ""
    open dynamic var nickname: String = ""
    open dynamic var introduction: String = ""
    open dynamic var avatarURLString: String = ""
    open dynamic var avatar: Avatar?
    open dynamic var badge: String = ""
    open dynamic var blogURLString: String = ""
    open dynamic var blogTitle: String = ""

    open override class func indexedProperties() -> [String] {
        return ["userID"]
    }

    open dynamic var createdUnixTime: TimeInterval = Date().timeIntervalSince1970
    open dynamic var lastSignInUnixTime: TimeInterval = Date().timeIntervalSince1970

    open dynamic var friendState: Int = UserFriendState.stranger.rawValue
    open dynamic var friendshipID: String = ""
    open dynamic var isBestfriend: Bool = false
    open dynamic var bestfriendIndex: Int = 0

    open var canShowProfile: Bool {
        return friendState != UserFriendState.yep.rawValue
    }

    open dynamic var longitude: Double = 0
    open dynamic var latitude: Double = 0

    open dynamic var notificationEnabled: Bool = true
    open dynamic var blocked: Bool = false

    open dynamic var doNotDisturb: UserDoNotDisturb?

    open var learningSkills = List<UserSkill>()
    open var masterSkills = List<UserSkill>()
    open var socialAccountProviders = List<UserSocialAccountProvider>()

    open let messages = LinkingObjects(fromType: Message.self, property: "fromFriend")

    let conversations = LinkingObjects(fromType: Conversation.self, property: "withFriend")
    open var conversation: Conversation? {
        return conversations.first
    }

    open let ownedGroups = LinkingObjects(fromType: Group.self, property: "owner")
    open let belongsToGroups = LinkingObjects(fromType: Group.self, property: "members")
    open let createdFeeds = LinkingObjects(fromType: Feed.self, property: "creator")

    open var isMe: Bool {
        if let myUserID = YepUserDefaults.userID.value {
            return userID == myUserID
        }
        
        return false
    }

    open var mentionedUsername: String? {
        if username.isEmpty {
            return nil
        } else {
            return "@\(username)"
        }
    }

    open var compositedName: String {
        if username.isEmpty {
            return nickname
        } else {
            return "\(nickname) @\(username)"
        }
    }

    // 级联删除关联的数据对象

    open func cascadeDeleteInRealm(_ realm: Realm) {

        if let avatar = avatar {

            if !avatar.avatarFileName.isEmpty {
                FileManager.deleteAvatarImageWithName(avatar.avatarFileName)
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
    case `public`     = 0
    case `private`    = 1
}

open class Group: Object {
    open dynamic var groupID: String = ""
    open dynamic var groupName: String = ""
    open dynamic var notificationEnabled: Bool = true
    open dynamic var createdUnixTime: TimeInterval = Date().timeIntervalSince1970

    open dynamic var owner: User?
    open var members = List<User>()

    open dynamic var groupType: Int = GroupType.private.rawValue

    open dynamic var withFeed: Feed?

    open dynamic var includeMe: Bool = false

    let conversations = LinkingObjects(fromType: Conversation.self, property: "withGroup")
    open var conversation: Conversation? {
        return conversations.first
    }

    // 级联删除关联的数据对象

    open func cascadeDeleteInRealm(_ realm: Realm) {

        withFeed?.cascadeDeleteInRealm(realm)

        if let conversation = conversation {
            realm.delete(conversation)

            SafeDispatch.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Config.Notification.changedConversation), object: nil)
            }
        }

        realm.delete(self)
    }
}

// MARK: Message

open class Coordinate: Object {
    open dynamic var latitude: Double = 0    // 合法范围 (-90, 90)
    open dynamic var longitude: Double = 0   // 合法范围 (-180, 180)

    // NOTICE: always use safe version property
    
    open var safeLatitude: Double {
        return abs(latitude) > 90 ? 0 : latitude
    }
    open var safeLongitude: Double {
        return abs(longitude) > 180 ? 0 : longitude
    }
    open var locationCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: safeLatitude, longitude: safeLongitude)
    }

    open func safeConfigureWithLatitude(_ latitude: Double, longitude: Double) {
        self.latitude = abs(latitude) > 90 ? 0 : latitude
        self.longitude = abs(longitude) > 180 ? 0 : longitude
    }
}

public enum MessageDownloadState: Int {
    case noDownload     = 0 // 未下载
    case downloading    = 1 // 下载中
    case downloaded     = 2 // 已下载
}

public enum MessageMediaType: Int, CustomStringConvertible {
    case text           = 0
    case image          = 1
    case video          = 2
    case audio          = 3
    case sticker        = 4
    case location       = 5
    case sectionDate    = 6
    case socialWork     = 7
    case shareFeed      = 8
    
    public var description: String {
        switch self {
        case .text:
            return "text"
        case .image:
            return "image"
        case .video:
            return "video"
        case .audio:
            return "audio"
        case .sticker:
            return "sticker"
        case .location:
            return "location"
        case .sectionDate:
            return "sectionDate"
        case .socialWork:
            return "socialWork"
        case .shareFeed:
            return "shareFeed"
        }
    }

    public var fileExtension: FileExtension? {
        switch self {
        case .image:
            return .JPEG
        case .video:
            return .MP4
        case .audio:
            return .M4A
        default:
            return nil // TODO: more
        }
    }

    public var placeholder: String? {
        switch self {
        case .text:
            return nil
        case .image:
            return NSLocalizedString("placeholder.image", comment: "")
        case .video:
            return NSLocalizedString("placeholder.video", comment: "")
        case .audio:
            return NSLocalizedString("placeholder.audio", comment: "")
        case .sticker:
            return NSLocalizedString("placeholder.sticker", comment: "")
        case .location:
            return NSLocalizedString("placeholder.location", comment: "")
        case .socialWork:
            return NSLocalizedString("placeholder.socialWork", comment: "")
        default:
            return NSLocalizedString("placeholder.all_messages_read", comment: "")
        }
    }
}

public enum MessageSendState: Int, CustomStringConvertible {
    case notSend    = 0
    case failed     = 1
    case successed  = 2
    case read       = 3
    
    public var description: String {
        get {
            switch self {
            case .notSend:
                return "NotSend"
            case .failed:
                return "Failed"
            case .successed:
                return "Sent"
            case .read:
                return "Read"
            }
        }
    }
}

open class MediaMetaData: Object {
    open dynamic var data: Data = Data()

    open var string: String? {
        return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String
    }
}

open class SocialWorkGithubRepo: Object {
    open dynamic var repoID: Int = 0
    open dynamic var name: String = ""
    open dynamic var fullName: String = ""
    open dynamic var URLString: String = ""
    open dynamic var repoDescription: String = ""

    open dynamic var createdUnixTime: TimeInterval = Date().timeIntervalSince1970
    open dynamic var synced: Bool = false

    open class func getWithRepoID(_ repoID: Int, inRealm realm: Realm) -> SocialWorkGithubRepo? {
        let predicate = NSPredicate(format: "repoID = %d", repoID)
        return realm.objects(SocialWorkGithubRepo.self).filter(predicate).first
    }

    open func fillWithGithubRepo(_ githubRepo: GithubRepo) {
        self.repoID = githubRepo.ID
        self.name = githubRepo.name
        self.fullName = githubRepo.fullName
        self.URLString = githubRepo.URLString
        self.repoDescription = githubRepo.description

        self.createdUnixTime = githubRepo.createdAt.timeIntervalSince1970
    }

    open func fillWithFeedGithubRepo(_ githubRepo: DiscoveredFeed.GithubRepo) {
        self.repoID = githubRepo.ID//(githubRepo.ID as NSString).integerValue
        self.name = githubRepo.name
        self.fullName = githubRepo.fullName
        self.URLString = githubRepo.URLString
        self.repoDescription = githubRepo.description

        self.createdUnixTime = githubRepo.createdUnixTime
    }
}

open class SocialWorkDribbbleShot: Object {
    open dynamic var shotID: Int = 0
    open dynamic var title: String = ""
    open dynamic var htmlURLString: String = ""
    open dynamic var imageURLString: String = ""
    open dynamic var shotDescription: String = ""

    open dynamic var createdUnixTime: TimeInterval = Date().timeIntervalSince1970
    open dynamic var synced: Bool = false

    open class func getWithShotID(_ shotID: Int, inRealm realm: Realm) -> SocialWorkDribbbleShot? {
        let predicate = NSPredicate(format: "shotID = %d", shotID)
        return realm.objects(SocialWorkDribbbleShot.self).filter(predicate).first
    }

    open func fillWithDribbbleShot(_ dribbbleShot: DribbbleShot) {
        self.shotID = dribbbleShot.ID
        self.title = dribbbleShot.title
        self.htmlURLString = dribbbleShot.htmlURLString
        
        if let hidpi = dribbbleShot.images.hidpi , dribbbleShot.images.normal.contains("gif") {
            self.imageURLString = hidpi
        } else {
            self.imageURLString = dribbbleShot.images.normal
        }
        
        if let description = dribbbleShot.description {
            self.shotDescription = description
        }

        self.createdUnixTime = dribbbleShot.createdAt.timeIntervalSince1970
    }

    open func fillWithFeedDribbbleShot(_ dribbbleShot: DiscoveredFeed.DribbbleShot) {
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

open class SocialWorkInstagramMedia: Object {
    open dynamic var repoID: String = ""
    open dynamic var linkURLString: String = ""
    open dynamic var imageURLString: String = ""

    open dynamic var createdUnixTime: TimeInterval = Date().timeIntervalSince1970
    open dynamic var synced: Bool = false
}

public enum MessageSocialWorkType: Int {
    case githubRepo     = 0
    case dribbbleShot   = 1
    case instagramMedia = 2

    public var accountName: String {
        switch self {
        case .githubRepo: return "github"
        case .dribbbleShot: return "dribbble"
        case .instagramMedia: return "instagram"
        }
    }
}

open class MessageSocialWork: Object {
    open dynamic var type: Int = MessageSocialWorkType.githubRepo.rawValue

    open dynamic var githubRepo: SocialWorkGithubRepo?
    open dynamic var dribbbleShot: SocialWorkDribbbleShot?
    open dynamic var instagramMedia: SocialWorkInstagramMedia?
}

open class Message: Object {
    open dynamic var messageID: String = ""

    open dynamic var createdUnixTime: TimeInterval = Date().timeIntervalSince1970
    open dynamic var updatedUnixTime: TimeInterval = Date().timeIntervalSince1970
    open dynamic var arrivalUnixTime: TimeInterval = Date().timeIntervalSince1970

    open dynamic var mediaType: Int = MessageMediaType.text.rawValue

    open dynamic var textContent: String = ""

    open var recalledTextContent: String {
        let nickname = fromFriend?.nickname ?? ""
        return String(format: NSLocalizedString("recalledMessage%@", comment: ""), nickname)
    }

    open var blockedTextContent: String {
        return String.trans_promptUserBeenBlocked
    }

    open dynamic var openGraphDetected: Bool = false
    open dynamic var openGraphInfo: OpenGraphInfo?

    open dynamic var coordinate: Coordinate?

    open dynamic var attachmentURLString: String = ""
    open dynamic var localAttachmentName: String = ""
    open dynamic var thumbnailURLString: String = ""
    open dynamic var localThumbnailName: String = ""
    open dynamic var attachmentID: String = ""
    open dynamic var attachmentExpiresUnixTime: TimeInterval = Date().timeIntervalSince1970 + (6 * 60 * 60 * 24) // 6天，过期时间s3为7天，客户端防止误差减去1天

    open var imageFileURL: URL? {
        if !localAttachmentName.isEmpty {
            return FileManager.yepMessageImageURLWithName(localAttachmentName)
        }
        return nil
    }
    
    open var videoFileURL: URL? {
        if !localAttachmentName.isEmpty {
            return FileManager.yepMessageVideoURLWithName(localAttachmentName)
        }
        return nil
    }

    open var videoThumbnailFileURL: URL? {
        if !localThumbnailName.isEmpty {
            return FileManager.yepMessageImageURLWithName(localThumbnailName)
        }
        return nil
    }

    open var audioFileURL: URL? {
        if !localAttachmentName.isEmpty {
            return FileManager.yepMessageAudioURLWithName(localAttachmentName)
        }
        return nil
    }

    open var imageKey: String {
        return "image-\(messageID)-\(localAttachmentName)-\(attachmentURLString)"
    }

    open var mapImageKey: String {
        return "mapImage-\(messageID)"
    }

    open var nicknameWithTextContent: String {
        if let nickname = fromFriend?.nickname {
            return String(format: NSLocalizedString("nicknameWithTextContent_%@_%@", comment: ""), nickname, textContent)
        } else {
            return textContent
        }
    }

    open var thumbnailImage: UIImage? {
        switch mediaType {
        case MessageMediaType.image.rawValue:
            if let imageFileURL = imageFileURL {
                return UIImage(contentsOfFile: imageFileURL.path)
            }
        case MessageMediaType.video.rawValue:
            if let imageFileURL = videoThumbnailFileURL {
                return UIImage(contentsOfFile: imageFileURL.path)
            }
        default:
            return nil
        }
        return nil
    }

    open dynamic var mediaMetaData: MediaMetaData?

    open dynamic var socialWork: MessageSocialWork?

    open dynamic var downloadState: Int = MessageDownloadState.noDownload.rawValue
    open dynamic var sendState: Int = MessageSendState.notSend.rawValue
    open dynamic var readed: Bool = false
    open dynamic var mediaPlayed: Bool = false // 音频播放过，图片查看过等
    open dynamic var hidden: Bool = false // 隐藏对方消息，使之不再显示
    open dynamic var deletedByCreator: Bool = false
    open dynamic var blockedByRecipient: Bool = false
    open var isIndicator: Bool {
        return deletedByCreator || blockedByRecipient
    }

    open dynamic var fromFriend: User?
    open dynamic var conversation: Conversation?

    open var isReal: Bool {

        if socialWork != nil {
            return false
        }

        if mediaType == MessageMediaType.sectionDate.rawValue {
            return false
        }

        return true
    }

    open func deleteAttachmentInRealm(_ realm: Realm) {

        if let mediaMetaData = mediaMetaData {
            realm.delete(mediaMetaData)
        }

        // 除非没有谁指向 openGraphInfo，不然不能删除它
        if let openGraphInfo = openGraphInfo {
            if openGraphInfo.feeds.isEmpty {
                if openGraphInfo.messages.count == 1, let first = openGraphInfo.messages.first , first == self {
                    realm.delete(openGraphInfo)
                }
            }
        }

        switch mediaType {

        case MessageMediaType.image.rawValue:
            FileManager.removeMessageImageFileWithName(localAttachmentName)

        case MessageMediaType.video.rawValue:
            FileManager.removeMessageVideoFilesWithName(localAttachmentName, thumbnailName: localThumbnailName)

        case MessageMediaType.audio.rawValue:
            FileManager.removeMessageAudioFileWithName(localAttachmentName)

        case MessageMediaType.location.rawValue:
            FileManager.removeMessageImageFileWithName(localAttachmentName)

        case MessageMediaType.socialWork.rawValue:

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

    open func deleteInRealm(_ realm: Realm) {
        deleteAttachmentInRealm(realm)
        realm.delete(self)
    }

    open func updateForDeletedFromServerInRealm(_ realm: Realm) {

        deletedByCreator = true

        // 删除附件
        deleteAttachmentInRealm(realm)

        // 再将其变为文字消息
        sendState = MessageSendState.read.rawValue
        readed = true
        textContent = "" 
        mediaType = MessageMediaType.text.rawValue
    }
}

open class Draft: Object {
    open dynamic var messageToolbarState: Int = MessageToolbarState.default.rawValue

    open dynamic var text: String = ""
}

// MARK: Conversation

public enum ConversationType: Int {
    case oneToOne   = 0 // 一对一对话
    case group      = 1 // 群组对话

    public var nameForServer: String {
        switch self {
        case .oneToOne:
            return "User"
        case .group:
            return "Circle"
        }
    }

    public var nameForBatchMarkAsRead: String {
        switch self {
        case .oneToOne:
            return "users"
        case .group:
            return "circles"
        }
    }

    public init?(nameForServer: String) {
        switch nameForServer {
        case "User":
            self = .oneToOne
        case "Circle":
            self = .group
        default:
            return nil
        }
    }
}

open class Conversation: Object {
    
    open var fakeID: String? {

        if isInvalidated {
            return nil
        }

        switch type {
        case ConversationType.oneToOne.rawValue:
            if let withFriend = withFriend {
                return "user_" + withFriend.userID
            }
        case ConversationType.group.rawValue:
            if let withGroup = withGroup {
                return "group_" + withGroup.groupID
            }
        default:
            return nil
        }

        return nil
    }

    open var recipientID: String? {

        switch type {
        case ConversationType.oneToOne.rawValue:
            if let withFriend = withFriend {
                return withFriend.userID
            }
        case ConversationType.group.rawValue:
            if let withGroup = withGroup {
                return withGroup.groupID
            }
        default:
            return nil
        }

        return nil
    }

    open var recipient: Recipient? {

        if let recipientType = ConversationType(rawValue: type), let recipientID = recipientID {
            return Recipient(type: recipientType, ID: recipientID)
        }

        return nil
    }

    open var mentionInitUsers: [UsernamePrefixMatchedUser] {

        let users = messages.flatMap({ $0.fromFriend }).filter({ !$0.isInvalidated }).filter({ !$0.username.isEmpty && !$0.isMe })

        let usernamePrefixMatchedUser = users.map({
            UsernamePrefixMatchedUser(
                userID: $0.userID,
                username: $0.username,
                nickname: $0.nickname,
                avatarURLString: $0.avatarURLString,
                lastSignInUnixTime: $0.lastSignInUnixTime
            )
        })

        let uniqueSortedUsers = Array(Set(usernamePrefixMatchedUser)).sorted(by: {
            $0.lastSignInUnixTime > $1.lastSignInUnixTime
        })

        return uniqueSortedUsers
    }

    open dynamic var type: Int = ConversationType.oneToOne.rawValue
    open dynamic var updatedUnixTime: TimeInterval = Date().timeIntervalSince1970
    open var olderUpdatedUnixTime: TimeInterval {
        return updatedUnixTime - 30
    }

    open dynamic var withFriend: User?
    open dynamic var withGroup: Group?

    open dynamic var draft: Draft?

    open let messages = LinkingObjects(fromType: Message.self, property: "conversation")

    open dynamic var unreadMessagesCount: Int = 0
    open dynamic var hasUnreadMessages: Bool = false
    open dynamic var mentionedMe: Bool = false
    open dynamic var lastMentionedMeUnixTime: TimeInterval = Date().timeIntervalSince1970 - 60*60*12 // 默认为此Conversation创建时间之前半天
    open dynamic var hasOlderMessages: Bool = true

    open var latestValidMessage: Message? {
        return messages.filter({
            ($0.hidden == false) && ($0.isIndicator == false && ($0.mediaType != MessageMediaType.sectionDate.rawValue))
        }).sorted(by: {
            $0.createdUnixTime > $1.createdUnixTime
        }).first
    }

    open var latestMessageTextContentOrPlaceholder: String? {

        guard let latestValidMessage = latestValidMessage else {
            return nil
        }

        if let mediaType = MessageMediaType(rawValue: latestValidMessage.mediaType), let placeholder = mediaType.placeholder {
            return placeholder
        } else {
            return latestValidMessage.textContent
        }
    }

    open var needDetectMention: Bool {
        return type == ConversationType.group.rawValue
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

open class Attachment: Object {

    //dynamic var kind: String = ""
    open dynamic var metadata: String = ""
    open dynamic var URLString: String = ""
}

open class FeedAudio: Object {

    open dynamic var feedID: String = ""
    open dynamic var URLString: String = ""
    open dynamic var metadata: Data = Data()
    open dynamic var fileName: String = ""

    open var belongToFeed: Feed? {
        return LinkingObjects(fromType: Feed.self, property: "audio").first
    }

    open var audioFileURL: URL? {
        if !fileName.isEmpty {
            if let fileURL = FileManager.yepMessageAudioURLWithName(fileName) {
                return fileURL
            }
        }
        return nil
    }

    open class func feedAudioWithFeedID(_ feedID: String, inRealm realm: Realm) -> FeedAudio? {
        let predicate = NSPredicate(format: "feedID = %@", feedID)
        return realm.objects(FeedAudio.self).filter(predicate).first
    }

    open var audioMetaInfo: (duration: TimeInterval, samples: [CGFloat])? {

        if let metaDataInfo = decodeJSON(metadata) {
            if let
                duration = metaDataInfo[Config.MetaData.audioDuration] as? TimeInterval,
                let samples = metaDataInfo[Config.MetaData.audioSamples] as? [CGFloat] {
                    return (duration, samples)
            }
        }

        return nil
    }

    open func deleteAudioFile() {

        guard !fileName.isEmpty else {
            return
        }

        FileManager.removeMessageAudioFileWithName(fileName)
    }
}

open class FeedLocation: Object {

    open dynamic var name: String = ""
    open dynamic var coordinate: Coordinate?
}

open class OpenGraphInfo: Object {

    open dynamic var URLString: String = ""
    open dynamic var siteName: String = ""
    open dynamic var title: String = ""
    open dynamic var infoDescription: String = ""
    open dynamic var thumbnailImageURLString: String = ""

    open let messages = LinkingObjects(fromType: Message.self, property: "openGraphInfo")
    open let feeds = LinkingObjects(fromType: Feed.self, property: "openGraphInfo")

    open override class func primaryKey() -> String? {
        return "URLString"
    }

    open override class func indexedProperties() -> [String] {
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

    open class func withURLString(_ URLString: String, inRealm realm: Realm) -> OpenGraphInfo? {
        return realm.objects(OpenGraphInfo.self).filter("URLString = %@", URLString).first
    }
}

extension OpenGraphInfo: OpenGraphInfoType {

    public var URL: Foundation.URL {
        return Foundation.URL(string: URLString)!
    }
}

open class Feed: Object {

    open dynamic var feedID: String = ""
    open dynamic var allowComment: Bool = true

    open dynamic var createdUnixTime: TimeInterval = Date().timeIntervalSince1970
    open dynamic var updatedUnixTime: TimeInterval = Date().timeIntervalSince1970

    open dynamic var creator: User?
    open dynamic var distance: Double = 0
    open dynamic var messagesCount: Int = 0
    open dynamic var body: String = ""

    open dynamic var kind: String = FeedKind.Text.rawValue
    open var attachments = List<Attachment>()
    open dynamic var socialWork: MessageSocialWork?
    open dynamic var audio: FeedAudio?
    open dynamic var location: FeedLocation?
    open dynamic var openGraphInfo: OpenGraphInfo?

    open dynamic var skill: UserSkill?

    open dynamic var group: Group?

    open dynamic var deleted: Bool = false // 已被管理员或建立者删除

    // 级联删除关联的数据对象

    open func cascadeDeleteInRealm(_ realm: Realm) {

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
                if openGraphInfo.feeds.count == 1, let first = openGraphInfo.messages.first , first == self {
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

open class OfflineJSON: Object {

    open dynamic var name: String!
    open dynamic var data: Data!

    open override class func primaryKey() -> String? {
        return "name"
    }

    public convenience init(name: String, data: Data) {
        self.init()

        self.name = name
        self.data = data
    }

    open var JSON: JSONDictionary? {
        return decodeJSON(data)
    }

    open class func withName(_ name: OfflineJSONName, inRealm realm: Realm) -> OfflineJSON? {
        return realm.objects(OfflineJSON.self).filter("name = %@", name.rawValue).first
    }
}

open class UserLocationName: Object {

    open dynamic var userID: String = ""
    open dynamic var locationName: String = ""

    open override class func primaryKey() -> String? {
        return "userID"
    }

    open override class func indexedProperties() -> [String] {
        return ["userID"]
    }

    public convenience init(userID: String, locationName: String) {
        self.init()

        self.userID = userID
        self.locationName = locationName
    }

    open class func withUserID(_ userID: String, inRealm realm: Realm) -> UserLocationName? {
        return realm.objects(UserLocationName.self).filter("userID = %@", userID).first
    }
}

open class SubscriptionViewShown: Object {

    open dynamic var groupID: String = ""

    open override class func primaryKey() -> String? {
        return "groupID"
    }

    open override class func indexedProperties() -> [String] {
        return ["groupID"]
    }

    public convenience init(groupID: String) {
        self.init()

        self.groupID = groupID
    }

    open class func canShow(groupID: String) -> Bool {
        guard let realm = try? Realm() else {
            return false
        }
        return realm.objects(SubscriptionViewShown.self).filter("groupID = %@", groupID).isEmpty
    }
}

// MARK: Helpers

public func normalFriends() -> Results<User> {
    let realm = try! Realm()
    let predicate = NSPredicate(format: "friendState = %d", UserFriendState.normal.rawValue)
    return realm.objects(User.self).filter(predicate).sorted(byProperty: "lastSignInUnixTime", ascending: false)
}

public func normalUsers() -> Results<User> {
    let realm = try! Realm()
    let predicate = NSPredicate(format: "friendState != %d", UserFriendState.blocked.rawValue)
    return realm.objects(User.self).filter(predicate)
}

public func userSkillWithSkillID(_ skillID: String, inRealm realm: Realm) -> UserSkill? {
    let predicate = NSPredicate(format: "skillID = %@", skillID)
    return realm.objects(UserSkill.self).filter(predicate).first
}

public func userSkillCategoryWithSkillCategoryID(_ skillCategoryID: String, inRealm realm: Realm) -> UserSkillCategory? {
    let predicate = NSPredicate(format: "skillCategoryID = %@", skillCategoryID)
    return realm.objects(UserSkillCategory.self).filter(predicate).first
}

public func userWithUserID(_ userID: String, inRealm realm: Realm) -> User? {
    let predicate = NSPredicate(format: "userID = %@", userID)

    #if DEBUG
    let users = realm.objects(User.self).filter(predicate)
    if users.count > 1 {
        println("Warning: same userID: \(users.count), \(userID)")
    }
    #endif

    return realm.objects(User.self).filter(predicate).first
}

public func meInRealm(_ realm: Realm) -> User? {
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

public func userWithUsername(_ username: String, inRealm realm: Realm) -> User? {
    let predicate = NSPredicate(format: "username = %@", username)
    return realm.objects(User.self).filter(predicate).first
}

public func userWithAvatarURLString(_ avatarURLString: String, inRealm realm: Realm) -> User? {
    let predicate = NSPredicate(format: "avatarURLString = %@", avatarURLString)
    return realm.objects(User.self).filter(predicate).first
}

public func conversationWithDiscoveredUser(_ discoveredUser: DiscoveredUser, inRealm realm: Realm) -> Conversation? {

    var stranger = userWithUserID(discoveredUser.id, inRealm: realm)

    if stranger == nil {
        let newUser = User()

        newUser.userID = discoveredUser.id

        newUser.friendState = UserFriendState.stranger.rawValue

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
    user.learningSkills.append(objectsIn: learningUserSkills)

    user.masterSkills.removeAll()
    let masterUserSkills = userSkillsFromSkills(discoveredUser.masterSkills, inRealm: realm)
    user.masterSkills.append(objectsIn: masterUserSkills)

    // 更新 Social Account Provider

    user.socialAccountProviders.removeAll()
    let socialAccountProviders = userSocialAccountProvidersFromSocialAccountProviders(discoveredUser.socialAccountProviders)
    user.socialAccountProviders.append(objectsIn: socialAccountProviders)

    if user.conversation == nil {
        let newConversation = Conversation()

        newConversation.type = ConversationType.oneToOne.rawValue
        newConversation.withFriend = user

        realm.add(newConversation)
    }

    return user.conversation
}

public func groupWithGroupID(_ groupID: String, inRealm realm: Realm) -> Group? {
    let predicate = NSPredicate(format: "groupID = %@", groupID)
    return realm.objects(Group.self).filter(predicate).first
}

public func refreshGroupTypeForAllGroups() {
    if let realm = try? Realm() {
        realm.beginWrite()
        realm.objects(Group.self).forEach({
            if $0.withFeed == nil {
                $0.groupType = GroupType.private.rawValue
                println("We have group with NO feed")
            }
        })
        let _ = try? realm.commitWrite()
    }
}

public func feedWithFeedID(_ feedID: String, inRealm realm: Realm) -> Feed? {
    let predicate = NSPredicate(format: "feedID = %@", feedID)

    #if DEBUG
    let feeds = realm.objects(Feed.self).filter(predicate)
    if feeds.count > 1 {
        println("Warning: same feedID: \(feeds.count), \(feedID)")
    }
    #endif

    return realm.objects(Feed.self).filter(predicate).first
}

public func filterValidFeeds(_ feeds: Results<Feed>) -> [Feed] {
    let validFeeds: [Feed] = feeds
        .filter({ $0.deleted == false })
        .filter({ $0.creator != nil})
        .filter({ $0.group?.conversation != nil })
        .filter({ ($0.group?.includeMe ?? false) })

    return validFeeds
}

public func filterValidMessages(_ messages: Results<Message>) -> [Message] {
    let validMessages: [Message] = messages
        .filter({ $0.hidden == false })
        .filter({ $0.isIndicator == false })
        .filter({ $0.isReal == true })
        .filter({ !($0.fromFriend?.isMe ?? true)})
        .filter({ $0.conversation != nil })

    return validMessages
}

public func filterValidMessages(_ messages: [Message]) -> [Message] {
    let validMessages: [Message] = messages
        .filter({ $0.hidden == false })
        .filter({ $0.isIndicator == false })
        .filter({ $0.isReal == true })
        .filter({ !($0.fromFriend?.isMe ?? true) })
        .filter({ $0.conversation != nil })

    return validMessages
}

public func feedConversationsInRealm(_ realm: Realm) -> Results<Conversation> {
    let predicate = NSPredicate(format: "withGroup != nil AND withGroup.includeMe = true AND withGroup.groupType = %d", GroupType.public.rawValue)
    let a = SortDescriptor(property: "mentionedMe", ascending: false)
    let b = SortDescriptor(property: "hasUnreadMessages", ascending: false)
    let c = SortDescriptor(property: "updatedUnixTime", ascending: false)
    return realm.objects(Conversation.self).filter(predicate).sorted(by: [a, b, c])
}

public func mentionedMeInFeedConversationsInRealm(_ realm: Realm) -> Bool {
    let predicate = NSPredicate(format: "withGroup != nil AND withGroup.includeMe = true AND withGroup.groupType = %d AND mentionedMe = true", GroupType.public.rawValue)
    return realm.objects(Conversation.self).filter(predicate).count > 0
}

public func countOfConversationsInRealm(_ realm: Realm) -> Int {
    return realm.objects(Conversation.self).filter({ !$0.isInvalidated }).count
}

public func countOfConversationsInRealm(_ realm: Realm, withConversationType conversationType: ConversationType) -> Int {
    let predicate = NSPredicate(format: "type = %d", conversationType.rawValue)
    return realm.objects(Conversation.self).filter(predicate).count
}

public func countOfUnreadMessagesInRealm(_ realm: Realm, withConversationType conversationType: ConversationType) -> Int {

    switch conversationType {

    case .oneToOne:
        let predicate = NSPredicate(format: "readed = false AND fromFriend != nil AND fromFriend.friendState != %d AND conversation != nil AND conversation.type = %d", UserFriendState.me.rawValue, conversationType.rawValue)
        return realm.objects(Message.self).filter(predicate).count

    case .group: // Public for now
        let predicate = NSPredicate(format: "includeMe = true AND groupType = %d", GroupType.public.rawValue)
        let count = realm.objects(Group.self).filter(predicate).map({ $0.conversation }).flatMap({ $0 }).filter({ !$0.isInvalidated }).map({ $0.hasUnreadMessages ? 1 : 0 }).reduce(0, +)

        return Int(count)
    }
}

public func countOfUnreadMessagesInConversation(_ conversation: Conversation) -> Int {

    return conversation.messages.filter({ message in
        if let fromFriend = message.fromFriend {
            return (message.readed == false) && (fromFriend.friendState != UserFriendState.me.rawValue)
        } else {
            return false
        }
    }).count
}

public func firstValidMessageInMessageResults(_ results: Results<Message>) -> (message: Message, headInvalidMessageIDSet: Set<String>)? {

    var headInvalidMessageIDSet: Set<String> = []

    for message in results {
        if !message.deletedByCreator && (message.mediaType != MessageMediaType.sectionDate.rawValue) {
            return (message, headInvalidMessageIDSet)
        } else {
            headInvalidMessageIDSet.insert(message.messageID)
        }
    }

    return nil
}

public func latestValidMessageInRealm(_ realm: Realm) -> Message? {

    let latestGroupMessage = latestValidMessageInRealm(realm, withConversationType: .group)
    let latestOneToOneMessage = latestValidMessageInRealm(realm, withConversationType: .oneToOne)

    let latestMessage: Message? = [latestGroupMessage, latestOneToOneMessage].flatMap({ $0 }).sorted(by: { $0.createdUnixTime > $1.createdUnixTime }).first

    return latestMessage
}

public func latestValidMessageInRealm(_ realm: Realm, withConversationType conversationType: ConversationType) -> Message? {

    switch conversationType {

    case .oneToOne:
        let predicate = NSPredicate(format: "hidden = false AND deletedByCreator = false AND blockedByRecipient == false AND mediaType != %d AND fromFriend != nil AND conversation != nil AND conversation.type = %d", MessageMediaType.socialWork.rawValue, conversationType.rawValue)
        return realm.objects(Message.self).filter(predicate).sorted(byProperty: "updatedUnixTime", ascending: false).first

    case .group: // Public for now
        let predicate = NSPredicate(format: "withGroup != nil AND withGroup.includeMe = true AND withGroup.groupType = %d", GroupType.public.rawValue)
        let messages: [Message]? = realm.objects(Conversation.self).filter(predicate).sorted(byProperty: "updatedUnixTime", ascending: false).first?.messages.sorted(by: { $0.createdUnixTime > $1.createdUnixTime })

        return messages?.filter({ ($0.hidden == false) && ($0.isIndicator == false) && ($0.mediaType != MessageMediaType.sectionDate.rawValue)}).first
    }
}

public func latestUnreadValidMessageInRealm(_ realm: Realm, withConversationType conversationType: ConversationType) -> Message? {

    switch conversationType {

    case .oneToOne:
        let predicate = NSPredicate(format: "readed = false AND hidden = false AND deletedByCreator = false AND blockedByRecipient == false AND mediaType != %d AND fromFriend != nil AND conversation != nil AND conversation.type = %d", MessageMediaType.socialWork.rawValue, conversationType.rawValue)
        return realm.objects(Message.self).filter(predicate).sorted(byProperty: "updatedUnixTime", ascending: false).first

    case .group: // Public for now
        let predicate = NSPredicate(format: "withGroup != nil AND withGroup.includeMe = true AND withGroup.groupType = %d", GroupType.public.rawValue)
        let messages: [Message]? = realm.objects(Conversation.self).filter(predicate).sorted(byProperty: "updatedUnixTime", ascending: false).first?.messages.filter({ $0.readed == false && $0.fromFriend?.userID != YepUserDefaults.userID.value }).sorted(by: { $0.createdUnixTime > $1.createdUnixTime })

        return messages?.filter({ ($0.hidden == false) && ($0.isIndicator == false) && ($0.mediaType != MessageMediaType.sectionDate.rawValue) }).first
    }
}

public func saveFeedWithDiscoveredFeed(_ feedData: DiscoveredFeed, group: Group, inRealm realm: Realm) {

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

    group.groupType = GroupType.public.rawValue

    if let distance = feedData.distance {
        feed.distance = distance
    }

    feed.messagesCount = feedData.messagesCount

    if let attachment = feedData.attachment {

        switch attachment {

        case .images(let attachments):

            guard feed.attachments.isEmpty else {
                break
            }

            feed.attachments.removeAll()
            let attachments = attachmentFromDiscoveredAttachment(attachments)
            feed.attachments.append(objectsIn: attachments)

        case .github(let repo):

            guard feed.socialWork?.githubRepo == nil else {
                break
            }

            let socialWork = MessageSocialWork()
            socialWork.type = MessageSocialWorkType.githubRepo.rawValue

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

        case .dribbble(let shot):

            guard feed.socialWork?.dribbbleShot == nil else {
                break
            }

            let socialWork = MessageSocialWork()
            socialWork.type = MessageSocialWorkType.dribbbleShot.rawValue

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

        case .audio(let audioInfo):

            guard feed.audio == nil else {
                break
            }

            let feedAudio = FeedAudio()
            feedAudio.feedID = audioInfo.feedID
            feedAudio.URLString = audioInfo.URLString
            feedAudio.metadata = audioInfo.metaData

            feed.audio = feedAudio

        case .location(let locationInfo):

            guard feed.location == nil else {
                break
            }

            let feedLocation = FeedLocation()
            feedLocation.name = locationInfo.name

            let coordinate = Coordinate()
            coordinate.safeConfigureWithLatitude(locationInfo.latitude, longitude:locationInfo.longitude)
            feedLocation.coordinate = coordinate

            feed.location = feedLocation

        case .url(let info):

            guard feed.openGraphInfo == nil else {
                break
            }

            let openGraphInfo = OpenGraphInfo(URLString: info.URL.absoluteString, siteName: info.siteName, title: info.title, infoDescription: info.infoDescription, thumbnailImageURLString: info.thumbnailImageURLString)

            realm.add(openGraphInfo, update: true)

            feed.openGraphInfo = openGraphInfo
        }
    }
}

public func messageWithMessageID(_ messageID: String, inRealm realm: Realm) -> Message? {
    if messageID.isEmpty {
        return nil
    }

    let predicate = NSPredicate(format: "messageID = %@", messageID)

    let messages = realm.objects(Message.self).filter(predicate)

    return messages.first
}

public func avatarWithAvatarURLString(_ avatarURLString: String, inRealm realm: Realm) -> Avatar? {
    let predicate = NSPredicate(format: "avatarURLString = %@", avatarURLString)
    return realm.objects(Avatar.self).filter(predicate).first
}

public func tryGetOrCreateMeInRealm(_ realm: Realm) -> User? {

    guard let userID = YepUserDefaults.userID.value else {
        return nil
    }

    if let me = userWithUserID(userID, inRealm: realm) {
        return me

    } else {
        let me = User()

        me.userID = userID
        me.friendState = UserFriendState.me.rawValue

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

public func mediaMetaDataFromString(_ metaDataString: String, inRealm realm: Realm) -> MediaMetaData? {

    if let data = metaDataString.data(using: String.Encoding.utf8, allowLossyConversion: false) {
        let mediaMetaData = MediaMetaData()
        mediaMetaData.data = data

        realm.add(mediaMetaData)

        return mediaMetaData
    }

    return nil
}

public func oneToOneConversationsInRealm(_ realm: Realm) -> Results<Conversation> {
    let predicate = NSPredicate(format: "type = %d", ConversationType.oneToOne.rawValue)
    return realm.objects(Conversation.self).filter(predicate).sorted(byProperty: "updatedUnixTime", ascending: false)
}

public func messagesInConversationFromFriend(_ conversation: Conversation) -> Results<Message> {
    
    let predicate = NSPredicate(format: "conversation = %@ AND fromFriend.friendState != %d", argumentArray: [conversation, UserFriendState.me.rawValue])
    
    if let realm = conversation.realm {
        return realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
        
    } else {
        let realm = try! Realm()
        return realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
    }
}

public func messagesInConversation(_ conversation: Conversation) -> Results<Message> {

    let predicate = NSPredicate(format: "conversation = %@", argumentArray: [conversation])

    if let realm = conversation.realm {
        return realm.objects(Message.self).filter(predicate).sorted(byProperty: "createdUnixTime", ascending: true)

    } else {
        let realm = try! Realm()
        return realm.objects(Message.self).filter(predicate).sorted(byProperty: "createdUnixTime", ascending: true)
    }
}

public func messagesOfConversation(_ conversation: Conversation, inRealm realm: Realm) -> Results<Message> {
    let predicate = NSPredicate(format: "conversation = %@ AND hidden = false", argumentArray: [conversation])
    let messages = realm.objects(Message.self).filter(predicate).sorted(byProperty: "createdUnixTime", ascending: true)
    return messages
}

public func handleMessageDeletedFromServer(messageID: String) {

    guard let
        realm = try? Realm(),
        let message = messageWithMessageID(messageID, inRealm: realm)
    else {
        return
    }

    let _ = try? realm.write {
        message.updateForDeletedFromServerInRealm(realm)
    }

    let messageIDs: [String] = [message.messageID]

    SafeDispatch.async {
        NotificationCenter.default.post(name: Notification.Name(rawValue: Config.Notification.deletedMessages), object: ["messageIDs": messageIDs])
    }
}

public func tryCreateSectionDateMessageInConversation(_ conversation: Conversation, beforeMessage message: Message, inRealm realm: Realm, success: (Message) -> Void) {

    let messages = messagesOfConversation(conversation, inRealm: realm)

    if messages.count > 1 {

        guard let index = messages.index(of: message) else {
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
                    newSectionDateMessage.mediaType = MessageMediaType.sectionDate.rawValue

                    newSectionDateMessage.createdUnixTime = sectionDateMessageCreatedUnixTime
                    newSectionDateMessage.arrivalUnixTime = sectionDateMessageCreatedUnixTime
                    
                    success(newSectionDateMessage)
                }
            }
        }
    }
}

public func nameOfConversation(_ conversation: Conversation) -> String? {

    guard !conversation.isInvalidated else {
        return nil
    }

    if conversation.type == ConversationType.oneToOne.rawValue {
        if let withFriend = conversation.withFriend {
            return withFriend.nickname
        }

    } else if conversation.type == ConversationType.group.rawValue {
        if let withGroup = conversation.withGroup {
            return withGroup.groupName
        }
    }

    return nil
}

public func lastChatDateOfConversation(_ conversation: Conversation) -> Date? {

    guard !conversation.isInvalidated else {
        return nil
    }

    let messages = messagesInConversation(conversation)

    if let lastMessage = messages.last {
        return Date(timeIntervalSince1970: lastMessage.createdUnixTime)
    }
    
    return nil
}

public func lastSignDateOfConversation(_ conversation: Conversation) -> Date? {

    guard !conversation.isInvalidated else {
        return nil
    }

    let messages = messagesInConversationFromFriend(conversation)

    if let
        lastMessage = messages.last,
        let user = lastMessage.fromFriend {
            return Date(timeIntervalSince1970: user.lastSignInUnixTime)
    }

    return nil
}

public func blurredThumbnailImageOfMessage(_ message: Message) -> UIImage? {

    guard !message.isInvalidated else {
        return nil
    }

    if let mediaMetaData = message.mediaMetaData {
        if let metaDataInfo = decodeJSON(mediaMetaData.data) {
            if let blurredThumbnailString = metaDataInfo[Config.MetaData.blurredThumbnailString] as? String {
                if let data = Data(base64Encoded: blurredThumbnailString, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                    return UIImage(data: data)
                }
            }
        }
    }

    return nil
}

public func audioMetaOfMessage(_ message: Message) -> (duration: Double, samples: [CGFloat])? {

    guard !message.isInvalidated else {
        return nil
    }

    if let mediaMetaData = message.mediaMetaData {
        if let metaDataInfo = decodeJSON(mediaMetaData.data) {
            if let
                duration = metaDataInfo[Config.MetaData.audioDuration] as? Double,
                let samples = metaDataInfo[Config.MetaData.audioSamples] as? [CGFloat] {
                    return (duration, samples)
            }
        }
    }

    return nil
}

public func imageMetaOfMessage(_ message: Message) -> (width: CGFloat, height: CGFloat)? {

    guard !message.isInvalidated else {
        return nil
    }

    if let mediaMetaData = message.mediaMetaData {
        if let metaDataInfo = decodeJSON(mediaMetaData.data) {
            if let
                width = metaDataInfo[Config.MetaData.imageWidth] as? CGFloat,
                let height = metaDataInfo[Config.MetaData.imageHeight] as? CGFloat {
                    return (width, height)
            }
        }
    }

    return nil
}

public func videoMetaOfMessage(_ message: Message) -> (width: CGFloat, height: CGFloat)? {

    guard !message.isInvalidated else {
        return nil
    }

    if let mediaMetaData = message.mediaMetaData {
        if let metaDataInfo = decodeJSON(mediaMetaData.data) {
            if let
                width = metaDataInfo[Config.MetaData.videoWidth] as? CGFloat,
                let height = metaDataInfo[Config.MetaData.videoHeight] as? CGFloat {
                    return (width, height)
            }
        }
    }

    return nil
}

// MARK: Update with info

public func updateUserWithUserID(_ userID: String, useUserInfo userInfo: JSONDictionary, inRealm realm: Realm) {

    if let user = userWithUserID(userID, inRealm: realm) {

        // 更新用户信息

        if let lastSignInUnixTime = userInfo["last_sign_in_at"] as? TimeInterval {
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

        if let avatarInfo = userInfo["avatar"] as? JSONDictionary, let avatarURLString = avatarInfo["url"] as? String {
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
            user.learningSkills.append(objectsIn: userSkills)
        }

        if let masterSkillsData = userInfo["master_skills"] as? [JSONDictionary] {
            user.masterSkills.removeAll()
            let userSkills = userSkillsFromSkillsData(masterSkillsData, inRealm: realm)
            user.masterSkills.append(objectsIn: userSkills)
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

private func clearMessagesOfConversation(_ conversation: Conversation, inRealm realm: Realm, keepHiddenMessages: Bool) {

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

public func deleteConversation(_ conversation: Conversation, inRealm realm: Realm, needLeaveGroup: Bool = true, afterLeaveGroup: (() -> Void)? = nil) {

    defer {
        realm.refresh()
    }

    clearMessagesOfConversation(conversation, inRealm: realm, keepHiddenMessages: false)

    // delete conversation from server

    let recipient = conversation.recipient

    if let recipient = recipient , recipient.type == .oneToOne {
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

            if let recipient = recipient , recipient.type == .group {
                deleteConversationWithRecipient(recipient, failureHandler: nil, completion: {
                    println("deleteConversationWithRecipient \(recipient)")
                })
            }
        }

        realm.delete(group)
    }

    realm.delete(conversation)
}

public func tryDeleteOrClearHistoryOfConversation(_ conversation: Conversation, inViewController vc: UIViewController, whenAfterClearedHistory afterClearedHistory: @escaping () -> Void, afterDeleted: @escaping () -> Void, orCanceled cancelled: @escaping () -> Void) {

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

    let deleteAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

    let clearHistoryAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("title.clear_history", comment: ""), style: .default) { _ in

        clearMessages()

        afterClearedHistory()
    }
    deleteAlertController.addAction(clearHistoryAction)

    let deleteAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("title.delete", comment: ""), style: .destructive) { _ in

        delete()

        afterDeleted()
    }
    deleteAlertController.addAction(deleteAction)

    let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel) { _ in

        cancelled()
    }
    deleteAlertController.addAction(cancelAction)
    
    vc.present(deleteAlertController, animated: true, completion: nil)
}

public func clearUselessRealmObjects() {

    realmQueue.async {

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
            let oldThresholdUnixTime = Date(timeIntervalSinceNow: -(60 * 60 * 24 * 7)).timeIntervalSince1970
            //let oldThresholdUnixTime = NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970 // for test

            let predicate = NSPredicate(format: "createdUnixTime < %f", oldThresholdUnixTime)
            let oldMessages = realm.objects(Message.self).filter(predicate)

            println("oldMessages.count: \(oldMessages.count)")

            oldMessages.forEach({
                $0.deleteAttachmentInRealm(realm)
                realm.delete($0)
            })
        }

        // Feed

        do {
            let predicate = NSPredicate(format: "group == nil")
            let noGroupFeeds = realm.objects(Feed.self).filter(predicate)

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
            let oldThresholdUnixTime = Date(timeIntervalSinceNow: -(60 * 60 * 24 * 2)).timeIntervalSince1970
            //let oldThresholdUnixTime = NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970 // for test

            let predicate = NSPredicate(format: "group != nil AND group.includeMe = false AND createdUnixTime < %f", oldThresholdUnixTime)
            let notJoinedFeeds = realm.objects(Feed.self).filter(predicate)

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
            let oldThresholdUnixTime = Date(timeIntervalSinceNow: -(60 * 60 * 24 * 7)).timeIntervalSince1970
            //let oldThresholdUnixTime = NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970 // for test
            let predicate = NSPredicate(format: "friendState == %d AND createdUnixTime < %f", UserFriendState.stranger.rawValue, oldThresholdUnixTime)
            //let predicate = NSPredicate(format: "friendState == %d ", UserFriendState.Stranger.rawValue)

            let strangers = realm.objects(User.self).filter(predicate)

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

