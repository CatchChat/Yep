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

    let messagesBunchCount = 12 // TODO: 分段载入的“一束”消息的数量
    var displayedMessagesRange = NSRange()


    // 上一次更新 UI 时的消息数
    var lastTimeMessagesCount: UInt = 0

    lazy var sectionDateFormatter: NSDateFormatter =  {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        return dateFormatter
        }()

    lazy var sectionDateInCurrentWeekFormatter: NSDateFormatter =  {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEEE HH:mm"
        return dateFormatter
        }()


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

    lazy var pullToRefreshView = PullToRefreshView()
    
    @IBOutlet weak var conversationCollectionView: UICollectionView!

    @IBOutlet weak var messageToolbar: MessageToolbar!
    @IBOutlet weak var messageToolbarBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var moreMessageTypesViewHeightConstraint: NSLayoutConstraint!
    let moreMessageTypesViewHeightConstraintConstant: CGFloat = 200

    @IBOutlet weak var choosePhotoButton: MessageTypeButton!
    @IBOutlet weak var takePhotoButton: MessageTypeButton!
    @IBOutlet weak var addLocationButton: MessageTypeButton!
    @IBOutlet weak var addContactButton: MessageTypeButton!


    var waverView: YepWaverView!
    var samplesCount = 0
    let samplingInterval = 6

    let sectionInsetTop: CGFloat = 10
    let sectionInsetBottom: CGFloat = 10

    let messageTextAttributes = [NSFontAttributeName: UIFont.chatTextFont()]
    lazy var messageTextLabelMaxWidth: CGFloat = {
        let maxWidth = self.collectionViewWidth - (YepConfig.chatCellGapBetweenWallAndAvatar() + YepConfig.chatCellAvatarSize() + YepConfig.chatCellGapBetweenTextContentLabelAndAvatar() + YepConfig.chatTextGapBetweenWallAndContentLabel())
        return maxWidth
        }()

    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.conversationCollectionView.bounds)
        }()

    lazy var messageImagePreferredWidth: CGFloat = {
        return ceil(self.collectionViewWidth * 0.6)
        }()
    lazy var messageImagePreferredHeight: CGFloat = {
        return ceil(self.collectionViewWidth * 0.65)
        }()

    let messageImagePreferredAspectRatio: CGFloat = 4.0 / 3.0

    let chatSectionDateCellIdentifier = "ChatSectionDateCell"
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

        navigationController?.interactivePopGestureRecognizer.delaysTouchesBegan = false

        if messages.count >= UInt(messagesBunchCount) {
            displayedMessagesRange = NSRange(location: Int(messages.count) - messagesBunchCount, length: messagesBunchCount)
        } else {
            displayedMessagesRange = NSRange(location: 0, length: Int(messages.count))
        }


        let undoBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Undo, target: self, action: "undoMessageSend")
        navigationItem.rightBarButtonItem = undoBarButtonItem

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateConversationCollectionView", name: YepNewMessagesReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadConversationCollectionView", name: YepUpdatedProfileAvatarNotification, object: nil)


        makePullToRefreshView()

        conversationCollectionView.alwaysBounceVertical = true

        conversationCollectionView.registerNib(UINib(nibName: chatSectionDateCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatSectionDateCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatLeftTextCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatLeftTextCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatRightTextCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatRightTextCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatLeftImageCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatLeftImageCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatRightImageCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatRightImageCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatLeftAudioCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatLeftAudioCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatRightAudioCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatRightAudioCellIdentifier)
        
        conversationCollectionView.bounces = true

        messageToolbarBottomConstraint.constant = 0
        moreMessageTypesViewHeightConstraint.constant = moreMessageTypesViewHeightConstraintConstant

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

                    self.waverView.waver.level = CGFloat(normalizedValue)
                }
            }
        }

        // MARK: Audio Send

        messageToolbar.voiceSendBeginAction = { messageToolbar in
            self.view.window?.addSubview(self.waverView)

            let audioFileName = NSUUID().UUIDString

            self.waverView.waver.resetWaveSamples()
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

            if let audioSamples = self.waverView.waver.compressSamples() {

                var audioSamples = audioSamples
                // 浮点数最多两位小数，使下面计算 metaData 时不至于太长
                for i in 0..<audioSamples.count {
                    var sample = audioSamples[i]
                    sample = round(sample * 100.0) / 100.0
                    audioSamples[i] = sample
                }

                if let fileURL = YepAudioService.sharedManager.audioFileURL {
                    let audioAsset = AVURLAsset(URL: fileURL, options: nil)
                    let audioDuration = CMTimeGetSeconds(audioAsset.duration) as Double

                    println("\nComporessed \(audioSamples)")

                    let audioMetaDataInfo = ["audio_samples": audioSamples, "audio_duration": audioDuration]

                    if let audioMetaData = NSJSONSerialization.dataWithJSONObject(audioMetaDataInfo, options: nil, error: nil) {
                        let audioMetaDataString = NSString(data: audioMetaData, encoding: NSUTF8StringEncoding) as? String
                        metaData = audioMetaDataString
                    }
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

        // MARK: MessageToolbar State Transitions

        messageToolbar.stateTransitionAction = { (previousState, currentState) in

            switch (previousState, currentState) {
            case (.MoreMessages, .Default):
                if !self.isKeyboardVisible {

                    UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in
                        self.messageToolbarBottomConstraint.constant = 0

                        self.view.layoutIfNeeded()

                    }, completion: { (finished) -> Void in
                    })
                }

            default:
                if currentState == .MoreMessages {
                    UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in
                        self.messageToolbarBottomConstraint.constant = self.moreMessageTypesViewHeightConstraintConstant

                        self.view.layoutIfNeeded()

                    }, completion: { (finished) -> Void in
                    })
                }
            }
        }

        // MARK: More Message Types

        choosePhotoButton.tapAction = {
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary){
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
                imagePicker.allowsEditing = false

                self.presentViewController(imagePicker, animated: true, completion: nil)
            }
        }

        takePhotoButton.tapAction = {
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
                imagePicker.allowsEditing = false

                self.presentViewController(imagePicker, animated: true, completion: nil)
            }
        }

        addLocationButton.tapAction = {
            YepAlert.alertSorry(message: "TODO: Add Location", inViewController: self)
        }

        addContactButton.tapAction = {
            YepAlert.alertSorry(message: "TODO: Add Contact", inViewController: self)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // 初始时移动一次到底部
        if !conversationCollectionViewHasBeenMovedToBottomOnce {
            conversationCollectionViewHasBeenMovedToBottomOnce = true

            // 先调整一下初次的 contentInset
            setConversaitonCollectionViewOriginalContentInset()

            if displayedMessagesRange.length > 0 {
                conversationCollectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: displayedMessagesRange.length - 1, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.Bottom, animated: false)
            }
        }
        
        self.waverView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - self.messageToolbar.frame.size.height)
    }

    // MARK: UI

    private func makePullToRefreshView() {
        pullToRefreshView.delegate = self

        conversationCollectionView.insertSubview(pullToRefreshView, atIndex: 0)

        pullToRefreshView.setTranslatesAutoresizingMaskIntoConstraints(false)

        let viewsDictionary = [
            "pullToRefreshView": pullToRefreshView,
            "view": view,
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(-200)-[pullToRefreshView(200)]", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        // 非常奇怪，若直接用 "H:|[pullToRefreshView]|" 得到的实际宽度为 0
        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[pullToRefreshView(==view)]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints(constraintsH)
    }

    // MARK: Private

    private func setConversaitonCollectionViewContentInsetBottom(bottom: CGFloat) {
        var contentInset = conversationCollectionView.contentInset
        contentInset.bottom = bottom
        conversationCollectionView.contentInset = contentInset
    }

    private func setConversaitonCollectionViewOriginalContentInset() {
        setConversaitonCollectionViewContentInsetBottom(CGRectGetHeight(messageToolbar.bounds) + sectionInsetBottom)
    }

    private var messageHeights = [String: CGFloat]()
    private func heightOfMessage(message: Message) -> CGFloat {

        let key = message.messageID

        if !key.isEmpty {
            if let messageHeight = messageHeights[key] {
                return messageHeight
            }
        }

        var height: CGFloat = 0

        switch message.mediaType {

        case MessageMediaType.Text.rawValue:
            let rect = message.textContent.boundingRectWithSize(CGSize(width: messageTextLabelMaxWidth, height: CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: messageTextAttributes, context: nil)

            height = max(ceil(rect.height) + (11 * 2), YepConfig.chatCellAvatarSize())

            if !key.isEmpty {
                textContentLabelWidths[key] = ceil(rect.width)
            }

        case MessageMediaType.Image.rawValue:

            if !message.metaData.isEmpty {
                if let data = message.metaData.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                    if let metaDataDict = decodeJSON(data) {
                        if
                            let imageWidth = metaDataDict["image_width"] as? CGFloat,
                            let imageHeight = metaDataDict["image_height"] as? CGFloat {

                                let aspectRatio = imageWidth / imageHeight

                                if aspectRatio >= 1 {
                                    return ceil(messageImagePreferredWidth / aspectRatio)
                                } else {
                                    return messageImagePreferredHeight
                                }
                        }
                    }
                }
            }

            height = ceil(messageImagePreferredWidth / messageImagePreferredAspectRatio)

        case MessageMediaType.Audio.rawValue:
            height = 40

        case MessageMediaType.SectionDate.rawValue:
            height = 20

        default:
            height = 20
        }

        if !key.isEmpty {
            messageHeights[key] = height
        }

        return height
    }

    private var textContentLabelWidths = [String: CGFloat]()
    private func textContentLabelWidthOfMessage(message: Message) -> CGFloat {
        let key = message.messageID

        if !key.isEmpty {
            if let textContentLabelWidth = textContentLabelWidths[key] {
                return textContentLabelWidth
            }
        }

        let rect = message.textContent.boundingRectWithSize(CGSize(width: messageTextLabelMaxWidth, height: CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: messageTextAttributes, context: nil)

        let width = ceil(rect.width)

        if !key.isEmpty {
            textContentLabelWidths[key] = width
        }

        return width
    }

    private var audioPlayedDurations = [String: Double]()
    private func audioPlayedDurationOfMessage(message: Message) -> Double {
        let key = message.messageID

        if !key.isEmpty {
            if let playedDuration = audioPlayedDurations[key] {
                return playedDuration
            }
        }

        return 0
    }
    private func setAudioPlayedDuration(audioPlayedDuration: Double, ofMessage message: Message) {
        let key = message.messageID
        if !key.isEmpty {
            audioPlayedDurations[key] = audioPlayedDuration
        }
    }
    func updateAudioPlaybackProgress(timer: NSTimer) {
        func updateAudioCellOfMessage(message: Message, withCurrentTime currentTime: NSTimeInterval) {
            let indexPath = NSIndexPath(forItem: Int(messages.indexOfObject(message)) - displayedMessagesRange.location, inSection: 0)

            if let sender = message.fromFriend {
                if sender.friendState != UserFriendState.Me.rawValue {
                    if let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatLeftAudioCell {
                        cell.audioPlayedDuration = currentTime   
                    }

                } else {
                    if let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatRightAudioCell {
                        cell.audioPlayedDuration = currentTime
                    }
                }
            }
        }

        if let audioPlayer = YepAudioService.sharedManager.audioPlayer {

            if let playingMessage = YepAudioService.sharedManager.playingMessage {

                let currentTime = audioPlayer.currentTime

                setAudioPlayedDuration(currentTime, ofMessage: playingMessage)

                updateAudioCellOfMessage(playingMessage, withCurrentTime: currentTime)
            }
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
        let newMessagesCount = Int(messages.count - _lastTimeMessagesCount)

        let lastDisplayedMessagesRange = displayedMessagesRange

        displayedMessagesRange.length += newMessagesCount

        var indexPaths = [NSIndexPath]()
        for i in 0..<newMessagesCount {
            let indexPath = NSIndexPath(forItem: lastDisplayedMessagesRange.length + i, inSection: 0)
            indexPaths.append(indexPath)
        }

        conversationCollectionView.insertItemsAtIndexPaths(indexPaths)

        if newMessagesCount > 0 {

            var newMessagesTotalHeight: CGFloat = 0

            for i in _lastTimeMessagesCount..<messages.count {
                let message = messages.objectAtIndex(i) as! Message

                let height = heightOfMessage(message) + 10 // TODO: +10 cell line space

                println("uuheight \(height)")
                newMessagesTotalHeight += height
            }
            
            let keyboardAndToolBarHeight = messageToolbarBottomConstraint.constant + CGRectGetHeight(messageToolbar.bounds)
            
            let totleMessagesHeight = conversationCollectionView.contentSize.height + keyboardAndToolBarHeight + 64.0 + newMessagesTotalHeight
            
            let visableMessageFieldHeight = conversationCollectionView.frame.size.height - (keyboardAndToolBarHeight + 64.0)
            
            let totalMessagesContentHeight = conversationCollectionView.contentSize.height + keyboardAndToolBarHeight + newMessagesTotalHeight
            
            println("Size is \(conversationCollectionView.contentSize.height) \(newMessagesTotalHeight) visableMessageFieldHeight \(visableMessageFieldHeight)")
            
            //Calculate the space can be used
            let useableSpace = visableMessageFieldHeight - conversationCollectionView.contentSize.height
            
            conversationCollectionView.contentSize = CGSizeMake(conversationCollectionView.contentSize.width, conversationCollectionView.contentSize.height + newMessagesTotalHeight)
            
            println("Size is after \(conversationCollectionView.contentSize.height)")

            if (totleMessagesHeight > conversationCollectionView.frame.size.height) {
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
        messageToolbar.state = .BeginTextInput
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
                    
                } else {
                    
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

                if self.messageToolbar.state != .MoreMessages {
                    self.messageToolbarBottomConstraint.constant = 0
                    self.view.layoutIfNeeded()
                }

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

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedMessagesRange.length
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let message = messages.objectAtIndex(UInt(displayedMessagesRange.location + indexPath.item)) as! Message

        if message.mediaType == MessageMediaType.SectionDate.rawValue {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatSectionDateCellIdentifier, forIndexPath: indexPath) as! ChatSectionDateCell

            if message.createdAt.isInCurrentWeek() {
                cell.sectionDateLabel.text = sectionDateInCurrentWeekFormatter.stringFromDate(message.createdAt)
            } else {
                cell.sectionDateLabel.text = sectionDateFormatter.stringFromDate(message.createdAt)
            }

            return cell
        }

        if let sender = message.fromFriend {

            if sender.friendState != UserFriendState.Me.rawValue { // from Friend

                // TODO: 需要更好的下载与 mark as read 逻辑：也许未下载的也可以 mark as read
                downloadAttachmentOfMessage(message)

                markAsReadMessage(message, failureHandler: nil) { success in
                    dispatch_async(dispatch_get_main_queue()) {
                        let realm = message.realm
                        realm.beginWriteTransaction()
                        message.readed = true
                        realm.commitWriteTransaction()

                        println("\(message.messageID) mark as read")
                    }
                }

                switch message.mediaType {
                case MessageMediaType.Image.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftImageCellIdentifier, forIndexPath: indexPath) as! ChatLeftImageCell

                    cell.configureWithMessage(message, messageImagePreferredWidth: messageImagePreferredWidth, messageImagePreferredHeight: messageImagePreferredHeight, messageImagePreferredAspectRatio: messageImagePreferredAspectRatio)
                    
                    return cell

                case MessageMediaType.Audio.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftAudioCellIdentifier, forIndexPath: indexPath) as! ChatLeftAudioCell

                    let audioPlayedDuration = audioPlayedDurationOfMessage(message)
                    cell.configureWithMessage(message, audioPlayedDuration: audioPlayedDuration)
                                        
                    return cell

                default:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftTextCellIdentifier, forIndexPath: indexPath) as! ChatLeftTextCell

                    cell.configureWithMessage(message, textContentLabelWidth: textContentLabelWidthOfMessage(message))
                    
                    return cell
                }

            } else { // from Me

                switch message.mediaType {
                case MessageMediaType.Image.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightImageCellIdentifier, forIndexPath: indexPath) as! ChatRightImageCell

                    cell.configureWithMessage(message, messageImagePreferredWidth: messageImagePreferredWidth, messageImagePreferredHeight: messageImagePreferredHeight, messageImagePreferredAspectRatio: messageImagePreferredAspectRatio)
                    
                    return cell

                case MessageMediaType.Audio.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightAudioCellIdentifier, forIndexPath: indexPath) as! ChatRightAudioCell

                    let audioPlayedDuration = audioPlayedDurationOfMessage(message)
                    cell.configureWithMessage(message, audioPlayedDuration: audioPlayedDuration)

                    return cell

                default:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightTextCellIdentifier, forIndexPath: indexPath) as! ChatRightTextCell

                    cell.configureWithMessage(message, textContentLabelWidth: textContentLabelWidthOfMessage(message))
                    
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

        let message = messages.objectAtIndex(UInt(displayedMessagesRange.location + indexPath.item)) as! Message

        return CGSizeMake(collectionViewWidth, heightOfMessage(message))
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: sectionInsetTop, left: 0, bottom: sectionInsetBottom, right: 0)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if isKeyboardVisible {
            messageToolbar.state = .Default

        } else {
            let message = messages.objectAtIndex(UInt(displayedMessagesRange.location + indexPath.item)) as! Message

            switch message.mediaType {
            case MessageMediaType.Image.rawValue:
                break

            case MessageMediaType.Video.rawValue:
                break // TODO: download video

            case MessageMediaType.Audio.rawValue:

                if let audioPlayer = YepAudioService.sharedManager.audioPlayer {
                    if let playingMessage = YepAudioService.sharedManager.playingMessage {
                        if audioPlayer.playing {

                            audioPlayer.pause()

                            if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
                                playbackTimer.invalidate()
                            }

                            let indexPath = NSIndexPath(forItem: Int(messages.indexOfObject(playingMessage)), inSection: 0)
                            if let sender = playingMessage.fromFriend {
                                if sender.friendState != UserFriendState.Me.rawValue {
                                    if let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatLeftAudioCell {
                                        cell.playing = false
                                    }

                                } else {
                                    if let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatRightAudioCell {
                                        cell.playing = false
                                    }
                                }
                            }

                            if message.isEqualToObject(playingMessage) {
                                return
                            }
                        }
                    }
                }

                let audioPlayedDuration = audioPlayedDurationOfMessage(message) as NSTimeInterval
                YepAudioService.sharedManager.playAudioWithMessage(message, beginFromTime: audioPlayedDuration, delegate: self) {
                    let playbackTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: self, selector: "updateAudioPlaybackProgress:", userInfo: nil, repeats: true)
                    YepAudioService.sharedManager.playbackTimer = playbackTimer
                }

            default:
                break
            }

        }
    }

    // MARK: UIScrollViewDelegate

    func scrollViewDidScroll(scrollView: UIScrollView) {
        pullToRefreshView.scrollViewDidScroll(scrollView)
    }

    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        pullToRefreshView.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
}

