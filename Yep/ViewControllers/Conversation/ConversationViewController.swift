//
//  ConversationViewController.swift
//  Yep
//
//  Created by NIX on 15/3/23.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import AVFoundation
import MobileCoreServices

class ConversationViewController: UIViewController {

    struct Notification {
        static let MessageSent = "MessageSentNotification"
    }

    var conversation: Conversation!

    var realm: Realm!

    lazy var messages: Results<Message> = {
        return messagesOfConversation(self.conversation, inRealm: self.realm)
        }()

    let messagesBunchCount = 50 // TODO: 分段载入的“一束”消息的数量
    var displayedMessagesRange = NSRange()


    // 上一次更新 UI 时的消息数
    var lastTimeMessagesCount: Int = 0

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

    var messagePreviewTransitionManager: ConversationMessagePreviewTransitionManager?


    var conversationCollectionViewHasBeenMovedToBottomOnce = false

    // Keyboard 动画相关
    var conversationCollectionViewContentOffsetBeforeKeyboardWillShow = CGPointZero
    var conversationCollectionViewContentOffsetBeforeKeyboardWillHide = CGPointZero
    var isKeyboardVisible = false
    var keyboardHeight: CGFloat = 0

    var checkTypingStatusTimer: NSTimer?
    
    var typingResetDelay: Float = 0
    
    var keyboardShowTimes = 0 {
        willSet {
//            println("set keyboardShowTimes \(newValue)")
            
            if newValue == 0 {
                if !self.isKeyboardVisible {
                    self.isKeyboardVisible = true
                }
            }
        }
    }

    lazy var titleView: ConversationTitleView = {
        let titleView = ConversationTitleView(frame: CGRect(origin: CGPointZero, size: CGSize(width: 150, height: 44)))
        titleView.nameLabel.text = nameOfConversation(self.conversation)

        self.updateStateInfoOfTitleView(titleView)

        return titleView
        }()
    
    lazy var pullToRefreshView = PullToRefreshView()
    
    @IBOutlet weak var conversationCollectionView: UICollectionView!

    @IBOutlet weak var messageToolbar: MessageToolbar!
    @IBOutlet weak var messageToolbarBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var moreMessageTypesViewHeightConstraint: NSLayoutConstraint!
    let moreMessageTypesViewHeightConstraintConstant: CGFloat = 110

    @IBOutlet weak var choosePhotoButton: MessageTypeButton!
    @IBOutlet weak var takePhotoButton: MessageTypeButton!
    @IBOutlet weak var addLocationButton: MessageTypeButton!


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
    let chatLeftVideoCellIdentifier = "ChatLeftVideoCell"
    let chatRightVideoCellIdentifier = "ChatRightVideoCell"
    let chatLeftLocationCellIdentifier =  "ChatLeftLocationCell"
    let chatRightLocationCellIdentifier =  "ChatRightLocationCell"
    


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
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        realm = Realm()

        navigationController?.interactivePopGestureRecognizer.delaysTouchesBegan = false

        if messages.count >= messagesBunchCount {
            displayedMessagesRange = NSRange(location: Int(messages.count) - messagesBunchCount, length: messagesBunchCount)
        } else {
            displayedMessagesRange = NSRange(location: 0, length: Int(messages.count))
        }

        navigationItem.titleView = titleView

