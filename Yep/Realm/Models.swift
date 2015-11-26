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

    var isMe: Bool {
        if let myUserID = YepUserDefaults.userID.value {
            return userID == myUserID
        }
        
        return false
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

    var conversation: Conversation? {
        let conversations = linkingObjects(Conversation.self, forProperty: "withGroup")
        return conversations.first
    }

    // 级联删除关联的数据对象

    func cascadeDelete() {

        guard let realm = realm else {
            return
        }

        withFeed?.cascadeDelete()

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

    var mineType: String {
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
            return (arc4random() % 2 == 0) ?  "I love NIX." : "We love NIX."
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
        self.imageURLString = dribbbleShot.images.normal
        self.shotDescription = dribbbleShot.description

        self.createdUnixTime = dribbbleShot.createdAt.timeIntervalSince1970
    }

    func fillWithFeedDribbbleShot(dribbbleShot: DiscoveredFeed.DribbbleShot) {
        self.shotID = dribbbleShot.ID//(dribbbleShot.ID as NSString).integerValue
        self.title = dribbbleShot.title
        self.htmlURLString = dribbbleShot.htmlURLString
        self.imageURLString = dribbbleShot.imageURLString
        self.shotDescription = dribbbleShot.description

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
    dynamic var coordinate: Coordinate?

    dynamic var attachmentURLString: String = ""
    dynamic var localAttachmentName: String = ""
    dynamic var thumbnailURLString: String = ""
    dynamic var localThumbnailName: String = ""

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

    dynamic var fromFriend: User?
    dynamic var conversation: Conversation?

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

    dynamic var type: Int = ConversationType.OneToOne.rawValue
    dynamic var updatedUnixTime: NSTimeInterval = NSDate().timeIntervalSince1970

    dynamic var withFriend: User?
    dynamic var withGroup: Group?

    dynamic var draft: Draft?

    var messages: [Message] {
        return linkingObjects(Message.self, forProperty: "conversation")
    }

    dynamic var unreadMessagesCount: Int = 0
}

// MARK: Feed

enum AttachmentKind: String {

    case Image = "image"
    case Thumbnail = "thumbnail"
    case Audio = "audio"
    case Video = "video"
}


class Attachment: Object {

    dynamic var kind: String = ""
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

    dynamic var skill: UserSkill?

    dynamic var group: Group?

    dynamic var deleted: Bool = false // 已被管理员或建立者删除

    // 级联删除关联的数据对象

    func cascadeDelete() {

        guard let realm = realm else {
            return
        }

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

        realm.delete(self)
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

func countOfConversationsInRealm(realm: Realm) -> Int {
    return realm.objects(Conversation).count
}

func countOfConversationsInRealm(realm: Realm, withConversationType conversationType: ConversationType) -> Int {
    let predicate = NSPredicate(format: "type = %d", conversationType.rawValue)
    return realm.objects(Conversation).filter(predicate).count
}

func countOfUnreadMessagesInRealm(realm: Realm) -> Int {
    let predicate = NSPredicate(format: "readed = false AND fromFriend != nil AND fromFriend.friendState != %d", UserFriendState.Me.rawValue)
    return realm.objects(Message).filter(predicate).count
}

func countOfUnreadMessagesInRealm(realm: Realm, withConversationType conversationType: ConversationType) -> Int {
    let predicate = NSPredicate(format: "readed = false AND fromFriend != nil AND fromFriend.friendState != %d AND conversation != nil AND conversation.type = %d", UserFriendState.Me.rawValue, conversationType.rawValue)
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

func latestMessageInRealm(realm: Realm, withConversationType conversationType: ConversationType) -> Message? {
    let predicate = NSPredicate(format: "fromFriend != nil AND conversation != nil AND conversation.type = %d", conversationType.rawValue)
    return realm.objects(Message).filter(predicate).sorted("updatedUnixTime", ascending: false).first
}

func saveFeedWithFeedDataWithoutFullGroup(feedData: DiscoveredFeed, group: Group, inRealm realm: Realm) {

    println("saveFeedWithFeedDataWithoutFullGroup joinGroup")

    // try sync group first

    let groupID = group.groupID
    
    joinGroup(groupID: groupID, failureHandler: nil, completion: {

        groupWithGroupID(groupID: groupID, failureHandler: nil, completion: { groupInfo in
            
            guard let realm = try? Realm() else {
                return
            }
            
            //println("feed groupInfo: \(groupInfo)")
            
            syncGroupWithGroupInfo(groupInfo, inRealm: realm)
            
            // now try save feed with full group
            
            if let group = groupWithGroupID(groupID, inRealm: realm) {
                saveFeedWithFeedDataWithFullGroup(feedData, group: group, inRealm: realm)
            }
        })
    })
}

func saveFeedWithFeedDataWithFullGroup(feedData: DiscoveredFeed, group: Group, inRealm realm: Realm) {
    // save feed
    
    if let feed = feedWithFeedID(feedData.id, inRealm: realm) {
        println("saveFeed: \(feedData.kind.rawValue), \(feed.feedID), do nothing.")

        let _ = try? realm.write {
            feed.kind = feedData.kind.rawValue
            feed.deleted = false
        }

        #if DEBUG
        if feed.group == nil {
            println("feed have not with group, it may old (not deleted with conversation before)")
        }
        #endif
        
    } else {
        let newFeed = Feed()
        newFeed.feedID = feedData.id
        newFeed.allowComment = feedData.allowComment
        newFeed.createdUnixTime = feedData.createdUnixTime
        newFeed.updatedUnixTime = feedData.updatedUnixTime
        newFeed.creator = getOrCreateUserWithDiscoverUser(feedData.creator, inRealm: realm)
        newFeed.body = feedData.body
        newFeed.kind = feedData.kind.rawValue
        newFeed.deleted = false
        
        if let distance = feedData.distance {
            newFeed.distance = distance
        }
        
        newFeed.messagesCount = feedData.messagesCount
        
        if let feedSkill = feedData.skill {
            let _ = try? realm.write {
                newFeed.skill = userSkillsFromSkills([feedSkill], inRealm: realm).first
            }
        }

        if let attachment = feedData.attachment {

            switch attachment {

            case .Images(let attachments):

                newFeed.attachments.removeAll()
                let attachments = attachmentFromDiscoveredAttachment(attachments, inRealm: nil)
                newFeed.attachments.appendContentsOf(attachments)

            case .Github(let repo):

                let socialWork = MessageSocialWork()
                socialWork.type = MessageSocialWorkType.GithubRepo.rawValue

                let repoID = repo.ID//(repo.ID as NSString).integerValue
                var socialWorkGithubRepo = SocialWorkGithubRepo.getWithRepoID(repoID, inRealm: realm)

                if socialWorkGithubRepo == nil {
                    let newSocialWorkGithubRepo = SocialWorkGithubRepo()
                    newSocialWorkGithubRepo.fillWithFeedGithubRepo(repo)

                    let _ = try? realm.write {
                        realm.add(newSocialWorkGithubRepo)
                    }

                    socialWorkGithubRepo = newSocialWorkGithubRepo
                }

                if let socialWorkGithubRepo = socialWorkGithubRepo {
                    let _ = try? realm.write {
                        socialWorkGithubRepo.synced = true
                    }
                }

                socialWork.githubRepo = socialWorkGithubRepo
                
                newFeed.socialWork = socialWork

            case .Dribbble(let shot):

                let socialWork = MessageSocialWork()
                socialWork.type = MessageSocialWorkType.DribbbleShot.rawValue

                let shotID = shot.ID//(shot.ID as NSString).integerValue
                var socialWorkDribbbleShot = SocialWorkDribbbleShot.getWithShotID(shotID, inRealm: realm)

                if socialWorkDribbbleShot == nil {
                    let newSocialWorkDribbbleShot = SocialWorkDribbbleShot()
                    newSocialWorkDribbbleShot.fillWithFeedDribbbleShot(shot)

                    let _ = try? realm.write {
                        realm.add(newSocialWorkDribbbleShot)
                    }

                    socialWorkDribbbleShot = newSocialWorkDribbbleShot
                }

                if let socialWorkDribbbleShot = socialWorkDribbbleShot {
                    let _ = try? realm.write {
                        socialWorkDribbbleShot.synced = true
                    }
                }

                socialWork.dribbbleShot = socialWorkDribbbleShot

                newFeed.socialWork = socialWork

            case .Audio(let audioInfo):

                let feedAudio = FeedAudio()
                feedAudio.feedID = audioInfo.feedID
                feedAudio.URLString = audioInfo.URLString
                feedAudio.metadata = audioInfo.metaData

                newFeed.audio = feedAudio
            }
        }

        newFeed.group = group
        
        let _ = try? realm.write {
            group.groupType = GroupType.Public.rawValue
            realm.add(newFeed)
        }
    }
}

func messageWithMessageID(messageID: String, inRealm realm: Realm) -> Message? {
    if messageID.isEmpty {
        return nil
    }

    let predicate = NSPredicate(format: "messageID = %@", messageID)

    let messages = realm.objects(Message).filter(predicate)
    if messages.count > 1 {
        
        println("Warning: same messageID: \(messages.count), \(messageID)")
        
        // Remove if dupicated
        while messages.count > 1 {
            if let message = messages.last {
                
                let messageID = message.messageID
                
                if let userID = YepUserDefaults.userID.value,
                    nickname = YepUserDefaults.nickname.value{
                        Answers.logCustomEventWithName("Dupicated Message",
                            customAttributes: [
                                "userID": userID,
                                "nickname": nickname,
                                "messageID": messageID,
                                "time": NSDate().description
                            ])
                        
                }
                
                let _ = try? realm.write {
                    realm.delete(message)
                }
            }
        }
        
//        // 治标未读
//        let _ = try? realm.write {
//            for message in messages {
//                message.readed = true
//            }
//        }
    }

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

/*
func messagesOfConversationByMe(conversation: Conversation, inRealm realm: Realm) -> Results<Message> {
    let predicate = NSPredicate(format: "conversation = %@ AND fromFriend.friendState = %d", argumentArray: [conversation, UserFriendState.Me.rawValue])
    let messages = realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
    return messages
}
*/

/*
func messagesUnreadSentByMe(inRealm realm: Realm) -> Results<Message> {
    let predicate = NSPredicate(format: "fromFriend.friendState = %d AND readed = false AND sendState = %d", argumentArray: [ UserFriendState.Me.rawValue, MessageSendState.Successed.rawValue])
    let messages = realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
    return messages
}
*/

/*
func unReadMessagesOfConversation(conversation: Conversation, inRealm realm: Realm) -> Results<Message> {
    let predicate = NSPredicate(format: "conversation = %@ AND readed = false", argumentArray: [conversation])
    let messages = realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
    return messages
}
*/

func messagesOfConversation(conversation: Conversation, inRealm realm: Realm) -> Results<Message> {
    let predicate = NSPredicate(format: "conversation = %@", argumentArray: [conversation])
    let messages = realm.objects(Message).filter(predicate).sorted("createdUnixTime", ascending: true)
    return messages
}

func deleteMessage(message: Message, inRealm realm: Realm) {
    let _ = try? realm.write {
        realm.delete(message)
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

func updateUserWithUserID(userID: String, useUserInfo userInfo: JSONDictionary) {

    guard let realm = try? Realm() else {
        return
    }

    if let user = userWithUserID(userID, inRealm: realm) {

        let _ = try? realm.write {

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

            if let avatarURLString = userInfo["avatar_url"] as? String {
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
}

// MARK: Delete

private func clearMessagesOfConversation(conversation: Conversation, inRealm realm: Realm) {

    let messages = conversation.messages

    // delete attachments of messages

    let _ = try? realm.write {
        messages.forEach { $0.deleteAttachmentInRealm(realm) }
    }

    // delete all mediaMetaDatas

    for message in messages {
        if let mediaMetaData = message.mediaMetaData {
            let _ = try? realm.write {
                realm.delete(mediaMetaData)
            }
        }
    }

    // delete all messages in conversation

    let _ = try? realm.write {
        realm.delete(messages)
    }
}

func deleteConversation(conversation: Conversation, inRealm realm: Realm, needLeaveGroup: Bool = true, afterLeaveGroup: (() -> Void)? = nil) {

    clearMessagesOfConversation(conversation, inRealm: realm)

    // delete conversation, finally

    let _ = try? realm.write {

        if let group = conversation.withGroup {

            if let feed = conversation.withGroup?.withFeed {

                feed.cascadeDelete()
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
}

func tryDeleteOrClearHistoryOfConversation(conversation: Conversation, inViewController vc: UIViewController, whenAfterClearedHistory afterClearedHistory: () -> Void, afterDeleted: () -> Void, orCanceled cancelled: () -> Void) {

    guard let realm = conversation.realm else {
        cancelled()
        return
    }

    let clearMessages: () -> Void = {
        clearMessagesOfConversation(conversation, inRealm: realm)
    }

    let delete: () -> Void = {
        deleteConversation(conversation, inRealm: realm)
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

