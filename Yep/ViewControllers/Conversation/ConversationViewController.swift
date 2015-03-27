//
//  ConversationViewController.swift
//  Yep
//
//  Created by NIX on 15/3/23.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Realm

class ConversationViewController: UIViewController {

    var conversation: Conversation!

    lazy var messages: RLMResults = {
        return messagesInConversation(self.conversation)
        }()

    // 上一次更新 UI 时的消息数
    var lastTimeMessagesCount: UInt = 0

    var conversationCollectionViewHasBeenMovedToBottomOnce = false

    // Keyboard 动画相关
    var conversationCollectionViewContentOffsetBeforeKeyboardWillShow = CGPointZero
    var conversationCollectionViewContentOffsetBeforeKeyboardWillHide = CGPointZero
    var isKeyboardVisible = false
    var keyboardHeight: CGFloat = 0

    var keyboardShowTimes = 0 {
        willSet {
            println("set keyboardShowTimes \(newValue)")

            if newValue == 0 {
                if !self.isKeyboardVisible {
                    var contentOffset = self.conversationCollectionViewContentOffsetBeforeKeyboardWillShow
                    contentOffset.y += keyboardHeight
                    self.conversationCollectionView.setContentOffset(contentOffset, animated: true)

                    println("fire setContentOffset")

                    self.isKeyboardVisible = true
                }
            }
        }
    }


    @IBOutlet weak var conversationCollectionView: UICollectionView!

    @IBOutlet weak var messageToolbar: MessageToolbar!
    @IBOutlet weak var messageToolbarBottomConstraint: NSLayoutConstraint!

    let messageTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(13)] // TODO: 用配置来决定
    let messageTextLabelMaxWidth: CGFloat = 320 - (15+40+20) - 20 // TODO: 根据 TextCell 的布局计算


    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.conversationCollectionView.bounds)
        }()

    let chatLeftTextCellIdentifier = "ChatLeftTextCell"
    let chatRightTextCellIdentifier = "ChatRightTextCell"


    // 使 messageToolbar 随着键盘出现或消失而移动
    var updateUIWithKeyboardChange = false {
        willSet {
            keyboardChangeObserver = newValue ? NSNotificationCenter.defaultCenter() : nil
        }
    }
    var keyboardChangeObserver: NSNotificationCenter? {
        didSet {
            oldValue?.removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
            oldValue?.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
            oldValue?.removeObserver(self, name: UIKeyboardDidHideNotification, object: nil)

            keyboardChangeObserver?.addObserver(self, selector: "handleKeyboardWillShowNotification:", name: UIKeyboardWillShowNotification, object: nil)
            keyboardChangeObserver?.addObserver(self, selector: "handleKeyboardWillHideNotification:", name: UIKeyboardWillHideNotification, object: nil)
            keyboardChangeObserver?.addObserver(self, selector: "handleKeyboardDidHideNotification:", name: UIKeyboardDidHideNotification, object: nil)
        }
    }


    deinit {
        updateUIWithKeyboardChange = false

        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateConversationCollectionView", name: YepNewMessagesReceivedNotification, object: nil)

        conversationCollectionView.registerNib(UINib(nibName: chatLeftTextCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatLeftTextCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatRightTextCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatRightTextCellIdentifier)

        setConversaitonCollectionViewOriginalContentInset()

        messageToolbarBottomConstraint.constant = 0

        updateUIWithKeyboardChange = true

        lastTimeMessagesCount = messages.count

        messageToolbar.textSendAction = { messageToolbar in
            let text = messageToolbar.messageTextField.text!

            self.cleanTextInput()

            if let withFriend = self.conversation.withFriend {
                sendText(text, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { message in
                    dispatch_async(dispatch_get_main_queue()) {
                        self.updateConversationCollectionView()
                    }

                }, failureHandler: { (reason, errorMessage) -> () in
                    defaultFailureHandler(reason, errorMessage)
                    // TODO: sendText 错误提醒

                }, completion: { success -> Void in
                    println("sendText to friend: \(success)")
                })

            } else if let withGroup = self.conversation.withGroup {
                sendText(text, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { message in
                    dispatch_async(dispatch_get_main_queue()) {
                        self.updateConversationCollectionView()
                    }

                }, failureHandler: { (reason, errorMessage) -> () in
                    defaultFailureHandler(reason, errorMessage)
                    // TODO: sendText 错误提醒

                }, completion: { success -> Void in
                    println("sendText to group: \(success)")
                })
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // 初始时移动一次到底部
        if !conversationCollectionViewHasBeenMovedToBottomOnce {
            conversationCollectionViewHasBeenMovedToBottomOnce = true
            if messages.count > 0 {
                conversationCollectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: Int(messages.count - 1), inSection: 0), atScrollPosition: UICollectionViewScrollPosition.Bottom, animated: false)
            }
        }
    }

    // MARK: Private

    private func setConversaitonCollectionViewOriginalContentInsetBottom(bottom: CGFloat) {
        var contentInset = conversationCollectionView.contentInset
        contentInset.bottom = bottom
        conversationCollectionView.contentInset = contentInset
    }

    private func setConversaitonCollectionViewOriginalContentInset() {
        setConversaitonCollectionViewOriginalContentInsetBottom(messageToolbar.intrinsicContentSize().height)
    }

    // MARK: Actions

    func updateConversationCollectionView() {
        let _lastTimeMessagesCount = lastTimeMessagesCount
        lastTimeMessagesCount = messages.count

        //let layout = conversationCollectionView.collectionViewLayout as! ConversationLayout
        //layout.needUpdate = true

        conversationCollectionView.reloadData()

        let newMessagesCount = messages.count - _lastTimeMessagesCount

        if newMessagesCount > 0 {

            var newMessagesTotalHeight: CGFloat = 0

            for i in _lastTimeMessagesCount..<messages.count {
                let message = messages.objectAtIndex(i) as! Message

                let rect = message.textContent.boundingRectWithSize(CGSize(width: messageTextLabelMaxWidth, height: CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: messageTextAttributes, context: nil)

                let height = max(ceil(rect.height) + 14 + 20, 40 + 20) + 10

                newMessagesTotalHeight += height
            }

            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.conversationCollectionView.contentOffset.y += newMessagesTotalHeight
                
            }, completion: { (finished) -> Void in
            })
        }
    }

    func cleanTextInput() {
        messageToolbar.messageTextField.text = ""
        messageToolbar.state = .Default
    }

    // MARK: Keyboard

    func handleKeyboardWillShowNotification(notification: NSNotification) {

        keyboardShowTimes += 1

        conversationCollectionViewContentOffsetBeforeKeyboardWillShow = conversationCollectionView.contentOffset

        if let userInfo = notification.userInfo {

            let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            let animationCurveValue = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedLongValue
            let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            let keyboardHeight = keyboardEndFrame.height

            self.keyboardHeight = keyboardHeight

            UIView.animateWithDuration(animationDuration, delay: 0, options: UIViewAnimationOptions(animationCurveValue << 16), animations: { () -> Void in
                self.messageToolbarBottomConstraint.constant = keyboardHeight
                self.view.layoutIfNeeded()

                self.conversationCollectionView.contentInset.bottom = self.messageToolbar.intrinsicContentSize().height + keyboardHeight

            }, completion: { (finished) -> Void in
                self.keyboardShowTimes -= 1
            })
        }
    }

    func handleKeyboardWillHideNotification(notification: NSNotification) {
        conversationCollectionViewContentOffsetBeforeKeyboardWillHide = conversationCollectionView.contentOffset

        if let userInfo = notification.userInfo {
            let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            let animationCurveValue = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedLongValue
            let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            let keyboardHeight = keyboardEndFrame.height

            UIView.animateWithDuration(animationDuration, delay: 0, options: UIViewAnimationOptions(animationCurveValue << 16), animations: { () -> Void in
                self.messageToolbarBottomConstraint.constant = 0
                self.view.layoutIfNeeded()

                self.conversationCollectionView.contentInset.bottom = self.messageToolbar.intrinsicContentSize().height

            }, completion: { (finished) -> Void in
                var contentOffset = self.conversationCollectionViewContentOffsetBeforeKeyboardWillHide
                contentOffset.y -= keyboardHeight
                self.conversationCollectionView.setContentOffset(contentOffset, animated: true)
            })
        }
    }

    func handleKeyboardDidHideNotification(notification: NSNotification) {
        isKeyboardVisible = false
    }

}