        if let withFriend = conversation?.withFriend {
            
            let avatarSize: CGFloat = 30.0
            
            AvatarCache.sharedInstance.roundAvatarOfUser(withFriend, withRadius: avatarSize * 0.5, completion: { image in
                dispatch_async(dispatch_get_main_queue()) {
                    
                    let button = UIButton(frame: CGRect(origin: CGPointZero, size: CGSize(width: avatarSize, height: avatarSize)))
                    button.addTarget(self, action: "showProfile", forControlEvents: .TouchUpInside)
                    button.setImage(image, forState: .Normal)

                    let avatarBarButton = UIBarButtonItem(customView: button)

                    self.navigationItem.rightBarButtonItem = avatarBarButton
                }
            })
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateConversationCollectionViewDefault", name: YepNewMessagesReceivedNotification, object: nil)

        YepUserDefaults.avatarURLString.bindListener("ConversationViewController") { _ in
            self.reloadConversationCollectionView()
        }


        makePullToRefreshView()

        conversationCollectionView.alwaysBounceVertical = true

        conversationCollectionView.registerNib(UINib(nibName: chatSectionDateCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatSectionDateCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatLeftTextCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatLeftTextCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatRightTextCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatRightTextCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatLeftImageCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatLeftImageCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatRightImageCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatRightImageCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatLeftAudioCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatLeftAudioCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatRightAudioCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatRightAudioCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatLeftVideoCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatLeftVideoCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatRightVideoCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatRightVideoCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatLeftLocationCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatLeftLocationCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatRightLocationCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatRightLocationCellIdentifier)
        
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
                        self.updateConversationCollectionView(scrollToBottom: true)

                        NSNotificationCenter.defaultCenter().postNotificationName(Notification.MessageSent, object: nil)
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
                        self.updateConversationCollectionView(scrollToBottom: true)

                        NSNotificationCenter.defaultCenter().postNotificationName(Notification.MessageSent, object: nil)
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

        self.waverView.waver.waverCallback = { waver in
            if let audioRecorder = YepAudioService.sharedManager.audioRecorder {
                if (audioRecorder.recording) {
                    //println("Update waver")
                    audioRecorder.updateMeters()
                    
                    var normalizedValue = pow(10, audioRecorder.averagePowerForChannel(0)/40)
                    
                    waver.level = CGFloat(normalizedValue)
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
            
            if let withFriend = self.conversation.withFriend {
                var typingMessage: JSONDictionary = ["state": FayeService.InstantStateType.Audio.rawValue]
                
                FayeService.sharedManager.sendPrivateMessage(typingMessage, messageType: .Instant, userID: withFriend.userID, completion: { (result, messageID) in
                    println("Send recording \(result)")
                })
            }
        }
        
        messageToolbar.voiceSendCancelAction = { messageToolbar in
            self.waverView.removeFromSuperview()
            YepAudioService.sharedManager.endRecord()
        }
        
        messageToolbar.voiceSendEndAction = { messageToolbar in
            self.waverView.removeFromSuperview()
            if YepAudioService.sharedManager.audioRecorder?.currentTime < 0.5 {
                YepAudioService.sharedManager.endRecord()
                return
            }
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
                            if let realm = message.realm {
                                realm.beginWrite()
                                message.localAttachmentName = fileURL.path!.lastPathComponent.stringByDeletingPathExtension
                                message.mediaType = MessageMediaType.Audio.rawValue
                                if let metaData = metaData {
                                    message.metaData = metaData
                                }
                                realm.commitWrite()

                                self.updateConversationCollectionView(scrollToBottom: true)

                                NSNotificationCenter.defaultCenter().postNotificationName(Notification.MessageSent, object: nil)
                            }
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
                            if let realm = message.realm {
                                realm.beginWrite()
                                message.localAttachmentName = fileURL.path!.lastPathComponent.stringByDeletingPathExtension
                                message.mediaType = MessageMediaType.Audio.rawValue
                                if let metaData = metaData {
                                    message.metaData = metaData
                                }
                                realm.commitWrite()

                                self.updateConversationCollectionView(scrollToBottom: true)

                                NSNotificationCenter.defaultCenter().postNotificationName(Notification.MessageSent, object: nil)
                            }
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
                    self.adjustBackCollectionViewWithHeight(0, animationDuration: 0.3, animationCurveValue: 7)
                }else{
                    self.hideKeyboardAndShowMoreMessageView()
                }

            default:
                if currentState == .MoreMessages {
                    self.hideKeyboardAndShowMoreMessageView()
                }
            }
        }
    

        // MARK: More Message Types

        choosePhotoButton.tapAction = {
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary){
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .PhotoLibrary
                imagePicker.mediaTypes = [kUTTypeImage, kUTTypeMovie]
                imagePicker.videoQuality = .TypeMedium
                imagePicker.allowsEditing = false

                self.presentViewController(imagePicker, animated: true, completion: nil)
            }
        }

        takePhotoButton.tapAction = {
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .Camera
                imagePicker.mediaTypes = [kUTTypeImage, kUTTypeMovie]
                imagePicker.videoQuality = .TypeMedium
                imagePicker.allowsEditing = false

                self.presentViewController(imagePicker, animated: true, completion: nil)
            }
        }