// MARK: PullToRefreshViewDelegate

extension ConversationViewController: PullToRefreshViewDelegate {
    func pulllToRefreshViewDidRefresh(pulllToRefreshView: PullToRefreshView) {

        func delayBySeconds(seconds: Double, delayedCode: ()->()) {
            let targetTime = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * seconds))
            dispatch_after(targetTime, dispatch_get_main_queue()) {
                delayedCode()
            }
        }

        delayBySeconds(1) {
            pulllToRefreshView.endRefreshingAndDoFurtherAction() {

                let lastDisplayedMessagesRange = self.displayedMessagesRange

                var newMessagesCount = self.messagesBunchCount

                if (self.displayedMessagesRange.location - newMessagesCount) < 0 {
                    newMessagesCount = self.displayedMessagesRange.location - newMessagesCount
                }

                if newMessagesCount > 0 {
                    self.displayedMessagesRange.location -= newMessagesCount
                    self.displayedMessagesRange.length += newMessagesCount

                    self.lastTimeMessagesCount = self.messages.count // 同样需要纪录它

                    var indexPaths = [NSIndexPath]()
                    for i in 0..<newMessagesCount {
                        let indexPath = NSIndexPath(forItem: Int(i), inSection: 0)
                        indexPaths.append(indexPath)
                    }

                    let bottomOffset = self.conversationCollectionView.contentSize.height - self.conversationCollectionView.contentOffset.y
                    
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)

                    self.conversationCollectionView.performBatchUpdates({ () -> Void in
                        self.conversationCollectionView.insertItemsAtIndexPaths(indexPaths)

                    }, completion: { (finished) -> Void in
                        var contentOffset = self.conversationCollectionView.contentOffset
                        contentOffset.y = self.conversationCollectionView.contentSize.height - bottomOffset

                        self.conversationCollectionView.setContentOffset(contentOffset, animated: false)

                        CATransaction.commit()

                        // 上面的 CATransaction 保证了 CollectionView 在插入后不闪动
                        // 此时再做个 scroll 动画比较自然
                        let indexPath = NSIndexPath(forItem: newMessagesCount - 1, inSection: 0)
                        self.conversationCollectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredVertically, animated: true)
                    })
                }
            }
        }
    }

    func scrollView() -> UIScrollView {
        return conversationCollectionView
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

// MARK: AVAudioPlayerDelegate

extension ConversationViewController: AVAudioPlayerDelegate {
    func audioPlayerBeginInterruption(player: AVAudioPlayer!) {
        println("audioPlayerBeginInterruption")

        if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
            playbackTimer.invalidate()
        }
    }

    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer!, error: NSError!) {
        println("audioPlayerDecodeErrorDidOccur")
    }

    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        println("audioPlayerDidFinishPlaying \(flag)")

        if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
            playbackTimer.invalidate()
        }

        if let playingMessage = YepAudioService.sharedManager.playingMessage {
            setAudioPlayedDuration(0, ofMessage: playingMessage)
        }
    }

    func audioPlayerEndInterruption(player: AVAudioPlayer!) {
        println("audioPlayerEndInterruption")
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

            sendImageInFilePath(nil, orFileData: imageData, metaData: metaData, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { message -> Void in

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
