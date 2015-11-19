//
//  ConversationsViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import Navi
import Kingfisher
import Proposer

let YepNotificationCommentAction = "YepNotificationCommentAction"
let YepNotificationOKAction = "YepNotificationOKAction"

class ConversationsViewController: UIViewController {

    lazy var activityIndicatorTitleView = ActivityIndicatorTitleView(frame: CGRect(x: 0, y: 0, width: 120, height: 30))

    @IBOutlet weak var conversationsTableView: UITableView!

    let feedConversationDockCellID = "FeedConversationDockCell"
    let cellIdentifier = "ConversationCell"

    var realm: Realm!

    var realmNotificationToken: NotificationToken?

    var haveUnreadMessages = false {
        didSet {
            if haveUnreadMessages != oldValue {
                if haveUnreadMessages {
                    navigationController?.tabBarItem.image = UIImage(named: "icon_chat_unread")
                    navigationController?.tabBarItem.selectedImage = UIImage(named: "icon_chat_active_unread")

                } else {
                    navigationController?.tabBarItem.image = UIImage(named: "icon_chat")
                    navigationController?.tabBarItem.selectedImage = UIImage(named: "icon_chat_active")
                }
            }
        }
    }

    lazy var noConversationFooterView: InfoView = InfoView(NSLocalizedString("Have a nice day!", comment: ""))

    var noConversation = false {
        didSet {
            if noConversation != oldValue {
                conversationsTableView.tableFooterView = UIView()
            }
        }
    }

    lazy var conversations: Results<Conversation> = {
        let predicate = NSPredicate(format: "type = %d", ConversationType.OneToOne.rawValue)
        return self.realm.objects(Conversation).filter(predicate).sorted("updatedUnixTime", ascending: false)
        }()

    struct Listener {
        static let Nickname = "ConversationsViewController.Nickname"
        static let Avatar = "ConversationsViewController.Avatar"

        static let isFetchingUnreadMessages = "ConversationsViewController.isFetchingUnreadMessages"
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)

        YepUserDefaults.avatarURLString.removeListenerWithName(Listener.Avatar)
        YepUserDefaults.nickname.removeListenerWithName(Listener.Nickname)

        isFetchingUnreadMessages.removeListenerWithName(Listener.isFetchingUnreadMessages)

        conversationsTableView?.delegate = nil

        println("deinit Conversations")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        realm = try! Realm()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadConversationsTableView", name: YepConfig.Notification.newMessages, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadConversationsTableView", name: YepConfig.Notification.changedConversation, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadConversationsTableView", name: YepConfig.Notification.markAsReaded, object: nil)
        
        // 确保自己发送消息的时候，会话列表也会刷新，避免时间戳不一致
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadConversationsTableView", name: MessageNotification.MessageStateChanged, object: nil)

        YepUserDefaults.nickname.bindListener(Listener.Nickname) { [weak self] _ in
            dispatch_async(dispatch_get_main_queue()) {
                self?.reloadConversationsTableView()
            }
        }

        YepUserDefaults.avatarURLString.bindListener(Listener.Avatar) { [weak self] _ in
            dispatch_async(dispatch_get_main_queue()) {
                self?.reloadConversationsTableView()
            }
        }

        navigationItem.titleView = activityIndicatorTitleView

        isFetchingUnreadMessages.bindListener(Listener.isFetchingUnreadMessages) { [weak self] isFetching in
            dispatch_async(dispatch_get_main_queue()) {
                self?.activityIndicatorTitleView.state = isFetching ? .Active : .Normal
            }
        }

        view.backgroundColor = UIColor.whiteColor()

        conversationsTableView.separatorColor = UIColor.yepCellSeparatorColor()
        conversationsTableView.separatorInset = YepConfig.ContactsCell.separatorInset

        conversationsTableView.registerNib(UINib(nibName: feedConversationDockCellID, bundle: nil), forCellReuseIdentifier: feedConversationDockCellID)
        conversationsTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        conversationsTableView.rowHeight = 80
        conversationsTableView.tableFooterView = UIView()

        noConversation = conversations.isEmpty

        realmNotificationToken = realm.addNotificationBlock { [weak self] notification, realm in
            if let strongSelf = self {

                let haveOneToOneUnreadMessages = countOfUnreadMessagesInRealm(realm, withConversationType: ConversationType.OneToOne) > 0

                strongSelf.haveUnreadMessages = haveOneToOneUnreadMessages || (countOfUnreadMessagesInRealm(realm) > 0)

                strongSelf.noConversation = countOfConversationsInRealm(realm) == 0
            }
        }

        if PrivateResource.Location(.WhenInUse).isAuthorized {
            YepLocationService.turnOn()
        }

