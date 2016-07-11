//
//  ChatViewController.swift
//  Yep
//
//  Created by NIX on 16/6/16.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
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

    let messagesBunchCount = 30
    var displayedMessagesRange = NSRange()

    lazy var tableNode: ASTableNode = {
        let node = ASTableNode()
        node.dataSource = self
        node.delegate = self
        node.view?.keyboardDismissMode = .OnDrag
        node.view?.separatorStyle = .None
        return node
    }()

    lazy var chatToolbar: ChatToolbar = {
        let toolbar = ChatToolbar()
        toolbar.sizeToFit()
        toolbar.layoutIfNeeded()

        toolbar.sendTextAction = { [weak self] text in
            self?.send(text: text)
        }

        toolbar.stateTransitionAction = { [weak self] (toolbar, previousState, currentState) in

            switch (previousState, currentState) {

            case (.TextInputing, .BeginTextInput):

                let deltaHeight = toolbar.height - toolbar.previousHeight

                UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
                    self?.tableNode.view?.contentInset.bottom += deltaHeight
                    self?.tableNode.view?.scrollIndicatorInsets.bottom += deltaHeight
                }, completion: { _ in })

            default:
                break
            }
        }

        return toolbar
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

    override func canBecomeFirstResponder() -> Bool {
        return true
    }

    override var inputAccessoryView: UIView? {
        return chatToolbar
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

            let bottom = keyboardHeight // + subscribeViewHeight
            strongSelf.tableNode.view?.contentInset.bottom = bottom
            strongSelf.tableNode.view?.scrollIndicatorInsets.bottom = bottom
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

            if sender.friendState != UserFriendState.Me.rawValue { // from Friend

                if message.deletedByCreator {
                    let node = ChatPromptCellNode()
                    node.configure(withMessage: message, promptType: .RecalledMessage)
                    return node
                }

                switch mediaType {

                case .Text:

                    let node = ChatLeftTextCellNode()
                    node.configure(withMessage: message)
                    return node

                case .Image:

                    let node = ChatLeftImageCellNode()
                    node.configure(withMessage: message)
                    node.tapImageAction = { [weak self] node in
                        self?.tryPreviewMediaOfMessage(message, fromNode: node)
                    }
                    return node

                case .Audio:

                    let node = ChatLeftTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious Audio")
                    return node

                case .Video:

                    let node = ChatLeftTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious Video")
                    return node

                case .Location:

                    let node = ChatLeftTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious Location")
                    return node

                case .SocialWork:

                    let node = ChatLeftTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious SocialWork")
                    return node
                    
                default:
                    let node = ChatLeftTextCellNode()
                    node.configure(withMessage: message)
                    return node
                }

            } else { // from Me

                switch mediaType {

                case .Text:

                    let node = ChatRightTextCellNode()
                    node.configure(withMessage: message)
                    return node

                case .Image:

                    let node = ChatRightImageCellNode()
                    node.configure(withMessage: message)
                    node.tapImageAction = { [weak self] node in
                        self?.tryPreviewMediaOfMessage(message, fromNode: node)
                    }
                    return node

                case .Audio:

                    let node = ChatRightTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious Audio")
                    return node

                case .Video:

                    let node = ChatRightTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious Video")
                    return node

                case .Location:

                    let node = ChatRightTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious Location")
                    return node

                default:
                    let node = ChatRightTextCellNode()
                    node.configure(withMessage: message)
                    return node
                }
            }
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

                tableNode.view?.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .None)
            }

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

