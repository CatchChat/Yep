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
import MapKit


struct MessageNotification {
    static let MessageStateChanged = "MessageStateChangedNotification"
}

class ConversationViewController: BaseViewController {

    @IBOutlet weak var swipeUpView: UIView!

    var conversation: Conversation!

    var realm: Realm!

    lazy var messages: Results<Message> = {
        return messagesOfConversation(self.conversation, inRealm: self.realm)
        }()

    let messagesBunchCount = 50 // TODO: 分段载入的“一束”消息的数量
    var displayedMessagesRange = NSRange()
    
    var realmChangeToken: NotificationToken?


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
    var navigationControllerDelegate: ConversationMessagePreviewNavigationControllerDelegate?


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

        let name = nameOfConversation(self.conversation)

        titleView.nameLabel.text = name

        self.updateStateInfoOfTitleView(titleView)

        self.navigationItem.title = name

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
    let chatStateCellIdentifier = "ChatStateCell"
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
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }

    deinit {
        updateUIWithKeyboardChange = false

        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures
            {
                if recognizer.isKindOfClass(UIScreenEdgePanGestureRecognizer)
                {
                    conversationCollectionView.panGestureRecognizer.requireGestureRecognizerToFail(recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }
        
        var layout = ConversationLayout()
        layout.minimumLineSpacing = 5
        conversationCollectionView.setCollectionViewLayout(layout, animated: false)
        
        self.swipeUpView.hidden = true
        realm = Realm()
        
        realmChangeToken = realm.addNotificationBlock { (notification, realm) -> Void in
            if notification.rawValue == "RLMRealmDidChangeNotification"{
            }
        }

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

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleReceivedNewMessagesNotification:", name: YepNewMessagesReceivedNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "cleanForLogout", name: EditProfileViewController.Notification.Logout, object: nil)

        YepUserDefaults.avatarURLString.bindListener("ConversationViewController") { [unowned self] _ in
            self.reloadConversationCollectionView()
        }


        makePullToRefreshView()

        conversationCollectionView.alwaysBounceVertical = true

        conversationCollectionView.registerNib(UINib(nibName: chatStateCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatStateCellIdentifier)
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

        messageToolbar.textSendAction = { [unowned self] messageToolbar in
            let text = messageToolbar.messageTextView.text!

            self.cleanTextInput()

            if let withFriend = self.conversation.withFriend {

                sendText(text, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { message in

                    dispatch_async(dispatch_get_main_queue()) {
                        self.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { success in
                        })
                    }

                }, failureHandler: { (reason, errorMessage) -> () in
                    defaultFailureHandler(reason, errorMessage)
                    // TODO: sendText 错误提醒

                }, completion: { success -> Void in
                    println("sendText to friend: \(success)")
                })

            } else if let withGroup = self.conversation.withGroup {
                sendText(text, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { [unowned self] message in

                    dispatch_async(dispatch_get_main_queue()) {
                        self.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { _ in
                        })
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
                    
                    let normalizedValue = pow(10, audioRecorder.averagePowerForChannel(0)/40)
                    
                    waver.level = CGFloat(normalizedValue)
                }
            }
        }

        // MARK: Audio Send

        messageToolbar.voiceSendBeginAction = { [unowned self] messageToolbar in
            self.view.addSubview(self.waverView)
            self.swipeUpView.hidden = false
            self.view.bringSubviewToFront(self.swipeUpView)
            
            let audioFileName = NSUUID().UUIDString

            self.waverView.waver.resetWaveSamples()
            self.samplesCount = 0

            if let fileURL = NSFileManager.yepMessageAudioURLWithName(audioFileName) {
                YepAudioService.sharedManager.beginRecordWithFileURL(fileURL, audioRecorderDelegate: self)
            }
            
            if let withFriend = self.conversation.withFriend {
                var typingMessage: JSONDictionary = ["state": FayeService.InstantStateType.Audio.rawValue]

                if FayeService.sharedManager.client.connected {
                    FayeService.sharedManager.sendPrivateMessage(typingMessage, messageType: .Instant, userID: withFriend.userID, completion: { (result, messageID) in
                        println("Send recording \(result)")
                    })
                }
            }
        }
        
        messageToolbar.voiceSendCancelAction = { [unowned self] messageToolbar in
            self.swipeUpView.hidden = true
            self.waverView.removeFromSuperview()
            YepAudioService.sharedManager.endRecord()
        }
        
        messageToolbar.voiceSendEndAction = { [unowned self] messageToolbar in
            self.swipeUpView.hidden = true
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
                    sendAudioInFilePath(fileURL.path!, orFileData: nil, metaData: metaData, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { [unowned self] message in

                        dispatch_async(dispatch_get_main_queue()) {
                            if let realm = message.realm {
                                realm.beginWrite()
                                message.localAttachmentName = fileURL.path!.lastPathComponent.stringByDeletingPathExtension
                                message.mediaType = MessageMediaType.Audio.rawValue
                                if let metaData = metaData {
                                    message.metaData = metaData
                                }
                                realm.commitWrite()

                                self.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { _ in
                                })
                            }
                        }

                    }, failureHandler: { (reason, errorMessage) -> Void in
                        defaultFailureHandler(reason, errorMessage)
                        // TODO: 音频发送失败
                        
                    }, completion: { (success) -> Void in
                        println("send audio to friend: \(success)")
                    })

                } else if let withGroup = self.conversation.withGroup {
                    sendAudioInFilePath(fileURL.path!, orFileData: nil, metaData: metaData, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { [unowned self] message in

                        dispatch_async(dispatch_get_main_queue()) {
                            if let realm = message.realm {
                                realm.beginWrite()
                                message.localAttachmentName = fileURL.path!.lastPathComponent.stringByDeletingPathExtension
                                message.mediaType = MessageMediaType.Audio.rawValue
                                if let metaData = metaData {
                                    message.metaData = metaData
                                }
                                realm.commitWrite()

                                self.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { _ in
                                })
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

        messageToolbar.stateTransitionAction = { [unowned self] (messageToolbar, previousState, currentState) in

            switch (previousState, currentState) {

            case (.MoreMessages, .Default):
                if !self.isKeyboardVisible {
                    self.adjustBackCollectionViewWithHeight(0, animationDuration: 0.3, animationCurveValue: 7)

                } else {
                    self.hideKeyboardAndShowMoreMessageView()
                }

            default:
                if currentState == .MoreMessages {
                    self.hideKeyboardAndShowMoreMessageView()
                }
            }


            // 尝试保留草稿

            let realm = Realm()

            if let draft = self.conversation.draft {
                realm.write {
                    draft.messageToolbarState = currentState.rawValue
                    draft.text = messageToolbar.messageTextView.text
                }

            } else {
                let draft = Draft()
                draft.messageToolbarState = currentState.rawValue

                realm.write {
                    self.conversation.draft = draft
                }
            }

        }
    

        // MARK: More Message Types

        choosePhotoButton.title = NSLocalizedString("Choose photo", comment: "")
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

        takePhotoButton.title = NSLocalizedString("Take photo", comment: "")
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

        addLocationButton.title = NSLocalizedString("Share location", comment: "")
        addLocationButton.tapAction = {
            self.performSegueWithIdentifier("presentPickLocation", sender: nil)
        }
    }
    
    func tryRecoverMessageToolBar() {
        if let
            draft = conversation.draft,
            state = MessageToolbarState(rawValue: draft.messageToolbarState) {
                
                if state == .TextInputing || state == .Default {
                    messageToolbar.messageTextView.text = draft.text
                }
        
                // 这句要放在最后，因为它会触发 stateTransitionAction
                if state != .MoreMessages {
                    messageToolbar.state = state
                }
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

                if FayeService.sharedManager.client.connected {
                    FayeService.sharedManager.sendPrivateMessage(typingMessage, messageType: .Instant, userID: withFriend.userID, completion: { (result, messageID) in
                        println("Send typing \(result)")
                    })
                }
            }
        }
        
        // 防止未在此界面时被标记
            
        var messages = conversation.messages.filter({ message in
            if let fromFriend = message.fromFriend {
                return (message.readed == false) && (fromFriend.friendState != UserFriendState.Me.rawValue)
            } else {
                return false
            }
        })

        for message in messages {
            markMessageAsReaded(message)
        }
    }
    
    func markMessageAsReaded(message: Message) {
        
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

            // 尝试恢复 messageToolbar 的状态
            tryRecoverMessageToolBar()

            // 尽量滚到底部
            tryScrollToBottom()
        }
        
        self.waverView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - self.messageToolbar.frame.size.height)
    }
    
    func tryScrollToBottom() {
        
        if displayedMessagesRange.length > 0 {
            
            let messageToolBarTop = messageToolbarBottomConstraint.constant + CGRectGetHeight(messageToolbar.bounds)
            let invisibleHeight = messageToolBarTop + 64.0
            let visibleHeight = conversationCollectionView.frame.height - invisibleHeight

            let canScroll = visibleHeight <= conversationCollectionView.contentSize.height

            if canScroll {
                conversationCollectionView.contentOffset.y = conversationCollectionView.contentSize.height - conversationCollectionView.frame.size.height + messageToolBarTop

                conversationCollectionView.contentInset.bottom = messageToolBarTop

                conversationCollectionViewContentOffsetBeforeKeyboardWillShow = conversationCollectionView.contentOffset
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
                textContentLabelWidths[key] = ceil(rect.width) + 1 // + 1 for TTTAttributedLabel
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

        let width = ceil(rect.width) + 1 // + 1 for TTTAttributedLabel

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
    
    func handleReceivedNewMessagesNotification(notification: NSNotification) {

        var messageIDs: [String]?

        if let messagesInfo = notification.object as? [String: [String]], let _messageIDs = messagesInfo["messageIDs"] {
            messageIDs = _messageIDs
        }

        updateConversationCollectionViewWithMessageIDs(messageIDs, scrollToBottom: false, success: { _ in
        })
    }

    func updateConversationCollectionViewWithMessageIDs(messageIDs: [String]?, scrollToBottom: Bool, success: (Bool) -> Void) {

        if navigationController?.topViewController == self { // 防止 pop/push 后，原来未释放的 VC 也执行这下面的代码

            let keyboardAndToolBarHeight = messageToolbarBottomConstraint.constant + CGRectGetHeight(messageToolbar.bounds)

            adjustConversationCollectionViewWithMessageIDs(messageIDs, adjustHeight: keyboardAndToolBarHeight, scrollToBottom: scrollToBottom) { finished in
                success(finished)
            }
        }
    }

    func adjustConversationCollectionViewWithMessageIDs(messageIDs: [String]?, adjustHeight: CGFloat, scrollToBottom: Bool, success: (Bool) -> Void) {
        let _lastTimeMessagesCount = lastTimeMessagesCount
        lastTimeMessagesCount = messages.count

        // 保证是增加消息
        if messages.count <= _lastTimeMessagesCount {
            return
        }

        let newMessagesCount = Int(messages.count - _lastTimeMessagesCount)
        
        let lastDisplayedMessagesRange = displayedMessagesRange
        
        displayedMessagesRange.length += newMessagesCount

        if newMessagesCount > 0 {

            /*
            //var indexPaths = [NSIndexPath]()
            // TODO: 下面插入逻辑的假设有问题，对方的新消息并不会一直排在最后一个
            for i in 0..<newMessagesCount {
                let indexPath = NSIndexPath(forItem: lastDisplayedMessagesRange.length + i, inSection: 0)
                indexPaths.append(indexPath)
            }

            conversationCollectionView.insertItemsAtIndexPaths(indexPaths)

            // 先治标
            if _lastTimeMessagesCount > 0 {
                let oldLastMessageIndexPath = NSIndexPath(forItem: lastDisplayedMessagesRange.length - 1, inSection: 0)
                conversationCollectionView.reloadItemsAtIndexPaths([oldLastMessageIndexPath])
            }
            */

            // 我们来治本

            if let messageIDs = messageIDs {

                var indexPaths = [NSIndexPath]()

                for messageID in messageIDs {
                    if let
                        message = messageWithMessageID(messageID, inRealm: realm),
                        index = messages.indexOf(message),
                        indexPath = NSIndexPath(forItem: index - displayedMessagesRange.location, inSection: 0) {
                            println("insert item: \(indexPath.item)")

                            indexPaths.append(indexPath)

                    } else {
                        println("unknown message")
                    }
                }

                conversationCollectionView.insertItemsAtIndexPaths(indexPaths)

            } else {
                println("self message")

                var indexPaths = [NSIndexPath]()

                for i in 0..<newMessagesCount {
                    let indexPath = NSIndexPath(forItem: lastDisplayedMessagesRange.length + i, inSection: 0)
                    indexPaths.append(indexPath)
                }

                conversationCollectionView.insertItemsAtIndexPaths(indexPaths)
            }
        }

        if newMessagesCount > 0 {
            
            var newMessagesTotalHeight: CGFloat = 0
            
            for i in _lastTimeMessagesCount..<messages.count {
                let message = messages[i]
                
                let height = heightOfMessage(message) + 5// TODO: +10 cell line space
//                println("uuheight \(height)")
                newMessagesTotalHeight += height
            }
            
            let keyboardAndToolBarHeight = adjustHeight
            
            let navicationBarAndKeyboardAndToolBarHeight = keyboardAndToolBarHeight + 64.0
            
            let totleMessagesHeight = conversationCollectionView.contentSize.height + navicationBarAndKeyboardAndToolBarHeight + newMessagesTotalHeight
            
            let visableMessageFieldHeight = conversationCollectionView.frame.size.height - navicationBarAndKeyboardAndToolBarHeight
            
            let totalMessagesContentHeight = conversationCollectionView.contentSize.height + keyboardAndToolBarHeight + newMessagesTotalHeight
            
//            println("Size is \(conversationCollectionView.contentSize.height) \(newMessagesTotalHeight) visableMessageFieldHeight \(visableMessageFieldHeight)")
            
            //Calculate the space can be used
            let useableSpace = visableMessageFieldHeight - conversationCollectionView.contentSize.height
            
            conversationCollectionView.contentSize = CGSizeMake(conversationCollectionView.contentSize.width, self.conversationCollectionView.contentSize.height + newMessagesTotalHeight)
            
//            println("Size is after \(conversationCollectionView.contentSize.height)")
            
            if (totleMessagesHeight > conversationCollectionView.frame.size.height) {
//                println("New Message scroll")
                
                UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { [unowned self] in
                    
                    if (useableSpace > 0) {
                        let contentToScroll = newMessagesTotalHeight - useableSpace
//                        println("contentToScroll \(contentToScroll)")
                        self.conversationCollectionView.contentOffset.y += contentToScroll
                    } else {
                        
                        var newContentSize = self.conversationCollectionView.collectionViewLayout.collectionViewContentSize()
                        self.conversationCollectionView.contentSize = newContentSize
                        
                        if scrollToBottom {
                            
                            var newContentOffsetY = newContentSize.height - self.conversationCollectionView.frame.size.height + keyboardAndToolBarHeight
                            
                            var oldContentOffsetY = self.conversationCollectionView.contentOffset.y
                            
//                            println("New contenct offset \(self.conversationCollectionView.contentSize.height - newContentSize.height) \(newContentOffsetY) \(oldContentOffsetY) \(newContentOffsetY - oldContentOffsetY)")
                            
                            self.conversationCollectionView.contentOffset.y = newContentOffsetY
                            
//                            println("Content Size is \(self.conversationCollectionView.contentSize.height) \(self.conversationCollectionView.contentOffset.y)")
                            
                            
                        }else {
                            
//                            println("Content Size is \(self.conversationCollectionView.contentSize.height) \(self.conversationCollectionView.contentOffset.y)")
                            
                            self.conversationCollectionView.contentOffset.y += newMessagesTotalHeight
                        }
                        
                    }
                    
                }, completion: { finished in
                        success(true)
                })
            } else {
                success(true)
            }
        } else {
            success(true)
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

    func playMessageAudioWithMessage(message: Message?) {

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

                    if let message = message {
                        if message.messageID == playingMessage.messageID {
                            return
                        }
                    }
                }
            }
        }

        if let message = message {
            let audioPlayedDuration = audioPlayedDurationOfMessage(message) as NSTimeInterval
            YepAudioService.sharedManager.playAudioWithMessage(message, beginFromTime: audioPlayedDuration, delegate: self) {
                let playbackTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: self, selector: "updateAudioPlaybackProgress:", userInfo: nil, repeats: true)
                YepAudioService.sharedManager.playbackTimer = playbackTimer
            }
        }
    }

    func cleanForLogout() {
        displayedMessagesRange.length = 0
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
        
        UIView.animateWithDuration(animationDuration, delay: 0, options: UIViewAnimationOptions(animationCurveValue << 16), animations: { [unowned self] in
            
            self.messageToolbarBottomConstraint.constant = newHeight
            
            let invisibleHeight = newHeight + CGRectGetHeight(self.messageToolbar.bounds) + 64
            
            //let totleMessagesHeight = self.conversationCollectionView.contentSize.height + keyboardAndToolBarHeight + 64.0
            
            let visibleHeight = self.conversationCollectionView.frame.size.height - invisibleHeight
            
            //                println("Content size is \(self.conversationCollectionView.contentSize.height) visableMessageFieldHeight \(visableMessageFieldHeight) totleMessagesHeight \(totleMessagesHeight) toolbar \(CGRectGetHeight(self.messageToolbar.bounds) ) keyboardHeight \(keyboardHeight) Navitation 64.0")
            
            let invisibleContentSizeHeight = self.conversationCollectionView.contentSize.height - visibleHeight
            println("invisibleContentSizeHeight is \(invisibleContentSizeHeight)")
            
            //Only scroll the invisable field if invisable < keyboardAndToolBarHeight
            if (invisibleContentSizeHeight < invisibleHeight) {
                
                //Only scroll if need
                if (invisibleContentSizeHeight > 0) {
                    let contentOffset = CGPointMake(self.conversationCollectionViewContentOffsetBeforeKeyboardWillShow.x, self.conversationCollectionViewContentOffsetBeforeKeyboardWillShow.y + invisibleContentSizeHeight)
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
            
        }, completion: { [unowned self] finished in
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

        UIView.animateWithDuration(animationDuration, delay: 0, options: UIViewAnimationOptions(animationCurveValue << 16), animations: { [unowned self] in
            
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

        }, completion: { _ in
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
                if withFriend.userID != YepUserDefaults.userID.value {
                    vc.profileUser = ProfileUser.UserType(withFriend)
                }
                vc.isFromConversation = true
                
                vc.setBackButtonWithTitle()
            }

        } else if segue.identifier == "showMessageMedia" {

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

                    let delegate = ConversationMessagePreviewNavigationControllerDelegate()
                    delegate.frame = frame
                    delegate.transitionView = transitionView

                    navigationControllerDelegate = delegate

                    navigationController?.delegate = delegate
                }
            }

        } else if segue.identifier == "presentMessageMedia" {

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

            vc.sendLocationAction = { [unowned self] coordinate in

                if let withFriend = self.conversation.withFriend {

                    sendLocationWithCoordinate(coordinate, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { message in

                        dispatch_async(dispatch_get_main_queue()) {
                            self.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { _ in
                            })
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
                            self.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { _ in
                            })
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

// MARK: UIGestureRecognizerDelegate

extension ConversationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let isAnimated = navigationController?.transitionCoordinator()?.isAnimated() {
            return !isAnimated
        }

        if navigationController?.viewControllers.count < 2 {
            return false
        }

        if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
            return true
        }

        return false
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

        println("conversation \(message.textContent) messageID: \(message.messageID)")

        if message.mediaType == MessageMediaType.SectionDate.rawValue {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatSectionDateCellIdentifier, forIndexPath: indexPath) as! ChatSectionDateCell

            let createdAt = NSDate(timeIntervalSince1970: message.createdUnixTime)

            if createdAt.isInCurrentWeek() {
                cell.sectionDateLabel.text = sectionDateInCurrentWeekFormatter.stringFromDate(createdAt)
            } else {
                cell.sectionDateLabel.text = sectionDateFormatter.stringFromDate(createdAt)
            }

            return cell
        }
        

        if let sender = message.fromFriend {

            if sender.friendState != UserFriendState.Me.rawValue { // from Friend

                downloadAttachmentOfMessage(message)
                
                markMessageAsReaded(message)

                switch message.mediaType {
                case MessageMediaType.Image.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftImageCellIdentifier, forIndexPath: indexPath) as! ChatLeftImageCell

                    cell.configureWithMessage(message, messageImagePreferredWidth: messageImagePreferredWidth, messageImagePreferredHeight: messageImagePreferredHeight, messageImagePreferredAspectRatio: messageImagePreferredAspectRatio, mediaTapAction: { [unowned self] in

                        self.performSegueWithIdentifier("showMessageMedia", sender: message)

                    }, collectionView: collectionView, indexPath: indexPath)
                    
                    return cell

                case MessageMediaType.Audio.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftAudioCellIdentifier, forIndexPath: indexPath) as! ChatLeftAudioCell

                    let audioPlayedDuration = audioPlayedDurationOfMessage(message)

                    cell.configureWithMessage(message, audioPlayedDuration: audioPlayedDuration, audioBubbleTapAction: { [unowned self] message in

                        self.playMessageAudioWithMessage(message)

                    }, collectionView: collectionView, indexPath: indexPath)
                                        
                    return cell

                case MessageMediaType.Video.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftVideoCellIdentifier, forIndexPath: indexPath) as! ChatLeftVideoCell

                    cell.configureWithMessage(message, messageImagePreferredWidth: messageImagePreferredWidth, messageImagePreferredHeight: messageImagePreferredHeight, messageImagePreferredAspectRatio: messageImagePreferredAspectRatio, mediaTapAction: { [unowned self] in

                        self.performSegueWithIdentifier("showMessageMedia", sender: message)

                    }, collectionView: collectionView, indexPath: indexPath)

                    return cell

                case MessageMediaType.Location.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftLocationCellIdentifier, forIndexPath: indexPath) as! ChatLeftLocationCell

                    cell.configureWithMessage(message, mediaTapAction: { [unowned self] in
                        if let coordinate = message.coordinate {
                            let locationCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
                            /*
                            let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                            mapItem.openInMapsWithLaunchOptions(launchOptions)
                            */
                            mapItem.openInMapsWithLaunchOptions(nil)
                        }

                    }, collectionView: collectionView, indexPath: indexPath)

                    return cell

                default:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftTextCellIdentifier, forIndexPath: indexPath) as! ChatLeftTextCell

                    cell.configureWithMessage(message, textContentLabelWidth: textContentLabelWidthOfMessage(message), collectionView: collectionView, indexPath: indexPath)

                    return cell
                }

            } else { // from Me

                switch message.mediaType {
                case MessageMediaType.Image.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightImageCellIdentifier, forIndexPath: indexPath) as! ChatRightImageCell

                    cell.configureWithMessage(message, messageImagePreferredWidth: messageImagePreferredWidth, messageImagePreferredHeight: messageImagePreferredHeight, messageImagePreferredAspectRatio: messageImagePreferredAspectRatio, mediaTapAction: { [unowned self] in

                        if message.sendState == MessageSendState.Failed.rawValue {

                            YepAlert.confirmOrCancel(title: NSLocalizedString("Action", comment: ""), message: NSLocalizedString("Resend image?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: {

                                resendMessage(message, failureHandler: { (reason, errorMessage) in
                                    defaultFailureHandler(reason, errorMessage)
                                    // TODO: resendImage 错误提醒

                                }, completion: { success in
                                    println("resendImage: \(success)")
                                })

                            }, cancelAction: {
                            })

                        } else {
                            self.performSegueWithIdentifier("showMessageMedia", sender: message)
                        }

                    }, collectionView: collectionView, indexPath: indexPath)
                    
                    return cell

                case MessageMediaType.Audio.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightAudioCellIdentifier, forIndexPath: indexPath) as! ChatRightAudioCell

                    let audioPlayedDuration = audioPlayedDurationOfMessage(message)

                    cell.configureWithMessage(message, audioPlayedDuration: audioPlayedDuration, audioBubbleTapAction: { [unowned self] message in

                        if let message = message {
                            if message.sendState == MessageSendState.Failed.rawValue {

                                YepAlert.confirmOrCancel(title: NSLocalizedString("Action", comment: ""), message: NSLocalizedString("Resend audio?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: {

                                    resendMessage(message, failureHandler: { (reason, errorMessage) in
                                        defaultFailureHandler(reason, errorMessage)
                                        // TODO: resendAudio 错误提醒

                                    }, completion: { success in
                                        println("resendAudio: \(success)")
                                    })

                                }, cancelAction: {
                                })

                                return
                            }
                        }

                        self.playMessageAudioWithMessage(message)

                    }, collectionView: collectionView, indexPath: indexPath)

                    return cell

                case MessageMediaType.Video.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightVideoCellIdentifier, forIndexPath: indexPath) as! ChatRightVideoCell

                    cell.configureWithMessage(message, messageImagePreferredWidth: messageImagePreferredWidth, messageImagePreferredHeight: messageImagePreferredHeight, messageImagePreferredAspectRatio: messageImagePreferredAspectRatio, mediaTapAction: { [unowned self] in

                        if message.sendState == MessageSendState.Failed.rawValue {

                            YepAlert.confirmOrCancel(title: NSLocalizedString("Action", comment: ""), message: NSLocalizedString("Resend video?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: {

                                resendMessage(message, failureHandler: { (reason, errorMessage) in
                                    defaultFailureHandler(reason, errorMessage)
                                    // TODO: resendVideo 错误提醒

                                }, completion: { success in
                                    println("resendVideo: \(success)")
                                })

                            }, cancelAction: {
                            })

                        } else {
                            self.performSegueWithIdentifier("showMessageMedia", sender: message)
                        }

                    }, collectionView: collectionView, indexPath: indexPath)

                    return cell

                case MessageMediaType.Location.rawValue:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightLocationCellIdentifier, forIndexPath: indexPath) as! ChatRightLocationCell

                    cell.configureWithMessage(message, mediaTapAction: { [unowned self] in

                        if message.sendState == MessageSendState.Failed.rawValue {

                            YepAlert.confirmOrCancel(title: NSLocalizedString("Action", comment: ""), message: NSLocalizedString("Resend location?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: {

                                resendMessage(message, failureHandler: { (reason, errorMessage) in
                                    defaultFailureHandler(reason, errorMessage)
                                    // TODO: resendLocation 错误提醒

                                }, completion: { success in
                                    println("resendLocation: \(success)")
                                })

                            }, cancelAction: {
                            })

                        } else {
                            if let coordinate = message.coordinate {
                                let locationCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
                                /*
                                let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                                mapItem.openInMapsWithLaunchOptions(launchOptions)
                                */
                                mapItem.openInMapsWithLaunchOptions(nil)
                            }
                        }

                    }, collectionView: collectionView, indexPath: indexPath)

                    return cell

                default:
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightTextCellIdentifier, forIndexPath: indexPath) as! ChatRightTextCell

                    cell.configureWithMessage(message, textContentLabelWidth: textContentLabelWidthOfMessage(message), mediaTapAction: { [unowned self] in

                        if message.sendState == MessageSendState.Failed.rawValue {

                            YepAlert.confirmOrCancel(title: NSLocalizedString("Action", comment: ""), message: NSLocalizedString("Resend text?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: {

                                resendMessage(message, failureHandler: { (reason, errorMessage) in
                                    defaultFailureHandler(reason, errorMessage)
                                    // TODO: resendText 错误提醒

                                }, completion: { success in
                                    println("resendText: \(success)")
                                })

                            }, cancelAction: {
                            })
                        }
                    }, collectionView: collectionView, indexPath: indexPath)

                    return cell
                }
            }

        } else {
            println("🐌 Conversation: Should not be there")

            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatSectionDateCellIdentifier, forIndexPath: indexPath) as! ChatSectionDateCell

            cell.sectionDateLabel.text = "🐌"

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
        
        switch messageToolbar.state {

        case .BeginTextInput, .TextInputing, .MoreMessages:
            messageToolbar.state = .Default

        default:
            break
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
            pulllToRefreshView.endRefreshingAndDoFurtherAction() { [unowned self] in

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

            sendImageInFilePath(nil, orFileData: imageData, metaData: metaData, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { [unowned self] message in

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

                    self.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { _ in
                    })
                }

            }, failureHandler: {(reason, errorMessage) -> () in
                defaultFailureHandler(reason, errorMessage)
                // TODO: sendImage 错误提醒

            }, completion: { success -> Void in
                println("sendImage to friend: \(success)")
            })

        } else if let withGroup = conversation.withGroup {
            sendImageInFilePath(nil, orFileData: imageData, metaData: nil, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { [unowned self] message in

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
                    
                    self.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { _ in
                    })
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

        let afterCreatedMessageAction = { [unowned self] (message: Message) in
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

                    self.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { _ in
                    })
                }
            }
        }

        if let withFriend = conversation.withFriend {
            sendVideoInFilePath(videoURL.path!, orFileData: nil, metaData: metaData, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: afterCreatedMessageAction, failureHandler: { (reason, errorMessage) in
                defaultFailureHandler(reason, errorMessage)
                // TODO: sendVideo 错误提醒

            }, completion: { success in
                println("sendVideo to friend: \(success)")
            })

        } else if let withGroup = conversation.withGroup {
            sendVideoInFilePath(videoURL.path!, orFileData: nil, metaData: nil, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: afterCreatedMessageAction, failureHandler: { (reason, errorMessage) in
                defaultFailureHandler(reason, errorMessage)
                // TODO: sendVideo 错误提醒
                
            }, completion: { success in
                println("sendVideo to group: \(success)")
            })
        }
    }
}