        addLocationButton.tapAction = {
            self.performSegueWithIdentifier("presentPickLocation", sender: nil)
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        conversationCollectionViewHasBeenMovedToBottomOnce = true

        FayeService.sharedManager.delegate = self

        checkTypingStatusTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("checkTypingStatus"), userInfo: nil, repeats: true)
        
        messageToolbar.notifyTypingAction = {

            if let withFriend = self.conversation.withFriend {

                let typingMessage: JSONDictionary = ["state": FayeService.InstantStateType.Text.rawValue]

                FayeService.sharedManager.sendPrivateMessage(typingMessage, messageType: .Instant, userID: withFriend.userID, completion: { (result, messageID) in
                    println("Send typing \(result)")
                })
            }
        }
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        FayeService.sharedManager.delegate = nil
        checkTypingStatusTimer?.invalidate()

        self.waverView.removeFromSuperview()
    }
    
    func hideKeyboardAndShowMoreMessageView() {
        self.messageToolbar.messageTextView.resignFirstResponder()
        self.adjustCollectionViewWithViewHeight(self.moreMessageTypesViewHeightConstraintConstant, animationDuration: 0.3, animationCurveValue: 7, keyboard: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // 初始时移动一次到底部
        if !conversationCollectionViewHasBeenMovedToBottomOnce {
            

            // 先调整一下初次的 contentInset
            setConversaitonCollectionViewOriginalContentInset()
            
            //以前的方法不能保证边界情况滚到底部
            scrollToLastMessage()
        }
        
        self.waverView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - self.messageToolbar.frame.size.height)
    }
    
    func scrollToLastMessage() {
        
        if displayedMessagesRange.length > 0 {
            
            let keyboardAndToolBarHeight = messageToolbarBottomConstraint.constant + CGRectGetHeight(messageToolbar.bounds)
            let navicationBarAndKeyboardAndToolBarHeight = keyboardAndToolBarHeight + 64.0
            
            let visableMessageFieldHeight = conversationCollectionView.frame.size.height - navicationBarAndKeyboardAndToolBarHeight
            let useableSpace = visableMessageFieldHeight - conversationCollectionView.contentSize.height

            if (useableSpace > 0) {
                return

            } else {
                self.conversationCollectionView.contentOffset.y = self.conversationCollectionView.contentSize.height - self.conversationCollectionView.frame.size.height + keyboardAndToolBarHeight
            }
        }
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
                                    height = ceil(messageImagePreferredWidth / aspectRatio)
                                } else {
                                    height = messageImagePreferredHeight
                                }

                                break
                        }
                    }
                }
            }

            height = ceil(messageImagePreferredWidth / messageImagePreferredAspectRatio)

        case MessageMediaType.Audio.rawValue:
            height = 40

        case MessageMediaType.Video.rawValue:

            if !message.metaData.isEmpty {
                if let data = message.metaData.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                    if let metaDataDict = decodeJSON(data) {
                        if
                            let imageWidth = metaDataDict["video_width"] as? CGFloat,
                            let imageHeight = metaDataDict["video_height"] as? CGFloat {

                                let aspectRatio = imageWidth / imageHeight

                                if aspectRatio >= 1 {
                                    height = ceil(messageImagePreferredWidth / aspectRatio)
                                } else {
                                    height = messageImagePreferredHeight
                                }

                                break
                        }
                    }
                }
            }
            
            height = ceil(messageImagePreferredWidth / messageImagePreferredAspectRatio)

        case MessageMediaType.Location.rawValue:
            height = 108

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

            if let messageIndex = messages.indexOf(message) {

                let indexPath = NSIndexPath(forItem: messageIndex - displayedMessagesRange.location, inSection: 0)

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

    func showProfile() {
        performSegueWithIdentifier("showProfile", sender: nil)
    }
    
    func updateMoreMessageConversationCollectionView() {
        let moreMessageViewHeight = moreMessageTypesViewHeightConstraintConstant + CGRectGetHeight(messageToolbar.bounds)

    }
    
    func updateConversationCollectionViewDefault() {
        updateConversationCollectionView(scrollToBottom: false)
    }

    func updateConversationCollectionView(#scrollToBottom: Bool) {
        let keyboardAndToolBarHeight = messageToolbarBottomConstraint.constant + CGRectGetHeight(messageToolbar.bounds)
        adjustConversationCollectionViewWith(keyboardAndToolBarHeight, scrollToBottom: scrollToBottom)
    }
    
    func adjustConversationCollectionViewWith(adjustHeight: CGFloat, scrollToBottom: Bool) {
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
                let message = messages[i]
                
                let height = heightOfMessage(message) + 10 // TODO: +10 cell line space
                
                println("uuheight \(height)")
                newMessagesTotalHeight += height
            }
            
            let keyboardAndToolBarHeight = adjustHeight
            
            let navicationBarAndKeyboardAndToolBarHeight = keyboardAndToolBarHeight + 64.0
            
            let totleMessagesHeight = conversationCollectionView.contentSize.height + navicationBarAndKeyboardAndToolBarHeight + newMessagesTotalHeight
            
            let visableMessageFieldHeight = conversationCollectionView.frame.size.height - navicationBarAndKeyboardAndToolBarHeight
            
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
                        if scrollToBottom {
                            
                            self.conversationCollectionView.contentOffset.y = self.conversationCollectionView.contentSize.height - self.conversationCollectionView.frame.size.height + keyboardAndToolBarHeight
                            
                        }else {
                            self.conversationCollectionView.contentOffset.y += newMessagesTotalHeight
                        }
                        
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

    func updateStateInfoOfTitleView(titleView: ConversationTitleView) {
        if let timeAgo = lastSignDateOfConversation(self.conversation)?.timeAgo {
            titleView.stateInfoLabel.text = NSLocalizedString("Last sign at ", comment: "") + timeAgo.lowercaseString
        } else {
            titleView.stateInfoLabel.text = NSLocalizedString("Begin chat just now", comment: "")
        }
    }

    // MARK: Keyboard

    func handleKeyboardWillShowNotification(notification: NSNotification) {
        keyboardShowTimes += 1
        
//        println("Set offset before is \(conversationCollectionView.contentOffset)")

        if let userInfo = notification.userInfo {

            let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            let animationCurveValue = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedLongValue
            let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            let keyboardHeight = keyboardEndFrame.height

            self.keyboardHeight = keyboardHeight
            
            adjustCollectionViewWithViewHeight(keyboardHeight, animationDuration: animationDuration, animationCurveValue: animationCurveValue, keyboard: true)

        }
    }
    
    func adjustCollectionViewWithViewHeight(newHeight: CGFloat, animationDuration: NSTimeInterval, animationCurveValue: UInt, keyboard: Bool) {
        
        conversationCollectionViewContentOffsetBeforeKeyboardWillHide = CGPointZero
        if (conversationCollectionViewContentOffsetBeforeKeyboardWillShow == CGPointZero) {
            conversationCollectionViewContentOffsetBeforeKeyboardWillShow = conversationCollectionView.contentOffset
        }
        
        UIView.animateWithDuration(animationDuration, delay: 0, options: UIViewAnimationOptions(animationCurveValue << 16), animations: { () -> Void in
            
            self.messageToolbarBottomConstraint.constant = newHeight
            
            let keyboardAndToolBarHeight = newHeight + CGRectGetHeight(self.messageToolbar.bounds)
            
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
                    println("Set offset 1 is \(contentOffset)")
                    
                    self.conversationCollectionView.setContentOffset(contentOffset, animated: false)
                }
                
            } else {
                
                var contentOffset = self.conversationCollectionViewContentOffsetBeforeKeyboardWillShow
                contentOffset.y += newHeight
                
                println("Set offset 2 is \(contentOffset)")
                
                self.conversationCollectionView.setContentOffset(contentOffset, animated: false)
            }
            
            self.conversationCollectionView.contentInset.bottom = CGRectGetHeight(self.messageToolbar.bounds)  + newHeight
            
            self.view.layoutIfNeeded()
            
            }, completion: { (finished) -> Void in
                if keyboard {
                    self.keyboardShowTimes -= 1
                }
                
        })
    }

    func handleKeyboardWillHideNotification(notification: NSNotification) {

        if let userInfo = notification.userInfo {
            let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            let animationCurveValue = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedLongValue
            let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            let keyboardHeight = keyboardEndFrame.height
            adjustBackCollectionViewWithHeight(keyboardHeight, animationDuration: animationDuration, animationCurveValue: animationCurveValue)

        }
    }
    
    func adjustBackCollectionViewWithHeight(newHeight: CGFloat, animationDuration: NSTimeInterval, animationCurveValue: UInt) {
        
        self.conversationCollectionViewContentOffsetBeforeKeyboardWillShow = CGPointZero

        if (conversationCollectionViewContentOffsetBeforeKeyboardWillHide == CGPointZero) {
            conversationCollectionViewContentOffsetBeforeKeyboardWillHide = conversationCollectionView.contentOffset
        }

        UIView.animateWithDuration(animationDuration, delay: 0, options: UIViewAnimationOptions(animationCurveValue << 16), animations: { () -> Void in
            
            var contentOffset = self.conversationCollectionViewContentOffsetBeforeKeyboardWillHide

            self.messageToolbarBottomConstraint.constant = 0

            if self.messageToolbar.state != .MoreMessages {
                contentOffset.y -= newHeight

            } else {
                contentOffset.y -= (newHeight - self.moreMessageTypesViewHeightConstraintConstant)
            }
            
            //println("\(self.conversationCollectionViewContentOffsetBeforeKeyboardWillHide.y) \(contentOffset.y) \(self.conversationCollectionViewContentOffsetBeforeKeyboardWillHide.y-contentOffset.y)")
            self.conversationCollectionView.setContentOffset(contentOffset, animated: false)
            self.conversationCollectionView.contentInset.bottom = CGRectGetHeight(self.messageToolbar.bounds)

            self.view.layoutIfNeeded()

        }, completion: { (finished) -> Void in
        })
    }

    func handleKeyboardDidHideNotification(notification: NSNotification) {
        isKeyboardVisible = false
    }


    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showProfile" {

            let vc = segue.destinationViewController as! ProfileViewController

            if let withFriend = conversation?.withFriend {
                let profileUser = ProfileUser.UserType(withFriend)

                vc.profileUser = profileUser
                vc.isFromConversation = true
            }
        }

        if segue.identifier == "presentMessageMedia" {

            let vc = segue.destinationViewController as! MessageMediaViewController

            if let message = sender as? Message, messageIndex = messages.indexOf(message) {

                vc.message = message

                let indexPath = NSIndexPath(forRow: messageIndex - displayedMessagesRange.location , inSection: 0)

                if let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) {

                    var frame = CGRectZero
                    var transitionView: UIView?

                    if let sender = message.fromFriend {
                        if sender.friendState != UserFriendState.Me.rawValue {
                            switch message.mediaType {

                            case MessageMediaType.Image.rawValue:
                                let cell = cell as! ChatLeftImageCell
                                transitionView = cell.messageImageView
                                frame = cell.convertRect(cell.messageImageView.frame, toView: view)

                            case MessageMediaType.Video.rawValue:
                                let cell = cell as! ChatLeftVideoCell
                                transitionView = cell.thumbnailImageView
                                frame = cell.convertRect(cell.thumbnailImageView.frame, toView: view)

                            case MessageMediaType.Location.rawValue:
                                let cell = cell as! ChatLeftLocationCell
                                transitionView = cell.mapImageView
                                frame = cell.convertRect(cell.mapImageView.frame, toView: view)

                            default:
                                break
                            }

                        } else {
                            switch message.mediaType {
                                
                            case MessageMediaType.Image.rawValue:
                                let cell = cell as! ChatRightImageCell
                                transitionView = cell.messageImageView
                                frame = cell.convertRect(cell.messageImageView.frame, toView: view)

                            case MessageMediaType.Video.rawValue:
                                let cell = cell as! ChatRightVideoCell
                                transitionView = cell.thumbnailImageView
                                frame = cell.convertRect(cell.thumbnailImageView.frame, toView: view)

                            case MessageMediaType.Location.rawValue:
                                let cell = cell as! ChatRightLocationCell
                                transitionView = cell.mapImageView
                                frame = cell.convertRect(cell.mapImageView.frame, toView: view)

                            default:
                                break
                            }
                        }
                    }

                    vc.modalPresentationStyle = UIModalPresentationStyle.Custom

                    let transitionManager = ConversationMessagePreviewTransitionManager()
                    transitionManager.frame = frame
                    transitionManager.transitionView = transitionView

                    vc.transitioningDelegate = transitionManager

                    messagePreviewTransitionManager = transitionManager
                }
            }

        } else if segue.identifier == "presentPickLocation" {

            let nvc = segue.destinationViewController as! UINavigationController
            let vc = nvc.topViewController as! PickLocationViewController

            vc.sendLocationAction = { coordinate in

                if let withFriend = self.conversation.withFriend {

                    sendLocationWithCoordinate(coordinate, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { message in
                        dispatch_async(dispatch_get_main_queue()) {
                            self.updateConversationCollectionView(scrollToBottom: false)

                            NSNotificationCenter.defaultCenter().postNotificationName(Notification.MessageSent, object: nil)
                        }

                    }, failureHandler: { (reason, errorMessage) -> () in
                        defaultFailureHandler(reason, errorMessage)
                        // TODO: sendLocation 错误提醒

                    }, completion: { success -> Void in
                        println("sendLocation to friend: \(success)")
                    })

                } else if let withGroup = self.conversation.withGroup {

                    sendLocationWithCoordinate(coordinate, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { message in
                        dispatch_async(dispatch_get_main_queue()) {
                            self.updateConversationCollectionView(scrollToBottom: false)

                            NSNotificationCenter.defaultCenter().postNotificationName(Notification.MessageSent, object: nil)
                        }

                    }, failureHandler: { (reason, errorMessage) -> () in
                        defaultFailureHandler(reason, errorMessage)
                        // TODO: sendLocation 错误提醒

                    }, completion: { success -> Void in
                        println("sendLocation to group: \(success)")
                    })
                }
            }
        }
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

        let message = messages[displayedMessagesRange.location + indexPath.item]

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

                // 防止未在此界面时被标记
                if navigationController?.topViewController == self {
                    markAsReadMessage(message, failureHandler: nil) { success in
                        dispatch_async(dispatch_get_main_queue()) {
                            let realm = Realm()

                            if let message = messageWithMessageID(message.messageID, inRealm: realm) {
                                realm.write {
                                    message.readed = true
                                }

                                println("\(message.messageID) mark as read")
                            }
                        }
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

                case MessageMediaType.Video.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftVideoCellIdentifier, forIndexPath: indexPath) as! ChatLeftVideoCell

                    cell.configureWithMessage(message, messageImagePreferredWidth: messageImagePreferredWidth, messageImagePreferredHeight: messageImagePreferredHeight, messageImagePreferredAspectRatio: messageImagePreferredAspectRatio)

                    return cell

                case MessageMediaType.Location.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftLocationCellIdentifier, forIndexPath: indexPath) as! ChatLeftLocationCell

                    cell.configureWithMessage(message)

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

                case MessageMediaType.Video.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightVideoCellIdentifier, forIndexPath: indexPath) as! ChatRightVideoCell

                    cell.configureWithMessage(message, messageImagePreferredWidth: messageImagePreferredWidth, messageImagePreferredHeight: messageImagePreferredHeight, messageImagePreferredAspectRatio: messageImagePreferredAspectRatio)

                    return cell

                case MessageMediaType.Location.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightLocationCellIdentifier, forIndexPath: indexPath) as! ChatRightLocationCell

                    cell.configureWithMessage(message)
                    
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

        let message = messages[displayedMessagesRange.location + indexPath.item]

        return CGSizeMake(collectionViewWidth, heightOfMessage(message))
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: sectionInsetTop, left: 0, bottom: sectionInsetBottom, right: 0)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if isKeyboardVisible {
            messageToolbar.state = .Default

        } else {
            let message = messages[displayedMessagesRange.location + indexPath.item]

            switch message.mediaType {
            case MessageMediaType.Image.rawValue:
                performSegueWithIdentifier("presentMessageMedia", sender: message)

            case MessageMediaType.Video.rawValue:
                performSegueWithIdentifier("presentMessageMedia", sender: message)

            case MessageMediaType.Audio.rawValue:

                if let audioPlayer = YepAudioService.sharedManager.audioPlayer {
                    if let playingMessage = YepAudioService.sharedManager.playingMessage {
                        if audioPlayer.playing {

                            audioPlayer.pause()

                            if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
                                playbackTimer.invalidate()
                            }

                            if let sender = playingMessage.fromFriend, playingMessageIndex = messages.indexOf(playingMessage) {

                                let indexPath = NSIndexPath(forItem: playingMessageIndex - displayedMessagesRange.location, inSection: 0)

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

                            if message == playingMessage {
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
    
    func checkTypingStatus() {
        typingResetDelay = typingResetDelay - 0.5

        if typingResetDelay < 0 {
            self.updateStateInfoOfTitleView(titleView)
        }
    }
}

// MARK: FayeServiceDelegate

extension ConversationViewController: FayeServiceDelegate {

    func fayeRecievedInstantStateType(instantStateType: FayeService.InstantStateType, userID: String) {
        if let withFriend = conversation.withFriend {

            if userID == withFriend.userID {

                let nickname = withFriend.nickname

                let content = "\(nickname)" + NSLocalizedString(" is ", comment: "正在") + "\(instantStateType)"

                self.titleView.stateInfoLabel.text = "\(content)..."

                switch instantStateType {

                case .Text:
                    self.typingResetDelay = 0.5

                case .Audio:
                    self.typingResetDelay = 2.5
                }
            }
        }
    }
}

// MARK: PullToRefreshViewDelegate

extension ConversationViewController: PullToRefreshViewDelegate {
    
    func pulllToRefreshViewDidRefresh(pulllToRefreshView: PullToRefreshView) {

        delay(1) {
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

    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        println("finished recording \(flag)")

        // ios8 and later
    }

    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder!, error: NSError!) {
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

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {

        if let mediaType = info[UIImagePickerControllerMediaType] as? String {
            println("mediaType \(mediaType)")

            switch mediaType {
            case kUTTypeImage as! String:
                if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                    sendImage(image)
                }
            case kUTTypeMovie as! String:
                if let videoURL = info[UIImagePickerControllerMediaURL] as? NSURL {
                    println("videoURL \(videoURL)")
                    sendVideoWithVideoURL(videoURL)
                }
            default:
                break
            }
        }

        dismissViewControllerAnimated(true, completion: nil)
    }

    func sendImage(image: UIImage) {
        // Prepare meta data

        var metaData: String? = nil

        let audioMetaDataInfo = ["image_width": image.size.width, "image_height": image.size.height]

        if let audioMetaData = NSJSONSerialization.dataWithJSONObject(audioMetaDataInfo, options: nil, error: nil) {
            let audioMetaDataString = NSString(data: audioMetaData, encoding: NSUTF8StringEncoding) as? String
            metaData = audioMetaDataString
        }


        // Do send

        let imageData = UIImageJPEGRepresentation(image, YepConfig.messageImageCompressionQuality())

        let messageImageName = NSUUID().UUIDString

        if let withFriend = conversation.withFriend {

            sendImageInFilePath(nil, orFileData: imageData, metaData: metaData, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { message -> Void in

                dispatch_async(dispatch_get_main_queue()) {

                    if let messageImageURL = NSFileManager.saveMessageImageData(imageData, withName: messageImageName) {
                        if let realm = message.realm {
                            realm.beginWrite()
                            message.localAttachmentName = messageImageName
                            message.mediaType = MessageMediaType.Image.rawValue
                            if let metaData = metaData {
                                message.metaData = metaData
                            }
                            realm.commitWrite()
                        }
                    }

                    self.updateConversationCollectionView(scrollToBottom: true)

                    NSNotificationCenter.defaultCenter().postNotificationName(Notification.MessageSent, object: nil)
                }

            }, failureHandler: {(reason, errorMessage) -> () in
                defaultFailureHandler(reason, errorMessage)
                // TODO: sendImage 错误提醒

            }, completion: { success -> Void in
                println("sendImage to friend: \(success)")
            })

        } else if let withGroup = conversation.withGroup {
            sendImageInFilePath(nil, orFileData: imageData, metaData: nil, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { message -> Void in

                dispatch_async(dispatch_get_main_queue()) {
                    if let messageImageURL = NSFileManager.saveMessageImageData(imageData, withName: messageImageName) {
                        if let realm = message.realm {
                            realm.beginWrite()
                            message.localAttachmentName = messageImageName
                            message.mediaType = MessageMediaType.Image.rawValue
                            if let metaData = metaData {
                                message.metaData = metaData
                            }
                            realm.commitWrite()
                        }
                    }
                    
                    self.updateConversationCollectionView(scrollToBottom: true)

                    NSNotificationCenter.defaultCenter().postNotificationName(Notification.MessageSent, object: nil)
                }
                
            }, failureHandler: {(reason, errorMessage) -> () in
                defaultFailureHandler(reason, errorMessage)
                // TODO: sendImage 错误提醒
                    
            }, completion: { success -> Void in
                println("sendImage to group: \(success)")
            })
        }
    }

    func sendVideoWithVideoURL(videoURL: NSURL) {

        // Prepare meta data

        var metaData: String? = nil

        var thumbnailData: NSData?

        if let image = thumbnailImageOfVideoInVideoURL(videoURL) {
            let videoMetaDataInfo = ["video_width": image.size.width, "video_height": image.size.height]

            if let videoMetaData = NSJSONSerialization.dataWithJSONObject(videoMetaDataInfo, options: nil, error: nil) {
                let videoMetaDataString = NSString(data: videoMetaData, encoding: NSUTF8StringEncoding) as? String
                metaData = videoMetaDataString
            }

            thumbnailData = UIImageJPEGRepresentation(image, YepConfig.messageImageCompressionQuality())
        }

        let messageVideoName = NSUUID().UUIDString

        let afterCreatedMessageAction = { (message: Message) in
            dispatch_async(dispatch_get_main_queue()) {

                if let videoData = NSData(contentsOfURL: videoURL) {

                    if let messageVideoURL = NSFileManager.saveMessageVideoData(videoData, withName: messageVideoName) {
                        if let realm = message.realm {
                            realm.beginWrite()

                            if let thumbnailData = thumbnailData {
                                if let thumbnailURL = NSFileManager.saveMessageImageData(thumbnailData, withName: messageVideoName) {
                                    message.localThumbnailName = messageVideoName
                                }
                            }

                            message.localAttachmentName = messageVideoName

                            message.mediaType = MessageMediaType.Video.rawValue
                            if let metaData = metaData {
                                message.metaData = metaData
                            }
                            realm.commitWrite()
                        }
                    }

                    self.updateConversationCollectionView(scrollToBottom: false)

                    NSNotificationCenter.defaultCenter().postNotificationName(Notification.MessageSent, object: nil)
                }
            }
        }

        if let withFriend = conversation.withFriend {
            sendVideoInFilePath(videoURL.path!, orFileData: nil, metaData: metaData, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: afterCreatedMessageAction, failureHandler: {(reason, errorMessage) -> () in
                defaultFailureHandler(reason, errorMessage)
                // TODO: sendVideo 错误提醒

            }, completion: { success -> Void in
                println("sendVideo to friend: \(success)")
            })

        } else if let withGroup = conversation.withGroup {
            sendVideoInFilePath(videoURL.path!, orFileData: nil, metaData: nil, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: afterCreatedMessageAction, failureHandler: {(reason, errorMessage) -> () in
                defaultFailureHandler(reason, errorMessage)
                // TODO: sendVideo 错误提醒
                
            }, completion: { success -> Void in
                println("sendVideo to group: \(success)")
            })
        }
    }
}