        tokensOfSocialAccounts(failureHandler: nil, completion: { tokensOfSocialAccounts in
            println("tokensOfSocialAccounts: \(tokensOfSocialAccounts)")

            func syncSocialWorkPiece(socialWorkPiece: SocialWorkPiece, yepTeam: User, inRealm realm: Realm) {

                let messageID = socialWorkPiece.messageID

                var message = messageWithMessageID(messageID, inRealm: realm)

                guard message == nil else {
                    return
                }

                if message == nil {
                    let newMessage = Message()
                    newMessage.messageID = messageID
                    newMessage.mediaType = MessageMediaType.SocialWork.rawValue

                    let socialWork = MessageSocialWork()
                    socialWork.type = socialWorkPiece.messageSocialWorkType.rawValue

                    switch socialWorkPiece {
                    case .Github(let repo):
                        let socialWorkGithubRepo = SocialWorkGithubRepo()
                        socialWorkGithubRepo.fillWithGithubRepo(repo)

                        socialWork.githubRepo = socialWorkGithubRepo

                    case .Dribbble(let shot):
                        let socialWorkDribbbleShot = SocialWorkDribbbleShot()
                        socialWorkDribbbleShot.fillWithDribbbleShot(shot)

                        socialWork.dribbbleShot = socialWorkDribbbleShot

                    case .Instagram(let media):
                        break
                    }

                    newMessage.socialWork = socialWork

                    let _ = try? realm.write {
                        realm.add(newMessage)
                    }

                    message = newMessage
                }

                if let message = message {
                    let _ = try? realm.write {
                        message.fromFriend = yepTeam
                    }

                    var conversation = yepTeam.conversation

                    if conversation == nil {
                        let newConversation = Conversation()

                        newConversation.type = ConversationType.OneToOne.rawValue
                        newConversation.withFriend = yepTeam

                        let _ = try? realm.write {
                            realm.add(newConversation)
                        }

                        conversation = newConversation
                    }

                    if let conversation = conversation {
                        let _ = try? realm.write {

                            conversation.updatedUnixTime = message.createdUnixTime

                            message.conversation = conversation

                            var sectionDateMessageID: String?
                            tryCreateSectionDateMessageInConversation(conversation, beforeMessage: message, inRealm: realm) { sectionDateMessage in
                                realm.add(sectionDateMessage)
                                sectionDateMessageID = sectionDateMessage.messageID
                            }

                            // 通知更新 UI

                            var messageIDs = [String]()
                            if let sectionDateMessageID = sectionDateMessageID {
                                messageIDs.append(sectionDateMessageID)
                            }
                            messageIDs.append(message.messageID)

                            tryPostNewMessagesReceivedNotificationWithMessageIDs(messageIDs, messageAge: .New)
                        }

                    } else {
                        deleteMessage(message, inRealm: realm)
                    }
                }
            }

            let yepTeamUsername = "yep_team"

            func yepTeamFromDiscoveredUser(discoveredUser: DiscoveredUser, inRealm realm: Realm) -> User? {

                var yepTeam = userWithUsername(yepTeamUsername, inRealm: realm)

                if yepTeam == nil {
                    let newYepTeam = User()
                    newYepTeam.userID = discoveredUser.id
                    newYepTeam.username = discoveredUser.username ?? ""
                    newYepTeam.nickname = discoveredUser.nickname
                    newYepTeam.introduction = discoveredUser.introduction ?? ""
                    newYepTeam.avatarURLString = discoveredUser.avatarURLString
                    newYepTeam.badge = discoveredUser.badge ?? ""

                    newYepTeam.friendState = UserFriendState.Yep.rawValue

                    let _ = try? realm.write {
                        realm.add(newYepTeam)
                    }

                    yepTeam = newYepTeam
                }

                return yepTeam
            }

            if let githubToken = tokensOfSocialAccounts.githubToken {

                githubReposWithToken(githubToken, failureHandler: nil, completion: { githubRepos in
                    println("githubRepos count: \(githubRepos.count)")

                    guard let latestRepo = githubRepos.first, realm = try? Realm() else {
                        return
                    }

                    if let yepTeam = userWithUsername(yepTeamUsername, inRealm: realm) {
                        syncSocialWorkPiece(SocialWorkPiece.Github(latestRepo), yepTeam: yepTeam, inRealm: realm)

                    } else {
                        discoverUserByUsername(yepTeamUsername, failureHandler: nil, completion: { discoveredUser in
                            dispatch_async(dispatch_get_main_queue()) {

                                guard let realm = try? Realm() else {
                                    return
                                }

                                if let yepTeam = yepTeamFromDiscoveredUser(discoveredUser, inRealm: realm) {
                                    syncSocialWorkPiece(SocialWorkPiece.Github(latestRepo), yepTeam: yepTeam, inRealm: realm)
                                }
                            }
                        })
                    }
                })
            }

            if let dribbbleToken = tokensOfSocialAccounts.dribbbleToken {

                dribbbleShotsWithToken(dribbbleToken, failureHandler: nil, completion: { dribbbleShots in
                    println("dribbbleShots count: \(dribbbleShots.count)")

                    guard let latestShot = dribbbleShots.first, realm = try? Realm() else {
                        return
                    }

                    if let yepTeam = userWithUsername(yepTeamUsername, inRealm: realm) {
                        syncSocialWorkPiece(SocialWorkPiece.Dribbble(latestShot), yepTeam: yepTeam, inRealm: realm)

                    } else {
                        discoverUserByUsername(yepTeamUsername, failureHandler: nil, completion: { discoveredUser in
                            dispatch_async(dispatch_get_main_queue()) {

                                guard let realm = try? Realm() else {
                                    return
                                }

                                if let yepTeam = yepTeamFromDiscoveredUser(discoveredUser, inRealm: realm) {
                                    syncSocialWorkPiece(SocialWorkPiece.Dribbble(latestShot), yepTeam: yepTeam, inRealm: realm)
                                }
                            }
                        })
                    }
               })
            }

            if let instagramToken = tokensOfSocialAccounts.instagramToken {

                instagramMediasWithToken(instagramToken, failureHandler: nil, completion: { instagramMedias in
                    println("instagramMedias count: \(instagramMedias.count)")
                })
            }
        })
    }

    private func cacheInAdvance() {

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

            // 聊天界面的小头像

            for user in normalUsers() {

                let userAvatar = UserAvatar(userID: user.userID, avatarStyle: nanoAvatarStyle)
                AvatarPod.wakeAvatar(userAvatar, completion: { _, _ in })
            }

            /*
            // 每个对话的最近 10 条消息（image or thumbnail）

            guard let realm = try? Realm() else {
                return
            }

            for conversation in realm.objects(Conversation) {

                let messages = messagesOfConversation(conversation, inRealm: realm)

                let latestBatch = min(10, messages.count)

                let messageImagePreferredWidth = YepConfig.ChatCell.mediaPreferredWidth
                let messageImagePreferredHeight = YepConfig.ChatCell.mediaPreferredHeight

                for i in (messages.count - latestBatch)..<messages.count {

                    let message = messages[i]

                    if let user = message.fromFriend {

                        let tailDirection: MessageImageTailDirection = user.friendState != UserFriendState.Me.rawValue ? .Left : .Right

                        switch message.mediaType {

                        case MessageMediaType.Image.rawValue:

                            if let (imageWidth, imageHeight) = imageMetaOfMessage(message) {

                                let aspectRatio = imageWidth / imageHeight

                                let messageImagePreferredWidth = max(messageImagePreferredWidth, ceil(YepConfig.ChatCell.mediaMinHeight * aspectRatio))
                                let messageImagePreferredHeight = max(messageImagePreferredHeight, ceil(YepConfig.ChatCell.mediaMinWidth / aspectRatio))

                                if aspectRatio >= 1 {
                                    ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / aspectRatio)), tailDirection: tailDirection, completion: { _ in
                                    })

                                } else {
                                    ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredHeight * aspectRatio, height: messageImagePreferredHeight), tailDirection: tailDirection, completion: { _ in
                                    })
                                }
                            }

                        case MessageMediaType.Video.rawValue:

                            if let (videoWidth, videoHeight) = videoMetaOfMessage(message) {
                                let aspectRatio = videoWidth / videoHeight

                                let messageImagePreferredWidth = max(messageImagePreferredWidth, ceil(YepConfig.ChatCell.mediaMinHeight * aspectRatio))
                                let messageImagePreferredHeight = max(messageImagePreferredHeight, ceil(YepConfig.ChatCell.mediaMinWidth / aspectRatio))

                                if aspectRatio >= 1 {
                                    ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / aspectRatio)), tailDirection: tailDirection, completion: { _ in
                                    })

                                } else {
                                    ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredHeight * aspectRatio, height: messageImagePreferredHeight), tailDirection: tailDirection, completion: { _ in
                                    })
                                }
                            }

                        default:
                            break
                        }
                    }
                }
            }
            */
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        delay(0.5) { [weak self] in
            self?.askForNotification()
        }

        // 预先生成小头像
        cacheInAdvance()
    }
    
    func askForNotification() {

        if #available(iOS 9.0, *) {
            
            let replyAction = UIMutableUserNotificationAction()
            replyAction.title = NSLocalizedString("Reply", comment: "")
            replyAction.identifier = YepNotificationCommentAction
            replyAction.activationMode = .Background
            replyAction.behavior = .TextInput
            replyAction.authenticationRequired = false
            
            let replyOKAction = UIMutableUserNotificationAction()
            replyOKAction.title = "OK"
            replyOKAction.identifier = YepNotificationOKAction
            replyOKAction.activationMode = .Background
            replyOKAction.behavior = .Default
            replyOKAction.authenticationRequired = false
            
            let category = UIMutableUserNotificationCategory()
            category.identifier = "YepMessageNotification"
            category.setActions([replyAction, replyOKAction], forContext: UIUserNotificationActionContext.Minimal)
            
            APService.registerForRemoteNotificationTypes(
                UIUserNotificationType.Badge.rawValue |
                    UIUserNotificationType.Sound.rawValue |
                    UIUserNotificationType.Alert.rawValue, categories: [category])
            
        } else {
            // 这里才开始向用户提示推送
            APService.registerForRemoteNotificationTypes(
                UIUserNotificationType.Badge.rawValue |
                    UIUserNotificationType.Sound.rawValue |
                    UIUserNotificationType.Alert.rawValue, categories: nil)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showConversation" {
            let vc = segue.destinationViewController as! ConversationViewController

            let conversation = sender as! Conversation
            vc.conversation = conversation

            vc.afterSentMessageAction = { // 自己发送消息后，更新 Cell

                dispatch_async(dispatch_get_main_queue()) { [weak self] in

                    guard let row = self?.conversations.indexOf(conversation) else {
                        return
                    }

                    let indexPath = NSIndexPath(forRow: row, inSection: Section.Conversation.rawValue)

                    if let cell = self?.conversationsTableView.cellForRowAtIndexPath(indexPath) as? ConversationCell {
                        cell.updateInfoLabels()
                    }
                }
            }
        }
    }

    // MARK: Actions

    func reloadConversationsTableView() {
        dispatch_async(dispatch_get_main_queue()) {
            self.conversationsTableView.reloadData()
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegat

extension ConversationsViewController: UITableViewDataSource, UITableViewDelegate {

    enum Section: Int {

        case FeedConversation
        case Conversation
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.FeedConversation.rawValue:
            return 1
        case Section.Conversation.rawValue:
            return conversations.count
        default:
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        switch indexPath.section {

        case Section.FeedConversation.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier(feedConversationDockCellID) as! FeedConversationDockCell

            cell.haveGroupUnreadMessages = countOfUnreadMessagesInRealm(realm, withConversationType: ConversationType.Group) > 0

            if let latestMessage = latestMessageInRealm(realm, withConversationType: ConversationType.Group) {

                if let mediaType = MessageMediaType(rawValue: latestMessage.mediaType), placeholder = mediaType.placeholder {
                    cell.chatLabel.text = placeholder
                } else {
                    cell.chatLabel.text = latestMessage.textContent
                }

            } else {
                cell.chatLabel.text = NSLocalizedString("No messages yet.", comment: "")
            }

            return cell

        case Section.Conversation.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ConversationCell

            if let conversation = conversations[safe: indexPath.row] {

                let radius = YepConfig.ConversationCell.avatarSize * 0.5

                cell.configureWithConversation(conversation, avatarRadius: radius, tableView: tableView, indexPath: indexPath)
            }
            
            return cell
            
        default:
            return UITableViewCell()
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        switch indexPath.section {

        case Section.FeedConversation.rawValue:
            performSegueWithIdentifier("showFeedConversations", sender: nil)

        case Section.Conversation.rawValue:
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? ConversationCell {
                performSegueWithIdentifier("showConversation", sender: cell.conversation)
            }

        default:
            break
        }
    }

    // Edit (for Delete)

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {

        if indexPath.section == Section.Conversation.rawValue {
            return true
        }

        return false
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        if editingStyle == .Delete {
            
            guard let conversation = conversations[safe: indexPath.row] else {
                tableView.setEditing(false, animated: true)
                return
            }
            
            tryDeleteOrClearHistoryOfConversation(conversation, inViewController: self, whenAfterClearedHistory: {

                tableView.setEditing(false, animated: true)

                // update cell

                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? ConversationCell {
                    if let conversation = self.conversations[safe: indexPath.row] {
                        let radius = min(CGRectGetWidth(cell.avatarImageView.bounds), CGRectGetHeight(cell.avatarImageView.bounds)) * 0.5
                        cell.configureWithConversation(conversation, avatarRadius: radius, tableView: tableView, indexPath: indexPath)
                    }
                }

            }, afterDeleted: {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

            }, orCanceled: {
                tableView.setEditing(false, animated: true)
            })
        }
    }
}