// MARK: UICollectionViewDataSource, UICollectionViewDelegate

extension ConversationViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int(messages.count)
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let message = messages.objectAtIndex(UInt(indexPath.row)) as! Message

        if let sender = message.fromFriend {
            if sender.friendState != UserFriendState.Me.rawValue {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftTextCellIdentifier, forIndexPath: indexPath) as! ChatLeftTextCell

                cell.textContentLabel.text = message.textContent

                AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: 40 * 0.5) { roundImage in
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.avatarImageView.image = roundImage
                    }
                }

                return cell

            } else {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightTextCellIdentifier, forIndexPath: indexPath) as! ChatRightTextCell

                cell.textContentLabel.text = message.textContent

                AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: 40 * 0.5) { roundImage in
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.avatarImageView.image = roundImage
                    }
                }

                return cell
            }

        } else {
            println("Conversation: Should not be there")

            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightTextCellIdentifier, forIndexPath: indexPath) as! ChatRightTextCell

            cell.textContentLabel.text = ""
            cell.avatarImageView.image = AvatarCache.sharedInstance.defaultRoundAvatarOfRadius(40 * 0.5)

            return cell
        }
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        // TODO: 缓存 Cell 高度才是正道
        // TODO: 不使用魔法数字
        let message = messages.objectAtIndex(UInt(indexPath.row)) as! Message

        let rect = message.textContent.boundingRectWithSize(CGSize(width: messageTextLabelMaxWidth, height: CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: messageTextAttributes, context: nil)

        let height = max(rect.height + 14 + 20, 40 + 20)
        return CGSizeMake(collectionViewWidth, height)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        view.endEditing(true)
    }
}


