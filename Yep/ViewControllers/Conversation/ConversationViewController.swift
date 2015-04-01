//
//  ConversationViewController.swift
//  Yep
//
//  Created by NIX on 15/3/23.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Realm
import AVFoundation

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
                    self.isKeyboardVisible = true
                }
            }
        }
    }

    @IBOutlet weak var conversationCollectionView: UICollectionView!

    @IBOutlet weak var messageToolbar: MessageToolbar!
    @IBOutlet weak var messageToolbarBottomConstraint: NSLayoutConstraint!

    let sectionInsetTop: CGFloat = 10
    let sectionInsetBottom: CGFloat = 10

    let messageTextAttributes = [NSFontAttributeName: UIFont.chatTextFont()]
    let messageTextLabelMaxWidth: CGFloat = 320 - (15+40+20) - 20 // TODO: 根据 TextCell 的布局计算


    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.conversationCollectionView.bounds)
        }()

    let chatLeftTextCellIdentifier = "ChatLeftTextCell"
    let chatRightTextCellIdentifier = "ChatRightTextCell"
    let chatLeftImageCellIdentifier = "ChatLeftImageCell"
    let chatRightImageCellIdentifier = "ChatRightImageCell"


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
        
        YepAudioService.sharedManager.audioRecorder.delegate = self
        
        let undoBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Undo, target: self, action: "undoMessageSend")
        navigationItem.rightBarButtonItem = undoBarButtonItem

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateConversationCollectionView", name: YepNewMessagesReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadConversationCollectionView", name: YepUpdatedProfileAvatarNotification, object: nil)

        conversationCollectionView.registerNib(UINib(nibName: chatLeftTextCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatLeftTextCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatRightTextCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatRightTextCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatLeftImageCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatLeftImageCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatRightImageCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatRightImageCellIdentifier)
        
        conversationCollectionView.bounces = true

        messageToolbarBottomConstraint.constant = 0

        updateUIWithKeyboardChange = true

        lastTimeMessagesCount = messages.count

        messageToolbar.textSendAction = { messageToolbar in
            let text = messageToolbar.messageTextView.text!

            self.cleanTextInput()

            if let withFriend = self.conversation.withFriend {
                sendText(text, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { (message, realm) in
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
                sendText(text, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { (message, realm) in
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

        messageToolbar.imageSendAction = { messageToolbar in
            
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
                imagePicker.allowsEditing = false

                self.presentViewController(imagePicker, animated: true, completion: nil)
            }
        }
        
        messageToolbar.voiceSendAction = { messageToolbar in

            YepAudioService.sharedManager.beginRecord()
        }
        
        messageToolbar.voiceSendCancelAction = { messageToolbar in
            
            YepAudioService.sharedManager.endRecord()
        }
        
        messageToolbar.voiceSendUpAction = { messageToolbar in
            
            YepAudioService.sharedManager.endRecord()
            
//            s3PrivateUploadParams(failureHandler: nil) { s3UploadParams in
//                
//                println("s3UploadParams: \(s3UploadParams)")
//                
//                let filePath = NSBundle.mainBundle().pathForResource("1", ofType: "png")!
//                uploadFileToS3(filePath: filePath, fileData: nil, mimetype: "image/png", s3UploadParams: s3UploadParams, completion: { (result, error) in
//                    if (result) {
//                        let newAvatarURLString = "\(s3UploadParams.url)\(s3UploadParams.key)"
//                        updateUserInfo(nickname: nil, avatar_url: newAvatarURLString, username: nil, latitude: nil, longitude: nil, completion: { result in
//                            YepUserDefaults.setAvatarURLString(newAvatarURLString)
//                            println("Update user info \(result)")
//                        })
//                        
//                    }
//                })
//            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // 初始时移动一次到底部
        if !conversationCollectionViewHasBeenMovedToBottomOnce {
            conversationCollectionViewHasBeenMovedToBottomOnce = true

            // 先调整一下初次的 contentInset
            setConversaitonCollectionViewOriginalContentInset()

            if messages.count > 0 {
                conversationCollectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: Int(messages.count - 1), inSection: 0), atScrollPosition: UICollectionViewScrollPosition.Bottom, animated: false)
            }
        }
    }

    // MARK: Private

    private func setConversaitonCollectionViewContentInsetBottom(bottom: CGFloat) {
        var contentInset = conversationCollectionView.contentInset
        contentInset.bottom = bottom
        conversationCollectionView.contentInset = contentInset
    }

    private func setConversaitonCollectionViewOriginalContentInset() {
        setConversaitonCollectionViewContentInsetBottom(CGRectGetHeight(messageToolbar.bounds))
    }

    // MARK: Actions

    func updateConversationCollectionView() {
        
        let _lastTimeMessagesCount = lastTimeMessagesCount
        lastTimeMessagesCount = messages.count
        
        // 保证是增加消息
        if messages.count <= _lastTimeMessagesCount {
            return
        }
        let newMessagesCount = messages.count - _lastTimeMessagesCount
        
        var indexPaths = [NSIndexPath]()
        for i in _lastTimeMessagesCount..<messages.count {
            let indexPath = NSIndexPath(forItem: Int(i), inSection: 0)
            indexPaths.append(indexPath)
        }

        self.conversationCollectionView.insertItemsAtIndexPaths(indexPaths)

        if newMessagesCount > 0 {

            var newMessagesTotalHeight: CGFloat = 0

            for i in _lastTimeMessagesCount..<messages.count {
                let message = messages.objectAtIndex(i) as! Message

                let rect = message.textContent.boundingRectWithSize(CGSize(width: messageTextLabelMaxWidth, height: CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: messageTextAttributes, context: nil)

                let height = max(ceil(rect.height) + 14 + 20, 40 + 20) + 10

                newMessagesTotalHeight += height
            }
            
            let keyboardAndToolBarHeight = self.messageToolbarBottomConstraint.constant + CGRectGetHeight(messageToolbar.bounds)
            
            let totleMessagesHeight = self.conversationCollectionView.contentSize.height + keyboardAndToolBarHeight + 64.0 + newMessagesTotalHeight
            
            let visableMessageFieldHeight = self.conversationCollectionView.frame.size.height - (keyboardAndToolBarHeight + 64.0)
            
            let totalMessagesContentHeight = self.conversationCollectionView.contentSize.height + keyboardAndToolBarHeight + newMessagesTotalHeight
            
            println("Size is \(self.conversationCollectionView.contentSize.height) \(newMessagesTotalHeight) visableMessageFieldHeight \(visableMessageFieldHeight)")
            
            //Calculate the space can be used
            let useableSpace = visableMessageFieldHeight - self.conversationCollectionView.contentSize.height
            
            self.conversationCollectionView.contentSize = CGSizeMake(self.conversationCollectionView.contentSize.width, self.conversationCollectionView.contentSize.height + newMessagesTotalHeight)
            
            println("Size is after \(self.conversationCollectionView.contentSize.height)")

            if (totleMessagesHeight > self.conversationCollectionView.frame.size.height) {
                println("New Message scroll")
                UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                    
                    if (useableSpace > 0) {
                        let contentToScroll = newMessagesTotalHeight - useableSpace
                        println("contentToScroll \(contentToScroll)")
                        self.conversationCollectionView.contentOffset.y += contentToScroll

                    } else {
                        self.conversationCollectionView.contentOffset.y += newMessagesTotalHeight
                    }
                    
                }, completion: { (finished) -> Void in
                })
            }
        }
    }

    func reloadConversationCollectionView() {
        conversationCollectionView.reloadData()
    }

    func cleanTextInput() {
        messageToolbar.messageTextView.text = ""
        messageToolbar.state = .Default
    }
    
    func undoMessageSend() {
        
        if let lastMessage = messages.lastObject() as? Message {

            let realm = RLMRealm.defaultRealm()
            realm.beginWriteTransaction()
            realm.deleteObject(lastMessage)
            realm.commitWriteTransaction()
            
            lastTimeMessagesCount = messages.count
            
            let lastMessageIndexPath = NSIndexPath(forItem: Int(messages.count), inSection: 0)
            conversationCollectionView.deleteItemsAtIndexPaths([lastMessageIndexPath])
            println("\(conversationCollectionView.contentSize) \(conversationCollectionView.contentOffset)")
//            messages = messagesInConversation(self.conversation)
            
//            println("Messages after refetch \(messages.count)")
        }
    }

    // MARK: Keyboard

    func handleKeyboardWillShowNotification(notification: NSNotification) {
        keyboardShowTimes += 1
        
        conversationCollectionViewContentOffsetBeforeKeyboardWillHide = CGPointZero
        if (conversationCollectionViewContentOffsetBeforeKeyboardWillShow == CGPointZero) {
            conversationCollectionViewContentOffsetBeforeKeyboardWillShow = conversationCollectionView.contentOffset
        }
//        println("Set offset before is \(conversationCollectionView.contentOffset)")

        if let userInfo = notification.userInfo {

            let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            let animationCurveValue = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedLongValue
            let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            let keyboardHeight = keyboardEndFrame.height

            self.keyboardHeight = keyboardHeight

            UIView.animateWithDuration(animationDuration, delay: 0, options: UIViewAnimationOptions(animationCurveValue << 16), animations: { () -> Void in
                
                self.messageToolbarBottomConstraint.constant = keyboardHeight
                
                let keyboardAndToolBarHeight = keyboardHeight + CGRectGetHeight(self.messageToolbar.bounds)
                
                let totleMessagesHeight = self.conversationCollectionView.contentSize.height + keyboardAndToolBarHeight + 64.0
                
                let visableMessageFieldHeight = self.conversationCollectionView.frame.size.height - (keyboardAndToolBarHeight + 64.0)
                
//                println("Content size is \(self.conversationCollectionView.contentSize.height) visableMessageFieldHeight \(visableMessageFieldHeight) totleMessagesHeight \(totleMessagesHeight) toolbar \(CGRectGetHeight(self.messageToolbar.bounds) ) keyboardHeight \(keyboardHeight) Navitation 64.0")
                
                let unvisibaleMessageHeight = self.conversationCollectionView.contentSize.height - visableMessageFieldHeight
                println("unvisibaleMessageHeight is \(unvisibaleMessageHeight)")
                
                //Only scroll the invisable field if invisable < keyboardAndToolBarHeight
                if (unvisibaleMessageHeight < (keyboardAndToolBarHeight)) {
                    
                    //Only scroll if need
                    if (unvisibaleMessageHeight > 0) {
                        var contentOffset = CGPointMake(self.conversationCollectionViewContentOffsetBeforeKeyboardWillShow.x, self.conversationCollectionViewContentOffsetBeforeKeyboardWillShow.y+unvisibaleMessageHeight)
                        println("Set offset is \(contentOffset)")
                        
                        self.conversationCollectionView.setContentOffset(contentOffset, animated: false)
                    }
                    
                }else{
                    
                    var contentOffset = self.conversationCollectionViewContentOffsetBeforeKeyboardWillShow
                    contentOffset.y += keyboardHeight
                    
                    println("Set offset is \(contentOffset)")
                    
                    self.conversationCollectionView.setContentOffset(contentOffset, animated: false)
                }
                
                self.conversationCollectionView.contentInset.bottom = CGRectGetHeight(self.messageToolbar.bounds)  + keyboardHeight
                
                self.view.layoutIfNeeded()
            
            }, completion: { (finished) -> Void in
                self.keyboardShowTimes -= 1
            })
        }
    }

    func handleKeyboardWillHideNotification(notification: NSNotification) {
        self.conversationCollectionViewContentOffsetBeforeKeyboardWillShow = CGPointZero
        if (conversationCollectionViewContentOffsetBeforeKeyboardWillHide == CGPointZero) {
            conversationCollectionViewContentOffsetBeforeKeyboardWillHide = conversationCollectionView.contentOffset
        }

        if let userInfo = notification.userInfo {
            let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            let animationCurveValue = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedLongValue
            let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            let keyboardHeight = keyboardEndFrame.height

            UIView.animateWithDuration(animationDuration, delay: 0, options: UIViewAnimationOptions(animationCurveValue << 16), animations: { () -> Void in
                self.messageToolbarBottomConstraint.constant = 0
                self.view.layoutIfNeeded()

                var contentOffset = self.conversationCollectionViewContentOffsetBeforeKeyboardWillHide
                contentOffset.y -= keyboardHeight
                //println("\(self.conversationCollectionViewContentOffsetBeforeKeyboardWillHide.y) \(contentOffset.y) \(self.conversationCollectionViewContentOffsetBeforeKeyboardWillHide.y-contentOffset.y)")
                self.conversationCollectionView.setContentOffset(contentOffset, animated: false)
                self.conversationCollectionView.contentInset.bottom = CGRectGetHeight(self.messageToolbar.bounds)

            }, completion: { (finished) -> Void in

            })
        }
    }

    func handleKeyboardDidHideNotification(notification: NSNotification) {
        isKeyboardVisible = false
    }

}

// MARK: UICollectionViewDataSource, UICollectionViewDelegate

extension ConversationViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
//        println("\(scrollView.contentSize) \(scrollView.contentOffset)")
    }

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
                switch message.mediaType {
                case MessageMediaType.Image.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftImageCellIdentifier, forIndexPath: indexPath) as! ChatLeftImageCell

                    AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: 40 * 0.5) { roundImage in
                        dispatch_async(dispatch_get_main_queue()) {
                            cell.avatarImageView.image = roundImage
                        }
                    }

                    ImageCache.sharedInstance.rightMessageImageOfMessage(message) { image in
                        dispatch_async(dispatch_get_main_queue()) {
                            cell.messageImageView.image = image
                        }
                    }

                    return cell

                default:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftTextCellIdentifier, forIndexPath: indexPath) as! ChatLeftTextCell

                    cell.textContentLabel.text = message.textContent

                    AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: 40 * 0.5) { roundImage in
                        dispatch_async(dispatch_get_main_queue()) {
                            cell.avatarImageView.image = roundImage
                        }
                    }
                    
                    return cell
                }

            } else {

                switch message.mediaType {
                case MessageMediaType.Image.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightImageCellIdentifier, forIndexPath: indexPath) as! ChatRightImageCell

                    if
                        let myUserID = YepUserDefaults.userID(),
                        let me = userWithUserID(myUserID) {
                            AvatarCache.sharedInstance.roundAvatarOfUser(me, withRadius: 40 * 0.5) { roundImage in
                                dispatch_async(dispatch_get_main_queue()) {
                                    cell.avatarImageView.image = roundImage
                                }
                            }

                            ImageCache.sharedInstance.rightMessageImageOfMessage(message) { image in
                                dispatch_async(dispatch_get_main_queue()) {
                                    cell.messageImageView.image = image
                                }
                            }
                    }
                    
                    return cell


                default:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightTextCellIdentifier, forIndexPath: indexPath) as! ChatRightTextCell

                    cell.textContentLabel.text = message.textContent

                    AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: 40 * 0.5) { roundImage in
                        dispatch_async(dispatch_get_main_queue()) {
                            cell.avatarImageView.image = roundImage
                        }
                    }
                    
                    return cell
                }
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

        let message = messages.objectAtIndex(UInt(indexPath.row)) as! Message

        switch message.mediaType {
        case MessageMediaType.Image.rawValue:
            return CGSizeMake(collectionViewWidth, 150)

        default:
            // TODO: 缓存 Cell 高度才是正道
            // TODO: 不使用魔法数字

            let rect = message.textContent.boundingRectWithSize(CGSize(width: messageTextLabelMaxWidth, height: CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: messageTextAttributes, context: nil)

            let height = max(ceil(rect.height) + 14 + 20, 40 + 20)
            return CGSizeMake(collectionViewWidth, height)
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: sectionInsetTop, left: 0, bottom: sectionInsetBottom, right: 0)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        view.endEditing(true)
    }
}

