//
//  ChatViewController.swift
//  Yep
//
//  Created by NIX on 16/6/16.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import MobileCoreServices.UTType
import YepKit
import YepNetworking
import KeyboardMan
import RealmSwift
import AsyncDisplayKit
import DeviceGuru

class ChatViewController: BaseViewController {

    var conversation: Conversation!
    var realm: Realm!

    lazy var messages: Results<Message> = {
        return messagesOfConversation(self.conversation, inRealm: self.realm)
    }()

    let messagesBunchCount = 20
    var displayedMessagesRange = NSRange()

    lazy var tableNode: ASTableNode = {
        let node = ASTableNode()
        node.dataSource = self
        node.delegate = self
        node.view?.contentInset.bottom = 49
        node.view?.keyboardDismissMode = .OnDrag
        node.view?.separatorStyle = .None
        return node
    }()

    private var chatToolbarBottomConstraint: NSLayoutConstraint!
    lazy var chatToolbar: ChatToolbar = {
        let toolbar = ChatToolbar()

        toolbar.sendTextAction = { [weak self] text in

            self?.send(text: text)
        }

        toolbar.moreMessageTypesAction = { [weak self] in

            if let window = self?.view.window {
                self?.moreMessageTypesView.showInView(window)

                if let state = self?.chatToolbar.state where !state.isAtBottom {
                    self?.chatToolbar.state = .Default
                }

                delay(0.2) {
                    self?.imagePicker.hidesBarsOnTap = false
                }
            }
        }

        toolbar.stateTransitionAction = { [weak self] (toolbar, previousState, currentState) in

            switch currentState {

            case .BeginTextInput:
                self?.trySnapContentOfTableToBottom(forceAnimation: true)
                break

            case .TextInputing:
                self?.trySnapContentOfTableToBottom()
                break
                
            default:
                break
            }
        }

        return toolbar
    }()

    lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        imagePicker.videoQuality = .TypeMedium
        imagePicker.allowsEditing = false
        return imagePicker
    }()

    private lazy var moreMessageTypesView: MoreMessageTypesView = {
        let view = self.makeMoreMessageTypesView()
        return view
    }()

    private let keyboardMan = KeyboardMan()

    // 上一次更新 UI 时的消息数
    var lastTimeMessagesCount: Int = 0

    var indexPathForMenu: NSIndexPath?

    var isLoadingPreviousMessages = false

    var previewTransitionViews: [UIView?]?
    var previewAttachmentPhotos: [PreviewAttachmentPhoto] = []
    var previewMessagePhotos: [PreviewMessagePhoto] = []

    deinit {
        tableNode.dataSource = nil
        tableNode.delegate = nil

        NSNotificationCenter.defaultCenter().removeObserver(self)

        println("deinit ChatViewController")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableNode.frame = view.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            view.addSubview(tableNode.view)

            if DeviceGuru.yep_isLowEndDevice {
                tableNode.view?.alpha = 0
            }

            view.addSubview(chatToolbar)
            chatToolbar.translatesAutoresizingMaskIntoConstraints = false
            chatToolbar.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
            chatToolbar.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
            let bottom = chatToolbar.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)
            chatToolbarBottomConstraint = bottom
            bottom.active = true
        }

        realm = conversation.realm!

        do {
            if messages.count >= messagesBunchCount {
                displayedMessagesRange = NSRange(location: messages.count - messagesBunchCount, length: messagesBunchCount)
            } else {
                displayedMessagesRange = NSRange(location: 0, length: messages.count)
            }
        }

        lastTimeMessagesCount = messages.count

        do {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.menuWillShow(_:)), name: UIMenuControllerWillShowMenuNotification, object: nil)

            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.menuWillHide(_:)), name: UIMenuControllerWillHideMenuNotification, object: nil)
        }

        let scrollToBottom: dispatch_block_t = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            guard strongSelf.displayedMessagesRange.length > 0 else {
                return
            }
            strongSelf.tableNode.view?.beginUpdates()
            strongSelf.tableNode.view?.reloadData()
            strongSelf.tableNode.view?.endUpdatesAnimated(false) { [weak self] success in
                guard success, let strongSelf = self else {
                    return
                }
                let bottomIndexPath = NSIndexPath(
                    forRow: strongSelf.displayedMessagesRange.length - 1,
                    inSection: Section.Messages.rawValue
                )
                strongSelf.tableNode.view?.scrollToRowAtIndexPath(bottomIndexPath, atScrollPosition: .Bottom, animated: false)
            }
        }
        delay(0, work: scrollToBottom)

        keyboardMan.animateWhenKeyboardAppear = { [weak self] appearPostIndex, keyboardHeight, keyboardHeightIncrement in

            guard let strongSelf = self where strongSelf.navigationController?.topViewController == strongSelf else {
                return
            }

            guard keyboardHeightIncrement > 0 else {
                return
            }

            print("KeyboardAppear: \(appearPostIndex, keyboardHeight, keyboardHeightIncrement)")

            strongSelf.tableNode.view?.contentOffset.y += keyboardHeightIncrement

            let bottom = keyboardHeight + strongSelf.chatToolbar.frame.height // + subscribeViewHeight
            strongSelf.tableNode.view?.contentInset.bottom = bottom
            strongSelf.tableNode.view?.scrollIndicatorInsets.bottom = bottom

            strongSelf.chatToolbarBottomConstraint.constant = -keyboardHeight
            strongSelf.view.layoutIfNeeded()
        }

        keyboardMan.animateWhenKeyboardDisappear = { [weak self] keyboardHeight in

            guard let strongSelf = self where strongSelf.navigationController?.topViewController == strongSelf else {
                return
            }

            print("KeyboardDisappear: \(keyboardHeight)")

            //let subscribeViewHeight = strongSelf.isSubscribeViewShowing ? SubscribeView.height : 0
            let bottom = strongSelf.chatToolbar.frame.height // + subscribeViewHeight

            strongSelf.tableNode.view?.contentOffset.y -= (keyboardHeight - bottom)

            strongSelf.tableNode.view?.contentInset.bottom = bottom
            strongSelf.tableNode.view?.scrollIndicatorInsets.bottom = bottom

            strongSelf.chatToolbarBottomConstraint.constant = 0
            strongSelf.view.layoutIfNeeded()
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if DeviceGuru.yep_isLowEndDevice {
            UIView.animateWithDuration(0.25, delay: 0, options: [.CurveEaseInOut], animations: { [weak self] in
                self?.tableNode.view?.alpha = 1
            }, completion: nil)
        }
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        chatToolbar.state = .Default

        switch identifier {

        case "showProfile":

            let vc = segue.destinationViewController as! ProfileViewController

            if let user = sender as? User {
                vc.prepare(withUser: user)

            } else {
                if let withFriend = conversation?.withFriend {
                    vc.prepare(withUser: withFriend)
                }
            }

            switch conversation.type {
            case ConversationType.OneToOne.rawValue:
                vc.fromType = .OneToOneConversation
            case ConversationType.Group.rawValue:
                vc.fromType = .GroupConversation
            default:
                break
            }

        case "showProfileWithUsername":

            let vc = segue.destinationViewController as! ProfileViewController

            let profileUser = (sender as! Box<ProfileUser>).value
            vc.prepare(withProfileUser: profileUser)
            
            vc.fromType = .GroupConversation

        case "presentPickLocation":

            let nvc = segue.destinationViewController as! UINavigationController
            let vc = nvc.topViewController as! PickLocationViewController

            vc.sendLocationAction = { [weak self] locationInfo in

                if let user = self?.conversation.withFriend {
                    self?.send(locationInfo: locationInfo, toUser: user)

                } else if let group = self?.conversation.withGroup {
                    self?.send(locationInfo: locationInfo, toGroup: group)
                }
            }

        default:
            break
        }
    }
}

// MARK: - Segue Show

extension ChatViewController {

    private func tryShowProfile(withUsername username: String) {

        if let realm = try? Realm(), user = userWithUsername(username, inRealm: realm) {
            let profileUser = ProfileUser.UserType(user)

            delay(0.1) { [weak self] in
                self?.performSegueWithIdentifier("showProfileWithUsername", sender: Box<ProfileUser>(profileUser))
            }

        } else {
            discoverUserByUsername(username, failureHandler: { [weak self] reason, errorMessage in
                YepAlert.alertSorry(message: errorMessage ?? NSLocalizedString("User not found!", comment: ""), inViewController: self)

            }, completion: { discoveredUser in
                SafeDispatch.async { [weak self] in
                    let profileUser = ProfileUser.DiscoveredUserType(discoveredUser)
                    self?.performSegueWithIdentifier("showProfileWithUsername", sender: Box<ProfileUser>(profileUser))
                }
            })
        }
    }
}

// MARK: - Open Map

extension ChatViewController {

    func tryOpenMap(forMessage message: Message) {

        guard let coordinate = message.coordinate else {
            return
        }

        let locationCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
        mapItem.name = message.textContent

        mapItem.openInMapsWithLaunchOptions(nil)
    }
}

// MARK: - ASTableDataSource, ASTableDelegate

extension ChatViewController: ASTableDataSource, ASTableDelegate {

    enum Section: Int {
        case LoadPrevious
        case Messages
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            return 0
        }

