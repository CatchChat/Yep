//
//  ConversationViewController.swift
//  Yep
//
//  Created by NIX on 15/3/23.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ConversationViewController: UIViewController {

    var conversation: Conversation!
    

    @IBOutlet weak var conversationCollectionView: UICollectionView!

    @IBOutlet weak var messageToolbar: MessageToolbar!
    @IBOutlet weak var messageToolbarBottomConstraint: NSLayoutConstraint!


    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.conversationCollectionView.bounds)
        }()

    let chatLeftTextCellIdentifier = "ChatLeftTextCell"
    let chatRightTextCellIdentifier = "ChatRightTextCell"


    lazy var messages = [
        (true, "What's up?"),
        (false, "Do not go gentle into that good night,"),
        (true, "Are you OK?"),
        (false, "Old age should burn and rage at close of day;"),
        (true, "Really?"),
        (false, "Rage, rage against the dying of the light."),
        (true, "Fuck you!"),
        (false, "Though wise men at their end know dark is right,"),
        (true, "You son of bitch!!!"),
        (true, "Go to hell!!!"),
        (true, "I will not talk to you again!!!!!!"),
        (false, "Because their words had forked no lightning they"),
        (false, "Do not go gentle into that good night."),
    ]


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

            keyboardChangeObserver?.addObserver(self, selector: "handleKeyboardWillShowNotification:", name: UIKeyboardWillShowNotification, object: nil)
            keyboardChangeObserver?.addObserver(self, selector: "handleKeyboardWillHideNotification:", name: UIKeyboardWillHideNotification, object: nil)
        }
    }


    deinit {
        updateUIWithKeyboardChange = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        conversationCollectionView.registerNib(UINib(nibName: chatLeftTextCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatLeftTextCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatRightTextCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatRightTextCellIdentifier)

        setConversaitonCollectionViewOriginalContentInset()

        messageToolbarBottomConstraint.constant = 0

        updateUIWithKeyboardChange = true

        messageToolbar.messageTextField.delegate = self
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

    // MARK: Keyboard

    func handleKeyboardWillShowNotification(notification: NSNotification) {
        println("showKeyboard") // 在 iOS 8.3 Beat 3 里，首次弹出键盘时，这个通知会发出三次，下面设置 contentOffset 因执行多次就会导致跳动。但第二次弹出键盘就不会了

        if let userInfo = notification.userInfo {

            let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            let animationCurveValue = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedLongValue
            let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            let keyboardHeight = keyboardEndFrame.height

            UIView.animateWithDuration(animationDuration, delay: 0, options: UIViewAnimationOptions(animationCurveValue << 16), animations: { () -> Void in
                self.messageToolbarBottomConstraint.constant = keyboardHeight
                self.view.layoutIfNeeded()

                self.conversationCollectionView.contentOffset.y += keyboardHeight
                self.conversationCollectionView.contentInset.bottom += keyboardHeight

            }, completion: { (finished) -> Void in
            })
        }
    }

    func handleKeyboardWillHideNotification(notification: NSNotification) {
        println("hideKeyboard")

        if let userInfo = notification.userInfo {
            let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            let animationCurveValue = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedLongValue
            let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            let keyboardHeight = keyboardEndFrame.height

            UIView.animateWithDuration(animationDuration, delay: 0, options: UIViewAnimationOptions(animationCurveValue << 16), animations: { () -> Void in
                self.messageToolbarBottomConstraint.constant = 0
                self.view.layoutIfNeeded()

                self.conversationCollectionView.contentOffset.y -= keyboardHeight
                self.conversationCollectionView.contentInset.bottom -= keyboardHeight

            }, completion: { (finished) -> Void in
            })
        }
    }
}

// MARK: UICollectionViewDataSource, UICollectionViewDelegate

extension ConversationViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let (isFromFriend, message) = messages[indexPath.row]

        if isFromFriend {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftTextCellIdentifier, forIndexPath: indexPath) as! ChatLeftTextCell

            cell.textContentLabel.text = message

            if let conversationWithFriend = conversation.withFriend {
                AvatarCache.sharedInstance.roundAvatarOfUser(conversationWithFriend, withRadius: 40 * 0.5) { roundImage in
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.avatarImageView.image = roundImage
                    }
                }

            } else {
                cell.avatarImageView.image = AvatarCache.sharedInstance.defaultRoundAvatarOfRadius(40 * 0.5)
            }

            return cell

        } else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightTextCellIdentifier, forIndexPath: indexPath) as! ChatRightTextCell

            if let avatarURLString = YepUserDefaults.avatarURLString() {
                AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(avatarURLString, withRadius: 40 * 0.5) { roundImage in
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.avatarImageView.image = roundImage
                    }
                }

            } else {
                cell.avatarImageView.image = AvatarCache.sharedInstance.defaultRoundAvatarOfRadius(40 * 0.5)
            }

            cell.textContentLabel.text = message

            return cell
        }
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        return CGSizeMake(collectionViewWidth, 60)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        view.endEditing(true)
    }
}

// MARK: UITextFieldDelegate

extension ConversationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {


        return true
    }
}


