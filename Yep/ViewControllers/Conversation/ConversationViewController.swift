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
    
    var waverView: YepWaverView!
    var audioSamples = [Float]()
    var samplesCount = 0
    let samplingInterval = 6

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
    let messageTextLabelMaxWidth: CGFloat = 320 - (15 + YepConfig.chatCellAvatarSize() + 20) - 20 // TODO: 根据 TextCell 的布局计算


    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.conversationCollectionView.bounds)
        }()

    lazy var messageImageWidth: CGFloat = {
        return self.collectionViewWidth * 0.6
        }()
    lazy var messageImageHeight: CGFloat = {
        return self.messageImageWidth / YepConfig.messageImageViewDefaultAspectRatio()
        }()

    let chatLeftTextCellIdentifier = "ChatLeftTextCell"
    let chatRightTextCellIdentifier = "ChatRightTextCell"
    let chatLeftImageCellIdentifier = "ChatLeftImageCell"
    let chatRightImageCellIdentifier = "ChatRightImageCell"
    let chatLeftAudioCellIdentifier = "ChatLeftAudioCell"
    let chatRightAudioCellIdentifier = "ChatRightAudioCell"


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

        self.navigationController?.interactivePopGestureRecognizer.delaysTouchesBegan = false

        //YepAudioService.sharedManager.audioRecorder.delegate = self
        
        let undoBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Undo, target: self, action: "undoMessageSend")
        navigationItem.rightBarButtonItem = undoBarButtonItem

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateConversationCollectionView", name: YepNewMessagesReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadConversationCollectionView", name: YepUpdatedProfileAvatarNotification, object: nil)

        conversationCollectionView.registerNib(UINib(nibName: chatLeftTextCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatLeftTextCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatRightTextCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatRightTextCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatLeftImageCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatLeftImageCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatRightImageCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatRightImageCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatLeftAudioCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatLeftAudioCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatRightAudioCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatRightAudioCellIdentifier)
        
        conversationCollectionView.bounces = true

        messageToolbarBottomConstraint.constant = 0

        updateUIWithKeyboardChange = true

        lastTimeMessagesCount = messages.count

        messageToolbar.textSendAction = { messageToolbar in
            let text = messageToolbar.messageTextView.text!

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
        
        self.waverView = YepWaverView(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - self.messageToolbar.frame.size.height))

        self.waverView.waver.waverCallback = {
            
            if let audioRecorder = YepAudioService.sharedManager.audioRecorder {
                if (audioRecorder.recording) {
                    //println("Update waver")
                    audioRecorder.updateMeters()

                    var normalizedValue = pow(10, audioRecorder.averagePowerForChannel(0)/40)

                    if (++self.samplesCount % self.samplingInterval) == 0 {
                        self.audioSamples.append(normalizedValue)
                    }

                    self.waverView.waver.level = CGFloat(normalizedValue)
                }
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

        // MARK: Audio Send

        messageToolbar.voiceSendBeginAction = { messageToolbar in
            self.view.window?.addSubview(self.waverView)

            let audioFileName = NSUUID().UUIDString

            self.audioSamples.removeAll(keepCapacity: true)
            self.samplesCount = 0

            if let fileURL = NSFileManager.yepMessageAudioURLWithName(audioFileName) {
                YepAudioService.sharedManager.beginRecordWithFileURL(fileURL, audioRecorderDelegate: self)
            }
        }
        
        messageToolbar.voiceSendCancelAction = { messageToolbar in
            self.waverView.removeFromSuperview()
            YepAudioService.sharedManager.endRecord()
        }
        
        messageToolbar.voiceSendEndAction = { messageToolbar in
            self.waverView.removeFromSuperview()
            YepAudioService.sharedManager.endRecord()


            // Prepare meta data

            var metaData: String? = nil

            let audioSamples = self.audioSamples

            if let fileURL = YepAudioService.sharedManager.audioFileURL {
                let audioAsset = AVURLAsset(URL: fileURL, options: nil)
                let audioDuration = CMTimeGetSeconds(audioAsset.duration) as Double

                let audioMetaDataInfo = ["audio_samples": audioSamples, "audio_duration": audioDuration]

                if let audioMetaData = NSJSONSerialization.dataWithJSONObject(audioMetaDataInfo, options: nil, error: nil) {
                    let audioMetaDataString = NSString(data: audioMetaData, encoding: NSUTF8StringEncoding) as? String
                    metaData = audioMetaDataString
                }
            }

            // Do send

            if let fileURL = YepAudioService.sharedManager.audioFileURL {
                if let withFriend = self.conversation.withFriend {
                    sendAudioInFilePath(fileURL.path!, orFileData: nil, metaData: metaData, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { message -> Void in

                        dispatch_async(dispatch_get_main_queue()) {
                            let realm = message.realm
                            realm.beginWriteTransaction()
                            message.localAttachmentName = fileURL.path!.lastPathComponent.stringByDeletingPathExtension
                            message.mediaType = MessageMediaType.Audio.rawValue
                            if let metaData = metaData {
                                message.metaData = metaData
                            }
                            realm.commitWriteTransaction()

                            self.updateConversationCollectionView()
                        }

                    }, failureHandler: { (reason, errorMessage) -> Void in
                        defaultFailureHandler(reason, errorMessage)
                        // TODO: 音频发送失败
                        
                    }, completion: { (success) -> Void in
                        println("send audio to friend: \(success)")
                    })

                } else if let withGroup = self.conversation.withGroup {
                    sendAudioInFilePath(fileURL.path!, orFileData: nil, metaData: metaData, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { (message) -> Void in

                        dispatch_async(dispatch_get_main_queue()) {
                            let realm = message.realm
                            realm.beginWriteTransaction()
                            message.localAttachmentName = fileURL.path!.lastPathComponent.stringByDeletingPathExtension
                            message.mediaType = MessageMediaType.Audio.rawValue
                            if let metaData = metaData {
                                message.metaData = metaData
                            }
                            realm.commitWriteTransaction()

                            self.updateConversationCollectionView()
                        }

                    }, failureHandler: { (reason, errorMessage) -> Void in
                        defaultFailureHandler(reason, errorMessage)
                        // TODO: 音频发送失败

                    }, completion: { (success) -> Void in
                        println("send audio to group: \(success)")
                    })
                }
            }
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
        
        self.waverView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - self.messageToolbar.frame.size.height)
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

    private func heightOfMessage(message: Message) -> CGFloat {
        switch message.mediaType {
        case MessageMediaType.Image.rawValue:
            //return messageImageHeight + 10 + 10
            if !message.metaData.isEmpty {
                if let data = message.metaData.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                    if let metaDataDict = decodeJSON(data) {
                        if
                            let imageWidth = metaDataDict["image_width"] as? CGFloat,
                            let imageHeight = metaDataDict["image_height"] as? CGFloat {

                                let aspectRatio = imageWidth / imageHeight

                                if aspectRatio >= 1 {
                                    return messageImageWidth / aspectRatio
                                } else {
                                    return 200
                                }
                        }
                    }
                }
            }

            return messageImageHeight

        case MessageMediaType.Audio.rawValue:
            return 50

        default:
            let rect = message.textContent.boundingRectWithSize(CGSize(width: messageTextLabelMaxWidth, height: CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: messageTextAttributes, context: nil)

            return max(ceil(rect.height) + 14 + 20, YepConfig.chatCellAvatarSize() + 20) + 10
        }
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

                let height = heightOfMessage(message) + 10 // TODO: +10 cell line space

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

        let message = messages.objectAtIndex(UInt(indexPath.item)) as! Message

        downloadAttachmentOfMessage(message)
        
        if let sender = message.fromFriend {
            if sender.friendState != UserFriendState.Me.rawValue {
                switch message.mediaType {
                case MessageMediaType.Image.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftImageCellIdentifier, forIndexPath: indexPath) as! ChatLeftImageCell

                    AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { roundImage in
                        dispatch_async(dispatch_get_main_queue()) {
                            cell.avatarImageView.image = roundImage
                        }
                    }

                    cell.messageImageView.alpha = 0.0
                    ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImageWidth, height: messageImageHeight), tailDirection: .Left) { image in
                        dispatch_async(dispatch_get_main_queue()) {
                            cell.messageImageView.image = image

                            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                                cell.messageImageView.alpha = 1.0
                            }, completion: { (finished) -> Void in
                            })
                        }
                    }

                    return cell

                case MessageMediaType.Audio.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftAudioCellIdentifier, forIndexPath: indexPath) as! ChatLeftAudioCell

                    AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { roundImage in
                        dispatch_async(dispatch_get_main_queue()) {
                            cell.avatarImageView.image = roundImage
                        }
                    }

                    if !message.metaData.isEmpty {

                        if let data = message.metaData.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                            if let metaDataDict = decodeJSON(data) {

                                if let audioSamples = metaDataDict["audio_samples"] as? [CGFloat] {
                                    cell.sampleViewWidthConstraint.constant = CGFloat(audioSamples.count) * (YepConfig.audioSampleWidth() + YepConfig.audioSampleGap()) - YepConfig.audioSampleGap() // 最后最后一个 gap 不要
                                    cell.sampleView.samples = audioSamples

                                    if let audioDuration = metaDataDict["audio_duration"] as? Double {
                                        cell.audioDurationLabel.text = NSString(format: "%.1f\"", audioDuration) as String
                                    }
                                }
                            }

                        } else {
                            cell.sampleViewWidthConstraint.constant = 15 * (YepConfig.audioSampleWidth() + YepConfig.audioSampleGap())
                            cell.audioDurationLabel.text = ""
                        }
                    }
                    
                    return cell

                default:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftTextCellIdentifier, forIndexPath: indexPath) as! ChatLeftTextCell

                    cell.textContentLabel.text = message.textContent

                    AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { roundImage in
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
                            AvatarCache.sharedInstance.roundAvatarOfUser(me, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { roundImage in
                                dispatch_async(dispatch_get_main_queue()) {
                                    cell.avatarImageView.image = roundImage
                                }
                            }

                            cell.messageImageView.alpha = 0.0

                            if message.metaData.isEmpty {
                                ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImageWidth, height: messageImageHeight), tailDirection: .Right) { image in
                                    dispatch_async(dispatch_get_main_queue()) {
                                        cell.messageImageView.image = image

                                        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                                            cell.messageImageView.alpha = 1.0
                                            }, completion: { (finished) -> Void in
                                        })
                                    }
                                }

                            } else {
                                if let data = message.metaData.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                                    if let metaDataDict = decodeJSON(data) {
                                        if
                                            let imageWidth = metaDataDict["image_width"] as? CGFloat,
                                            let imageHeight = metaDataDict["image_height"] as? CGFloat {

                                                let aspectRatio = imageWidth / imageHeight



                                                if aspectRatio >= 1 {
                                                    cell.messageImageViewWidthConstrint.constant = messageImageWidth

                                                    ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImageWidth, height: messageImageWidth / aspectRatio), tailDirection: .Right) { image in
                                                        dispatch_async(dispatch_get_main_queue()) {
                                                            cell.messageImageView.image = image

                                                            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                                                                cell.messageImageView.alpha = 1.0
                                                            }, completion: { (finished) -> Void in
                                                            })
                                                        }
                                                    }

                                                } else {
                                                    cell.messageImageViewWidthConstrint.constant = 200 * aspectRatio

                                                    ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: 200 * aspectRatio, height: 200), tailDirection: .Right) { image in
                                                        dispatch_async(dispatch_get_main_queue()) {
                                                            cell.messageImageView.image = image

                                                            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                                                                cell.messageImageView.alpha = 1.0
                                                            }, completion: { (finished) -> Void in
                                                            })
                                                        }
                                                    }
                                                }


                                        }
                                    }
                                }
                            }
                    }
                    
                    return cell

                case MessageMediaType.Audio.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightAudioCellIdentifier, forIndexPath: indexPath) as! ChatRightAudioCell

                    AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { roundImage in
                        dispatch_async(dispatch_get_main_queue()) {
                            cell.avatarImageView.image = roundImage
                        }
                    }

                    if !message.metaData.isEmpty {

                        if let data = message.metaData.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                            if let metaDataDict = decodeJSON(data) {

                                if let audioSamples = metaDataDict["audio_samples"] as? [CGFloat] {
                                    cell.sampleViewWidthConstraint.constant = CGFloat(audioSamples.count) * (YepConfig.audioSampleWidth() + YepConfig.audioSampleGap()) - YepConfig.audioSampleGap() // 最后一个 gap 不要
                                    cell.sampleView.samples = audioSamples

                                    if let audioDuration = metaDataDict["audio_duration"] as? Double {
                                        cell.audioDurationLabel.text = NSString(format: "%.1f\"", audioDuration) as String
                                    }
                                }
                            }

                        } else {
                            cell.sampleViewWidthConstraint.constant = 15 * (YepConfig.audioSampleWidth() + YepConfig.audioSampleGap())
                            cell.audioDurationLabel.text = ""
                        }
                    }

                    return cell

                default:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightTextCellIdentifier, forIndexPath: indexPath) as! ChatRightTextCell

                    cell.textContentLabel.text = message.textContent

                    AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { roundImage in
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
            cell.avatarImageView.image = AvatarCache.sharedInstance.defaultRoundAvatarOfRadius(YepConfig.chatCellAvatarSize() * 0.5)

            return cell
        }

    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        let message = messages.objectAtIndex(UInt(indexPath.item)) as! Message

        return CGSizeMake(collectionViewWidth, heightOfMessage(message))
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: sectionInsetTop, left: 0, bottom: sectionInsetBottom, right: 0)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if isKeyboardVisible {
            view.endEditing(true)

        } else {
            let message = messages.objectAtIndex(UInt(indexPath.item)) as! Message

            switch message.mediaType {
            case MessageMediaType.Image.rawValue:
                break

            case MessageMediaType.Video.rawValue:
                break // TODO: download video

            case MessageMediaType.Audio.rawValue:

                let fileName = message.localAttachmentName

                if !fileName.isEmpty {
                    if let fileURL = NSFileManager.yepMessageAudioURLWithName(fileName) {
                        YepAudioService.sharedManager.playAudioWithURL(fileURL)
                    }

                } else {
                    println("please wait for download")
                }

            default:
                break
            }

        }
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

        // Prepare meta data

        var metaData: String? = nil

        let audioMetaDataInfo = ["image_width": image.size.width, "image_height": image.size.height]

        if let audioMetaData = NSJSONSerialization.dataWithJSONObject(audioMetaDataInfo, options: nil, error: nil) {
            let audioMetaDataString = NSString(data: audioMetaData, encoding: NSUTF8StringEncoding) as? String
            metaData = audioMetaDataString
        }


        // Do send

        var imageData = UIImageJPEGRepresentation(image, YepConfig.messageImageCompressionQuality())

        let messageImageName = NSUUID().UUIDString

        if let withFriend = self.conversation.withFriend {

            sendImageInFilePath(nil, orFileData: imageData, metaData: nil, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { message -> Void in

                dispatch_async(dispatch_get_main_queue()) {

                    if let messageImageURL = NSFileManager.saveMessageImageData(imageData, withName: messageImageName) {
                        let realm = message.realm
                        realm.beginWriteTransaction()
                        message.localAttachmentName = messageImageName
                        message.mediaType = MessageMediaType.Image.rawValue
                        if let metaData = metaData {
                            message.metaData = metaData
                        }
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
            sendImageInFilePath(nil, orFileData: imageData, metaData: nil, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { message -> Void in

                dispatch_async(dispatch_get_main_queue()) {
                    if let messageImageURL = NSFileManager.saveMessageImageData(imageData, withName: messageImageName) {
                        let realm = message.realm
                        realm.beginWriteTransaction()
                        message.localAttachmentName = messageImageName
                        message.mediaType = MessageMediaType.Image.rawValue
                        if let metaData = metaData {
                            message.metaData = metaData
                        }
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


        dismissViewControllerAnimated(true, completion: nil)
    }
}
