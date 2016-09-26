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

final class ConversationsViewController: BaseViewController, CanScrollsToTop {

    fileprivate lazy var activityIndicatorTitleView = ActivityIndicatorTitleView(frame: CGRect(x: 0, y: 0, width: 120, height: 30))

    fileprivate lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = NSLocalizedString("Search", comment: "")
        searchBar.setSearchFieldBackgroundImage(UIImage.yep_searchbarTextfieldBackground, for: UIControlState())
        searchBar.delegate = self
        return searchBar
    }()

    var originalNavigationControllerDelegate: UINavigationControllerDelegate?
    lazy var searchTransition: SearchTransition = {
        return SearchTransition()
    }()

    @IBOutlet fileprivate weak var conversationsTableView: UITableView! {
        didSet {
            searchBar.sizeToFit()
            conversationsTableView.tableHeaderView = searchBar
            //conversationsTableView.contentOffset.y = CGRectGetHeight(searchBar.frame)
            //println("searchBar.frame: \(searchBar.frame)")

            conversationsTableView.separatorColor = UIColor.yepCellSeparatorColor()
            conversationsTableView.separatorInset = YepConfig.ContactsCell.separatorInset

            conversationsTableView.registerNibOf(FeedConversationDockCell.self)
            conversationsTableView.registerNibOf(ConversationCell.self)

            conversationsTableView.rowHeight = 80
            conversationsTableView.tableFooterView = UIView()
        }
    }

    // CanScrollsToTop
    var scrollView: UIScrollView? {
        return conversationsTableView
    }

    fileprivate var realm: Realm!

    fileprivate var realmNotificationToken: NotificationToken?

    fileprivate var haveUnreadMessages = false {
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

    fileprivate var unreadMessagesCount: Int = 0 {
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

    fileprivate lazy var noConversationFooterView: InfoView = InfoView(String.trans_promptHaveANiceDay)

    fileprivate var noConversation = false {
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

    fileprivate lazy var conversations: Results<Conversation> = {
        return oneToOneConversationsInRealm(self.realm)
    }()

    fileprivate struct Listener {
        static let Nickname = "ConversationsViewController.Nickname"
        static let Avatar = "ConversationsViewController.Avatar"

        static let isFetchingUnreadMessages = "ConversationsViewController.isFetchingUnreadMessages"
    }

    deinit {
        NotificationCenter.default.removeObserver(self)

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

        navigationItem.titleView = activityIndicatorTitleView

        view.backgroundColor = UIColor.white

        NotificationCenter.default.addObserver(self, selector: #selector(ConversationsViewController.reloadConversationsTableView), name: NSNotification.Name(rawValue: Config.Notification.newMessages), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ConversationsViewController.reloadConversationsTableView), name: NSNotification.Name(rawValue: Config.Notification.deletedMessages), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ConversationsViewController.reloadConversationsTableView), name: NSNotification.Name(rawValue: Config.Notification.changedConversation), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ConversationsViewController.reloadFeedConversationsDock), name: NSNotification.Name(rawValue: Config.Notification.changedFeedConversation), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ConversationsViewController.reloadConversationsTableView), name: NSNotification.Name(rawValue: Config.Notification.markAsReaded), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ConversationsViewController.reloadConversationsTableView), name: NSNotification.Name(rawValue: Config.Notification.updatedUser), object: nil)
        
        // 确保自己发送消息的时候，会话列表也会刷新，避免时间戳不一致
        NotificationCenter.default.addObserver(self, selector: #selector(ConversationsViewController.reloadConversationsTableView), name: NSNotification.Name(rawValue: Config.Message.Notification.MessageStateChanged), object: nil)

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

        isFetchingUnreadMessages.bindListener(Listener.isFetchingUnreadMessages) { [weak self] isFetching in
            SafeDispatch.async {
                self?.activityIndicatorTitleView.state = isFetching ? .active : .normal
            }
        }

        noConversation = conversations.isEmpty

        realmNotificationToken = realm.addNotificationBlock { [weak self] notification, realm in
            if let strongSelf = self {

                strongSelf.unreadMessagesCount = countOfUnreadMessagesInRealm(realm, withConversationType: .oneToOne)

                let haveOneToOneUnreadMessages = strongSelf.unreadMessagesCount > 0
                strongSelf.haveUnreadMessages = haveOneToOneUnreadMessages || (countOfUnreadMessagesInRealm(realm, withConversationType: .group) > 0)
                /*
                let predicate = YepConfig.Conversation.hasUnreadMessagesPredicate
                let haveUnreadMessages = (!strongSelf.conversations.filter(predicate).isEmpty)
                    || (!feedConversationsInRealm(realm).filter(predicate).isEmpty)
                strongSelf.haveUnreadMessages = haveUnreadMessages
                 */

                strongSelf.noConversation = countOfConversationsInRealm(realm) == 0
            }
        }

        cacheInAdvance()

        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: conversationsTableView)
        }

        #if DEBUG
            //view.addSubview(conversationsFPSLabel)
        #endif
    }

    fileprivate func cacheInAdvance() {

        DispatchQueue.global(qos: .background).async {

            // 最近两天活跃的好友

            for user in normalFriends().filter("lastSignInUnixTime > %@", Date().timeIntervalSince1970 - 60*60*48) {

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isFirstAppear {
            _ = delay(0.5) { [weak self] in
                self?.askForRemotePushNotifications()
            }
        }

        isFirstAppear = false

        recoverOriginalNavigationDelegate()
    }
    
    fileprivate func askForRemotePushNotifications() {

        let replyAction = UIMutableUserNotificationAction()
        replyAction.title = NSLocalizedString("Reply", comment: "")
        replyAction.identifier = YepNotificationCommentAction
        replyAction.activationMode = .background
        replyAction.behavior = .textInput
        replyAction.isAuthenticationRequired = false

        let replyOKAction = UIMutableUserNotificationAction()
        replyOKAction.title = String.trans_titleOK
        replyOKAction.identifier = YepNotificationOKAction
        replyOKAction.activationMode = .background
        replyOKAction.behavior = .default
        replyOKAction.isAuthenticationRequired = false

        let category = UIMutableUserNotificationCategory()
        category.identifier = "YepMessageNotification"
        category.setActions([replyAction, replyOKAction], for: UIUserNotificationActionContext.minimal)

        // 这里才开始向用户提示推送
        let types = UIUserNotificationType.badge.rawValue |
                    UIUserNotificationType.sound.rawValue |
                    UIUserNotificationType.alert.rawValue

        JPUSHService.register(forRemoteNotificationTypes: types, categories: [category])
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let identifier = segue.identifier else { return }

        switch identifier {

        case "showSearchConversations":

            let vc = segue.destination as! SearchConversationsViewController
            vc.originalNavigationControllerDelegate = navigationController?.delegate

            vc.hidesBottomBarWhenPushed = true

            prepareSearchTransition()

        case "showConversation":

            let vc = segue.destination as! ConversationViewController
            let conversation = sender as! Conversation
            prepareConversationViewController(vc, withConversation: conversation)

            recoverOriginalNavigationDelegate()

        case "showProfile":

            let vc = segue.destination as! ProfileViewController

            let user = sender as! User
            vc.prepare(withUser: user)

            recoverOriginalNavigationDelegate()
            
        default:
            break
        }
    }

    fileprivate func prepareConversationViewController(_ vc: ConversationViewController, withConversation conversation: Conversation) {

        vc.conversation = conversation

        vc.afterSentMessageAction = { // 自己发送消息后，更新 Cell

            SafeDispatch.async { [weak self] in

                guard let row = self?.conversations.index(of: conversation) else {
                    return
                }

                let indexPath = IndexPath(row: row, section: Section.conversation.rawValue)

                if let cell = self?.conversationsTableView.cellForRow(at: indexPath) as? ConversationCell {
                    cell.updateInfoLabels()
                }
            }
        }
    }

    // MARK: Actions

    @objc fileprivate func reloadConversationsTableView() {

        SafeDispatch.async { [weak self] in
            self?.conversationsTableView.reloadData()
        }
    }

    @objc fileprivate func reloadFeedConversationsDock() {

        SafeDispatch.async { [weak self] in
            let sectionIndex = Section.feedConversation.rawValue
            guard (self?.conversationsTableView.numberOfSections ?? 0) > sectionIndex else {
                self?.conversationsTableView.reloadData()
                return
            }

            self?.conversationsTableView.reloadSections(IndexSet(integer: sectionIndex), with: .none)
        }
    }
}

// MARK: - UISearchBarDelegate

extension ConversationsViewController: UISearchBarDelegate {

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {

        performSegue(withIdentifier: "showSearchConversations", sender: nil)

        return false
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegat

extension ConversationsViewController: UITableViewDataSource, UITableViewDelegate {

    fileprivate enum Section: Int {

        case feedConversation
        case conversation
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.feedConversation.rawValue:
            return 1
        case Section.conversation.rawValue:
            return conversations.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch (indexPath as NSIndexPath).section {

        case Section.feedConversation.rawValue:
            let cell: FeedConversationDockCell = tableView.dequeueReusableCell()
            return cell

        case Section.conversation.rawValue:
            let cell: ConversationCell = tableView.dequeueReusableCell()
            return cell
            
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        switch (indexPath as NSIndexPath).section {

        case Section.feedConversation.rawValue:

            guard let cell = cell as? FeedConversationDockCell else {
                break
            }

            cell.haveGroupUnreadMessages = countOfUnreadMessagesInRealm(realm, withConversationType: ConversationType.group) > 0

            // 先找最新且未读的消息
            let latestUnreadMessage = latestUnreadValidMessageInRealm(realm, withConversationType: .group)
            // 找不到就找最新的消息
            if let latestMessage = (latestUnreadMessage ?? latestValidMessageInRealm(realm, withConversationType: .group)) {

                if let mediaType = MessageMediaType(rawValue: latestMessage.mediaType), let placeholder = mediaType.placeholder {
                    cell.chatLabel.text = placeholder

                } else {
                    if mentionedMeInFeedConversationsInRealm(realm) {
                        let mentionedYouString = NSLocalizedString("[Mentioned you]", comment: "")
                        let string = mentionedYouString + " " + latestMessage.nicknameWithTextContent

                        let attributedString = NSMutableAttributedString(string: string)
                        let mentionedYouRange = NSMakeRange(0, (mentionedYouString as NSString).length)
                        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.red, range: mentionedYouRange)

                        cell.chatLabel.attributedText = attributedString

                    } else {
                        cell.chatLabel.text = latestMessage.nicknameWithTextContent
                    }
                }

            } else {
                cell.chatLabel.text = String.trans_promptNoMessages
            }

        case Section.conversation.rawValue:

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

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        switch (indexPath as NSIndexPath).section {

        case Section.feedConversation.rawValue:
            break

        case Section.conversation.rawValue:

            guard let cell = cell as? ConversationCell else {
                return
            }

            cell.avatarImageView.image = nil

        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        switch (indexPath as NSIndexPath).section {

        case Section.feedConversation.rawValue:
            performSegue(withIdentifier: "showFeedConversations", sender: nil)

        case Section.conversation.rawValue:
            if let cell = tableView.cellForRow(at: indexPath) as? ConversationCell {
                performSegue(withIdentifier: "showConversation", sender: cell.conversation)
            }

        default:
            break
        }
    }

    // Edit (for Delete)

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

        if (indexPath as NSIndexPath).section == Section.conversation.rawValue {
            return true
        }

        return false
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {

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

                    if let cell = tableView.cellForRow(at: indexPath) as? ConversationCell {
                        if let conversation = self?.conversations[safe: indexPath.row] {
                            let radius = min(cell.avatarImageView.bounds.width, cell.avatarImageView.bounds.height) * 0.5
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

                    tableView?.deleteRows(at: [indexPath], with: .automatic)
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

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        guard let indexPath = conversationsTableView.indexPathForRow(at: location), let cell = conversationsTableView.cellForRow(at: indexPath) else {
            return nil
        }

        previewingContext.sourceRect = cell.frame

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            return nil
        }

        switch section {

        case .feedConversation:
            return nil

        case .conversation:

            let vc = UIStoryboard.Scene.conversation
            let conversation = conversations[indexPath.row]
            prepareConversationViewController(vc, withConversation: conversation)

            recoverOriginalNavigationDelegate()

            vc.isPreviewed = true

            return vc
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {

        show(viewControllerToCommit, sender: self)
    }
}
