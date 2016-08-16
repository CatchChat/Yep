//
//  ConversationsViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift
import Navi
import Kingfisher

let YepNotificationCommentAction = "YepNotificationCommentAction"
let YepNotificationOKAction = "YepNotificationOKAction"

final class ConversationsViewController: BaseViewController {

    private lazy var activityIndicatorTitleView = ActivityIndicatorTitleView(frame: CGRect(x: 0, y: 0, width: 120, height: 30))

    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .Minimal
        searchBar.placeholder = NSLocalizedString("Search", comment: "")
        searchBar.setSearchFieldBackgroundImage(UIImage.yep_searchbarTextfieldBackground, forState: .Normal)
        searchBar.delegate = self
        return searchBar
    }()

    var originalNavigationControllerDelegate: UINavigationControllerDelegate?
    lazy var searchTransition: SearchTransition = {
        return SearchTransition()
    }()

    @IBOutlet weak var conversationsTableView: UITableView! {
        didSet {
            searchBar.sizeToFit()
            conversationsTableView.tableHeaderView = searchBar
            //conversationsTableView.contentOffset.y = CGRectGetHeight(searchBar.frame)
            //println("searchBar.frame: \(searchBar.frame)")

            conversationsTableView.separatorColor = UIColor.yepCellSeparatorColor()
            conversationsTableView.separatorInset = YepConfig.ContactsCell.separatorInset

            conversationsTableView.registerNibOf(FeedConversationDockCell)
            conversationsTableView.registerNibOf(ConversationCell)

            conversationsTableView.rowHeight = 80
            conversationsTableView.tableFooterView = UIView()
        }
    }

    private var realm: Realm!

    private var realmNotificationToken: NotificationToken?

    private var haveUnreadMessages = false {
        didSet {
            if haveUnreadMessages != oldValue {
                if haveUnreadMessages {
                    navigationController?.tabBarItem.image = UIImage.yep_iconChatUnread
                    navigationController?.tabBarItem.selectedImage = UIImage.yep_iconChatActiveUnread

                } else {
                    navigationController?.tabBarItem.image = UIImage.yep_iconChat
                    navigationController?.tabBarItem.selectedImage = UIImage.yep_iconChatActive
                }
            }
        }
    }

    private var unreadMessagesCount: Int = 0 {
        willSet {
            SafeDispatch.async { [weak self] in
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
        return oneToOneConversationsInRealm(self.realm)
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

        realmNotificationToken?.stop()

        println("deinit Conversations")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        realm = try! Realm()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationsViewController.reloadConversationsTableView), name: Config.Notification.newMessages, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationsViewController.reloadConversationsTableView), name: Config.Notification.deletedMessages, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationsViewController.reloadConversationsTableView), name: Config.Notification.changedConversation, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationsViewController.reloadFeedConversationsDock), name: Config.Notification.changedFeedConversation, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationsViewController.reloadConversationsTableView), name: Config.Notification.markAsReaded, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationsViewController.reloadConversationsTableView), name: Config.Notification.updatedUser, object: nil)
        
        // 确保自己发送消息的时候，会话列表也会刷新，避免时间戳不一致
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationsViewController.reloadConversationsTableView), name: Config.Message.Notification.MessageStateChanged, object: nil)

        YepUserDefaults.nickname.bindListener(Listener.Nickname) { [weak self] _ in
            SafeDispatch.async {
                self?.reloadConversationsTableView()
            }
        }

        YepUserDefaults.avatarURLString.bindListener(Listener.Avatar) { [weak self] _ in
            SafeDispatch.async {
                self?.reloadConversationsTableView()
            }
        }

        navigationItem.titleView = activityIndicatorTitleView

        isFetchingUnreadMessages.bindListener(Listener.isFetchingUnreadMessages) { [weak self] isFetching in
            SafeDispatch.async {
                self?.activityIndicatorTitleView.state = isFetching ? .Active : .Normal
            }
        }

        view.backgroundColor = UIColor.whiteColor()

        noConversation = conversations.isEmpty

        realmNotificationToken = realm.addNotificationBlock { [weak self] notification, realm in
            if let strongSelf = self {

                strongSelf.unreadMessagesCount = countOfUnreadMessagesInRealm(realm, withConversationType: .OneToOne)

                let haveOneToOneUnreadMessages = strongSelf.unreadMessagesCount > 0

                strongSelf.haveUnreadMessages = haveOneToOneUnreadMessages || (countOfUnreadMessagesInRealm(realm, withConversationType: .Group) > 0)

                strongSelf.noConversation = countOfConversationsInRealm(realm) == 0
            }
        }

        cacheInAdvance()

        if traitCollection.forceTouchCapability == .Available {
            registerForPreviewingWithDelegate(self, sourceView: conversationsTableView)
        }

        #if DEBUG
            //view.addSubview(conversationsFPSLabel)
        #endif
    }

    private func cacheInAdvance() {

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {

            // 最近两天活跃的好友

            for user in normalFriends().filter("lastSignInUnixTime > %@", NSDate().timeIntervalSince1970 - 60*60*48) {

                do {
                    let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: miniAvatarStyle)
                    AvatarPod.wakeAvatar(userAvatar, completion: { _, _, _ in })
                }

                do {
                    let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: nanoAvatarStyle)
                    AvatarPod.wakeAvatar(userAvatar, completion: { _, _, _ in })
                }
            }
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

        recoverOriginalNavigationDelegate()
    }
    
    private func askForNotification() {

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

        // 这里才开始向用户提示推送
        let types = UIUserNotificationType.Badge.rawValue |
                    UIUserNotificationType.Sound.rawValue |
                    UIUserNotificationType.Alert.rawValue

        JPUSHService.registerForRemoteNotificationTypes(types, categories: [category])
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else { return }

        switch identifier {

        case "showSearchConversations":

            let vc = segue.destinationViewController as! SearchConversationsViewController
            vc.originalNavigationControllerDelegate = navigationController?.delegate

            vc.hidesBottomBarWhenPushed = true

            prepareSearchTransition()

        case "showConversation":

            let vc = segue.destinationViewController as! ConversationViewController
            let conversation = sender as! Conversation
            prepareConversationViewController(vc, withConversation: conversation)

            recoverOriginalNavigationDelegate()

        case "showChat":

            let vc = segue.destinationViewController as! ChatViewController
            let conversation = sender as! Conversation
            vc.conversation = conversation

            recoverOriginalNavigationDelegate()

        case "showProfile":

            let vc = segue.destinationViewController as! ProfileViewController

            let user = sender as! User
            vc.prepare(withUser: user)

            recoverOriginalNavigationDelegate()
            
        default:
            break
        }
    }

    private func prepareConversationViewController(vc: ConversationViewController, withConversation conversation: Conversation) {

        vc.conversation = conversation

        vc.afterSentMessageAction = { // 自己发送消息后，更新 Cell

            SafeDispatch.async { [weak self] in

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

    // MARK: Actions

    @objc private func reloadConversationsTableView() {

        SafeDispatch.async { [weak self] in
            self?.conversationsTableView.reloadData()
        }
    }

    @objc private func reloadFeedConversationsDock() {

        SafeDispatch.async { [weak self] in
            let sectionIndex = Section.FeedConversation.rawValue
            guard (self?.conversationsTableView.numberOfSections ?? 0) > sectionIndex else {
                self?.conversationsTableView.reloadData()
                return
            }

            self?.conversationsTableView.reloadSections(NSIndexSet(index: sectionIndex), withRowAnimation: .None)
        }
    }
}

// MARK: - UISearchBarDelegate

extension ConversationsViewController: UISearchBarDelegate {

    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {

        performSegueWithIdentifier("showSearchConversations", sender: nil)

        return false
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
            let cell: FeedConversationDockCell = tableView.dequeueReusableCell()
            return cell

        case Section.Conversation.rawValue:
            let cell: ConversationCell = tableView.dequeueReusableCell()
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
            let latestUnreadMessage = latestUnreadValidMessageInRealm(realm, withConversationType: .Group)
            // 找不到就找最新的消息
            if let latestMessage = (latestUnreadMessage ?? latestValidMessageInRealm(realm, withConversationType: .Group)) {

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

                #if ASYNC_DISPLAY
                    let conversation = cell.conversation
                    if conversation.withFriend?.username == "init" || conversation.withFriend?.username == "nixzhu" {
                        performSegueWithIdentifier("showChat", sender: cell.conversation)
                    } else {
                        performSegueWithIdentifier("showConversation", sender: cell.conversation)
                    }
                #else
                    performSegueWithIdentifier("showConversation", sender: cell.conversation)
                #endif
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

            let conversationsCountBeforeDelete = conversations.count

            tryDeleteOrClearHistoryOfConversation(conversation, inViewController: self, whenAfterClearedHistory: {

                SafeDispatch.async { [weak self, weak tableView] in

                    guard let tableView = tableView else { return }

                    tableView.setEditing(false, animated: true)

                    // update cell

                    if let cell = tableView.cellForRowAtIndexPath(indexPath) as? ConversationCell {
                        if let conversation = self?.conversations[safe: indexPath.row] {
                            let radius = min(CGRectGetWidth(cell.avatarImageView.bounds), CGRectGetHeight(cell.avatarImageView.bounds)) * 0.5
                            cell.configureWithConversation(conversation, avatarRadius: radius, tableView: tableView, indexPath: indexPath)
                        }
                    }
                }

            }, afterDeleted: {
                SafeDispatch.async { [weak self, weak tableView] in

                    guard let strongSelf = self else { return }

                    // double check
                    // NOTICE: conversations.count less than conversationsCountBeforeDelete by 1
                    guard conversationsCountBeforeDelete == (strongSelf.conversations.count + 1) else {
                        tableView?.reloadData()
                        return
                    }

                    tableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }

            }, orCanceled: {
                SafeDispatch.async { [weak tableView] in
                    tableView?.setEditing(false, animated: true)
                }
            })
        }
    }
}

// MARK: - UIViewControllerPreviewingDelegate

extension ConversationsViewController: UIViewControllerPreviewingDelegate {

    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        guard let indexPath = conversationsTableView.indexPathForRowAtPoint(location), cell = conversationsTableView.cellForRowAtIndexPath(indexPath) else {
            return nil
        }

        previewingContext.sourceRect = cell.frame

        guard let section = Section(rawValue: indexPath.section) else {
            return nil
        }

        switch section {

        case .FeedConversation:
            return nil

        case .Conversation:

            let vc = UIStoryboard.Scene.conversation
            let conversation = conversations[indexPath.row]
            prepareConversationViewController(vc, withConversation: conversation)

            recoverOriginalNavigationDelegate()

            vc.isPreviewed = true

            return vc
        }
    }

    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {

        showViewController(viewControllerToCommit, sender: self)
    }
}