// MARK: AVAudioRecorderDelegate

extension ConversationViewController : AVAudioRecorderDelegate {

    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!,
        successfully flag: Bool) {
            println("finished recording \(flag)")
            
            // ios8 and later
    }
    
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder!,
        error: NSError!) {
            println("\(error.localizedDescription)")
    }
}

// MARK: UIImagePicker

extension ConversationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {

        var imageData = UIImageJPEGRepresentation(image, YepConfig.messageImageCompressionQuality())

        s3PrivateUploadParams(failureHandler: nil) { s3UploadParams in
            uploadFileToS3(inFilePath: nil, orFileData: imageData, mimetype: "image/jpeg", s3UploadParams: s3UploadParams) { (result, error) in
                println("upload Image: \(result), \(error)")

                let messageImageName = NSUUID().UUIDString

                if let withFriend = self.conversation.withFriend {
                    sendImageWithKey(s3UploadParams.key, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { (message, realm) -> Void in

                        dispatch_async(dispatch_get_main_queue()) {

                            if let messageImageURL = NSFileManager.saveMessageImageData(imageData, withName: messageImageName) {
                                realm.beginWriteTransaction()
                                message.localAttachmentName = messageImageName
                                realm.commitWriteTransaction()
                            }

                            self.updateConversationCollectionView()
                        }

                    }, failureHandler: {(reason, errorMessage) -> () in
                        defaultFailureHandler(reason, errorMessage)
                        // TODO: sendImage 错误提醒

                    }, completion: { success -> Void in
                        println("sendImage to friend: \(success)")
                    })

                } else if let withGroup = self.conversation.withGroup {
                    sendImageWithKey(s3UploadParams.key, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { (message, realm) -> Void in
                        dispatch_async(dispatch_get_main_queue()) {
                            if let messageImageURL = NSFileManager.saveMessageImageData(imageData, withName: messageImageName) {
                                realm.beginWriteTransaction()
                                message.localAttachmentName = messageImageName
                                realm.commitWriteTransaction()
                            }

                            self.updateConversationCollectionView()
                        }

                    }, failureHandler: {(reason, errorMessage) -> () in
                        defaultFailureHandler(reason, errorMessage)
                        // TODO: sendImage 错误提醒

                    }, completion: { success -> Void in
                        println("sendImage to friend: \(success)")
                    })
                }
            }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}
