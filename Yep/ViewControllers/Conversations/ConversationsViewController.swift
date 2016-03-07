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

class ConversationsViewController: SegueViewController {

    private lazy var activityIndicatorTitleView = ActivityIndicatorTitleView(frame: CGRect(x: 0, y: 0, width: 120, height: 30))

    @IBOutlet weak var conversationsTableView: UITableView!

    private let feedConversationDockCellID = "FeedConversationDockCell"
    private let cellIdentifier = "ConversationCell"

    private var realm: Realm!

    private var realmNotificationToken: NotificationToken?

    private var haveUnreadMessages = false {
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

    private var unreadMessagesCount: Int = 0 {
        willSet {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                if newValue > 0 {
                    self?.navigationItem.title = "Yep(\(newValue))"
                } else {
                    self?.navigationItem.title = "Yep"
                }
            }

            //println("unreadMessagesCount: \(unreadMessagesCount)")
        }
    }

    private lazy var noConversationFooterView: InfoView = InfoView(NSLocalizedString("Have a nice day!", comment: ""))

    private var noConversation = false {
        didSet {
            if noConversation != oldValue {
                conversationsTableView.tableFooterView = UIView()
            }
        }
    }

    #if DEBUG
    private lazy var conversationsFPSLabel: FPSLabel = {
        let label = FPSLabel()
        return label
    }()
    #endif

    private lazy var conversations: Results<Conversation> = {
        let predicate = NSPredicate(format: "type = %d", ConversationType.OneToOne.rawValue)
        return self.realm.objects(Conversation).filter(predicate).sorted("updatedUnixTime", ascending: false)
    }()

    private struct Listener {
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

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadConversationsTableView", name: YepConfig.Notification.deletedMessages, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadConversationsTableView", name: YepConfig.Notification.changedConversation, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadFeedConversationsDock", name: YepConfig.Notification.changedFeedConversation, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadConversationsTableView", name: YepConfig.Notification.markAsReaded, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadConversationsTableView", name: YepConfig.Notification.updatedUser, object: nil)
        
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

                strongSelf.unreadMessagesCount = countOfUnreadMessagesInRealm(realm, withConversationType: .OneToOne)

                let haveOneToOneUnreadMessages = strongSelf.unreadMessagesCount > 0

                strongSelf.haveUnreadMessages = haveOneToOneUnreadMessages || (countOfUnreadMessagesInRealm(realm, withConversationType: .Group) > 0)

                strongSelf.noConversation = countOfConversationsInRealm(realm) == 0
            }
        }

        if PrivateResource.Location(.WhenInUse).isAuthorized {
            YepLocationService.turnOn()
        }

        cacheInAdvance()

        #if DEBUG
            //view.addSubview(conversationsFPSLabel)
        #endif
    }

    private func cacheInAdvance() {

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {

            // 最近一天活跃的好友

            for user in normalFriends().filter("lastSignInUnixTime > %@", NSDate().timeIntervalSince1970 - 60*60*24) {

                do {
                    let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: miniAvatarStyle)
                    AvatarPod.wakeAvatar(userAvatar, completion: { _, _, _ in })
                }

                do {
                    let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: nanoAvatarStyle)
                    AvatarPod.wakeAvatar(userAvatar, completion: { _, _, _ in })
                }
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

    var isFirstAppear = true

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if isFirstAppear {
            delay(0.5) { [weak self] in
                self?.askForNotification()
            }
        }

        isFirstAppear = false
    }
    
    private func askForNotification() {

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
            
            //JPUSHService.registerForRemoteNotificationTypes(
            APService.registerForRemoteNotificationTypes(
                UIUserNotificationType.Badge.rawValue |
                    UIUserNotificationType.Sound.rawValue |
                    UIUserNotificationType.Alert.rawValue, categories: [category])
            
        } else {
            // 这里才开始向用户提示推送
            //JPUSHService.registerForRemoteNotificationTypes(
            APService.registerForRemoteNotificationTypes(
                UIUserNotificationType.Badge.rawValue |
                    UIUserNotificationType.Sound.rawValue |
                    UIUserNotificationType.Alert.rawValue, categories: nil)
        }
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else { return }

        switch identifier {

        case "showConversation":

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

        case "showProfile":

            let vc = segue.destinationViewController as! ProfileViewController

            let user = sender as! User
            vc.profileUser = ProfileUser.UserType(user)

            vc.setBackButtonWithTitle()
            
        default:
            break
        }
    }

    // MARK: Actions

    @objc private func reloadConversationsTableView() {
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.conversationsTableView.reloadData()
        }
    }

    @objc private func reloadFeedConversationsDock() {
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            let sectionIndex = Section.FeedConversation.rawValue
            guard self?.conversationsTableView.numberOfSections ?? 0 > sectionIndex else {
                return
            }

            self?.conversationsTableView.reloadSections(NSIndexSet(index: sectionIndex), withRowAnimation: .None)
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegat

extension ConversationsViewController: UITableViewDataSource, UITableViewDelegate {

    private enum Section: Int {

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
            return cell

        case Section.Conversation.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ConversationCell
            return cell
            
        default:
            return UITableViewCell()
        }
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        switch indexPath.section {

        case Section.FeedConversation.rawValue:

            guard let cell = cell as? FeedConversationDockCell else {
                break
            }

            cell.haveGroupUnreadMessages = countOfUnreadMessagesInRealm(realm, withConversationType: ConversationType.Group) > 0

            // 先找最新且未读的消息
            let latestUnreadMessage = latestUnreadValidMessageInRealm(realm, withConversationType: ConversationType.Group)
            // 找不到就找最新的消息
            if let latestMessage = (latestUnreadMessage ?? latestValidMessageInRealm(realm, withConversationType: ConversationType.Group)) {

                if let mediaType = MessageMediaType(rawValue: latestMessage.mediaType), placeholder = mediaType.placeholder {
                    cell.chatLabel.text = placeholder

                } else {
                    if mentionedMeInFeedConversationsInRealm(realm) {
                        let mentionedYouString = NSLocalizedString("[Mentioned you]", comment: "")
                        let string = mentionedYouString + " " + latestMessage.nicknameWithTextContent

                        let attributedString = NSMutableAttributedString(string: string)
                        let mentionedYouRange = NSMakeRange(0, (mentionedYouString as NSString).length)
                        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: mentionedYouRange)

                        cell.chatLabel.attributedText = attributedString

                    } else {
                        cell.chatLabel.text = latestMessage.nicknameWithTextContent
                    }
                }

            } else {
                cell.chatLabel.text = NSLocalizedString("No messages yet.", comment: "")
            }

        case Section.Conversation.rawValue:

            guard let cell = cell as? ConversationCell else {
                break
            }

            if let conversation = conversations[safe: indexPath.row] {

                let radius = YepConfig.ConversationCell.avatarSize * 0.5

                cell.configureWithConversation(conversation, avatarRadius: radius, tableView: tableView, indexPath: indexPath)
            }
            
        default:
            break
        }
    }

    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        switch indexPath.section {

        case Section.FeedConversation.rawValue:
            break

        case Section.Conversation.rawValue:

            guard let cell = cell as? ConversationCell else {
                return
            }

            cell.avatarImageView.image = nil

        default:
            break
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

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