        switch section {

        case .LoadPrevious:
            return 1

        case .Messages:
            return displayedMessagesRange.length
        }
    }

    func tableView(tableView: ASTableView, nodeForRowAtIndexPath indexPath: NSIndexPath) -> ASCellNode {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:

            let node = ChatLoadingCellNode()
            return node

        case .Messages:

            guard let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] else {
                let node = ChatSectionDateCellNode()
                node.configure(withText: "🐌🐌🐌")
                return node
            }

            guard let mediaType = MessageMediaType(rawValue: message.mediaType) else {
                let node = ChatSectionDateCellNode()
                node.configure(withText: "🐌🐌")
                return node
            }

            if case .SectionDate = mediaType {
                let node = ChatSectionDateCellNode()
                node.configure(withMessage: message)
                return node
            }

            guard let sender = message.fromFriend else {

                if message.blockedByRecipient {
                    let node = ChatPromptCellNode()
                    node.configure(withMessage: message, promptType: .BlockedByRecipient)
                    return node
                }

                let node = ChatSectionDateCellNode()
                node.configure(withText: "🐌")
                return node
            }

            if message.deletedByCreator {
                let node = ChatPromptCellNode()
                node.configure(withMessage: message, promptType: .RecalledMessage)
                return node
            }

            let cellNode: ASCellNode

            if sender.friendState != UserFriendState.Me.rawValue { // from Friend

                switch mediaType {

                case .Text:

                    let node = ChatLeftTextCellNode()
                    node.configure(withMessage: message)
                    node.tapURLAction = { [weak self] url in
                        self?.yep_openURL(url)
                    }
                    node.tapMentionAction = { [weak self] username in
                        self?.tryShowProfile(withUsername: username)
                    }
                    cellNode = node

                case .Image:

                    let node = ChatLeftImageCellNode()
                    node.configure(withMessage: message)
                    node.tapImageAction = { [weak self] node in
                        self?.tryPreviewMediaOfMessage(message, fromNode: node)
                    }
                    cellNode = node

                case .Audio:

                    let node = ChatLeftTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious Audio")
                    cellNode = node

                case .Video:

                    let node = ChatLeftTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious Video")
                    cellNode = node

                case .Location:

                    let node = ChatLeftLocationCellNode()
                    node.configure(withMessage: message)
                    node.tapMapAction = { [weak self] message in
                        self?.tryOpenMap(forMessage: message)
                    }
                    cellNode = node

                case .SocialWork:

                    let node = ChatLeftTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious SocialWork")
                    cellNode = node
                    
                default:

                    let node = ChatLeftTextCellNode()
                    node.configure(withMessage: message, text: "<🐌>")
                    cellNode = node
                }

            } else { // from Me

                switch mediaType {

                case .Text:

                    let node = ChatRightTextCellNode()
                    node.configure(withMessage: message)
                    node.tapURLAction = { [weak self] url in
                        self?.yep_openURL(url)
                    }
                    node.tapMentionAction = { [weak self] username in
                        self?.tryShowProfile(withUsername: username)
                    }
                    cellNode = node

                case .Image:

                    let node = ChatRightImageCellNode()
                    node.configure(withMessage: message)
                    node.tapImageAction = { [weak self] node in
                        self?.tryPreviewMediaOfMessage(message, fromNode: node)
                    }
                    cellNode = node

                case .Audio:

                    let node = ChatRightTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious Audio")
                    cellNode = node

                case .Video:

                    let node = ChatRightTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious Video")
                    cellNode = node

                case .Location:

                    let node = ChatRightLocationCellNode()
                    node.configure(withMessage: message)
                    node.tapMapAction = { [weak self] message in
                        self?.tryOpenMap(forMessage: message)
                    }
                    cellNode = node

                default:

                    let node = ChatRightTextCellNode()
                    node.configure(withMessage: message, text: "<🐌>")
                    cellNode = node
                }
            }

            if let baseCellNode = cellNode as? ChatBaseCellNode {
                baseCellNode.tapAvatarAction = { [weak self] user in
                    self?.performSegueWithIdentifier("showProfile", sender: user)
                }
            }

            return cellNode
        }
    }

    func tableView(tableView: ASTableView, willDisplayNodeForRowAtIndexPath indexPath: NSIndexPath) {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:
            let node = tableView.nodeForRowAtIndexPath(indexPath) as? ChatLoadingCellNode
            node?.isLoading = isLoadingPreviousMessages

        case .Messages:
            break
        }
    }

    // MARK: Menu

    func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {

        guard let message = messages[safe: (displayedMessagesRange.location + indexPath.row)] where message.isReal else {
            return false
        }

        indexPathForMenu = indexPath

        var canReport = false

        let title: String
        let isMyMessage = message.fromFriend?.isMe ?? false
        if isMyMessage {
            title = NSLocalizedString("Recall", comment: "")
        } else {
            title = NSLocalizedString("Hide", comment: "")
            canReport = true
        }

        var menuItems = [
            UIMenuItem(title: title, action: #selector(ChatBaseCellNode.deleteMessage(_:))),
        ]

        if canReport {
            let reportItem = UIMenuItem(title: NSLocalizedString("Report", comment: ""), action: #selector(ChatBaseCellNode.reportMessage(_:)))
            menuItems.append(reportItem)
        }

        UIMenuController.sharedMenuController().menuItems = menuItems
        UIMenuController.sharedMenuController().update()
        
        return true
    }

    func tableView(tableView: UITableView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {

        println("action: \(action)")

        if action == #selector(NSObject.copy(_:)) {
            if tableNode.view?.nodeForRowAtIndexPath(indexPath) is Copyable {
                return true
            } else {
                return false
            }
        }

        if action == #selector(ChatBaseCellNode.deleteMessage(_:)) {
            return true
        }

        if action == #selector(ChatBaseCellNode.reportMessage(_:)) {
            return true
        }

        return false
    }

    func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {

        if action == #selector(NSObject.copy(_:)) {
            if let copyableNode = tableNode.view?.nodeForRowAtIndexPath(indexPath) as? Copyable {
                UIPasteboard.generalPasteboard().string = copyableNode.text
            }
        }
    }

    // MARK: UIScrollViewDelegate

    func scrollViewDidScroll(scrollView: UIScrollView) {

        func tryTriggerLoadPreviousMessages() {

            guard scrollView.yep_isAtTop && (scrollView.dragging || scrollView.decelerating) else {
                return
            }

            let indexPath = NSIndexPath(forRow: 0, inSection: Section.LoadPrevious.rawValue)
            let node = tableNode.view?.nodeForRowAtIndexPath(indexPath) as? ChatLoadingCellNode

            guard !isLoadingPreviousMessages else {
                node?.isLoading = false
                return
            }

            node?.isLoading = true

            delay(0.5) { [weak self] in
                self?.tryLoadPreviousMessages { [weak node] in
                    node?.isLoading = false
                }
            }
        }
        
        tryTriggerLoadPreviousMessages()
    }

    func tryLoadPreviousMessages(completion: () -> Void) {

        if isLoadingPreviousMessages {
            completion()
            return
        }

        isLoadingPreviousMessages = true

        println("tryLoadPreviousMessages")

        if displayedMessagesRange.location == 0 {
            completion()

        } else {
            var newMessagesCount = self.messagesBunchCount

            if (self.displayedMessagesRange.location - newMessagesCount) < 0 {
                newMessagesCount = self.displayedMessagesRange.location
            }

            if newMessagesCount > 0 {
                self.displayedMessagesRange.location -= newMessagesCount
                self.displayedMessagesRange.length += newMessagesCount

                let indexPaths = (0..<newMessagesCount).map({
                    NSIndexPath(forRow: $0, inSection: Section.Messages.rawValue)
                })

                if let tableView = tableNode.view {
                    let bottomOffset = tableView.contentSize.height - tableView.contentOffset.y
                    tableView.beginUpdates()
                    tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .None)
                    tableView.endUpdatesAnimated(false, completion: { _ in
                        var contentOffset = tableView.contentOffset
                        contentOffset.y = tableView.contentSize.height - bottomOffset
                        print("bottomOffset: \(bottomOffset)")
                        print("tableView.contentOffset: \(tableView.contentOffset)")
                        print("tableView.contentSize: \(tableView.contentSize)")
                        print("contentOffset: \(contentOffset)")
                        tableView.setContentOffset(contentOffset, animated: false)
                    })
                }
            }

            isLoadingPreviousMessages = false

            completion()
        }
    }
}

// MARK: - Menu Notifcations

extension ChatViewController {

    @objc func menuWillShow(notification: NSNotification) {

        println("menu will show")

        guard let menu = notification.object as? UIMenuController, indexPathForMenu = indexPathForMenu, cellNode = tableNode.view?.nodeForRowAtIndexPath(indexPathForMenu) as? ChatBaseCellNode else {
            return
        }

        var targetRect = CGRectZero

        if let cell = cellNode as? ChatLeftTextCellNode {
            targetRect = cell.view.convertRect(cell.bubbleNode.frame, toView: view)

        } else if let cell = cellNode as? ChatRightTextCellNode {
            targetRect = cell.view.convertRect(cell.bubbleNode.frame, toView: view)
        }

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIMenuControllerWillShowMenuNotification, object: nil)

        menu.setTargetRect(targetRect, inView: view)
        menu.setMenuVisible(true, animated: true)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.menuWillShow(_:)), name: UIMenuControllerWillShowMenuNotification, object: nil)
    }

    @objc func menuWillHide(notification: NSNotification) {

        println("menu will hide")

        indexPathForMenu = nil
    }
}

