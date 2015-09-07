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
import Proposer
import KeyboardMan

struct MessageNotification {
    static let MessageStateChanged = "MessageStateChangedNotification"
}

class ConversationViewController: BaseViewController {

    var conversation: Conversation!

    var realm: Realm!

    lazy var messages: Results<Message> = {
        return messagesOfConversation(self.conversation, inRealm: self.realm)
        }()

    let messagesBunchCount = 50 // TODO: 分段载入的“一束”消息的数量
    var displayedMessagesRange = NSRange()
    
    // 上一次更新 UI 时的消息数
    var lastTimeMessagesCount: Int = 0

    // 位于后台时收到的消息
    var inActiveNewMessageIDSet = Set<String>()

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

    var checkTypingStatusTimer: NSTimer?
    var typingResetDelay: Float = 0

    // KeyboardMan 帮助我们做键盘动画
    let keyboardMan = KeyboardMan()

    var isFirstAppear = true

    lazy var titleView: ConversationTitleView = {
        let titleView = ConversationTitleView(frame: CGRect(origin: CGPointZero, size: CGSize(width: 150, height: 44)))
        titleView.nameLabel.text = nameOfConversation(self.conversation)
        self.updateStateInfoOfTitleView(titleView)
        return titleView
        }()

    lazy var moreView = ConversationMoreView()

    lazy var pullToRefreshView: PullToRefreshView = {

        let pullToRefreshView = PullToRefreshView()
        pullToRefreshView.delegate = self

        self.conversationCollectionView.insertSubview(pullToRefreshView, atIndex: 0)

        pullToRefreshView.setTranslatesAutoresizingMaskIntoConstraints(false)

        let viewsDictionary = [
            "pullToRefreshView": pullToRefreshView,
            "view": self.view,
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(-200)-[pullToRefreshView(200)]", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        // 非常奇怪，若直接用 "H:|[pullToRefreshView]|" 得到的实际宽度为 0
        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[pullToRefreshView(==view)]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints(constraintsH)

        return pullToRefreshView
        }()

    lazy var waverView: YepWaverView = {
        let view = YepWaverView(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - self.messageToolbar.frame.size.height))

        view.waver.waverCallback = { waver in

            if let audioRecorder = YepAudioService.sharedManager.audioRecorder {

                if (audioRecorder.recording) {
                    //println("Update waver")
                    audioRecorder.updateMeters()

                    let normalizedValue = pow(10, audioRecorder.averagePowerForChannel(0)/40)

                    waver.level = CGFloat(normalizedValue)
                }
            }
        }

        return view
        }()
    var samplesCount = 0
    let samplingInterval = 6
    
    @IBOutlet weak var conversationCollectionView: UICollectionView!

    @IBOutlet weak var messageToolbar: MessageToolbar!
    @IBOutlet weak var messageToolbarBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var moreMessageTypesViewHeightConstraint: NSLayoutConstraint!
    let moreMessageTypesViewDefaultHeight: CGFloat = 110

    @IBOutlet weak var choosePhotoButton: MessageTypeButton!
    @IBOutlet weak var takePhotoButton: MessageTypeButton!
    @IBOutlet weak var addLocationButton: MessageTypeButton!

    @IBOutlet weak var swipeUpView: UIView!
    @IBOutlet weak var swipeUpPromptLabel: UILabel!
    
    var isTryingShowFriendRequestView = false

    var originalNavigationControllerDelegate: UINavigationControllerDelegate?

    let sectionInsetTop: CGFloat = 10
    let sectionInsetBottom: CGFloat = 10

    lazy var messageTextLabelMaxWidth: CGFloat = {
        let maxWidth = self.collectionViewWidth - (YepConfig.chatCellGapBetweenWallAndAvatar() + YepConfig.chatCellAvatarSize() + YepConfig.chatCellGapBetweenTextContentLabelAndAvatar() + YepConfig.chatTextGapBetweenWallAndContentLabel())
        return maxWidth
        }()

    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.conversationCollectionView.bounds)
        }()

    lazy var messageImagePreferredWidth: CGFloat = {
        return YepConfig.ChatCell.mediaPreferredWidth
        }()
    lazy var messageImagePreferredHeight: CGFloat = {
        return YepConfig.ChatCell.mediaPreferredHeight
        }()

    let messageImagePreferredAspectRatio: CGFloat = 4.0 / 3.0
    
    lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.mediaTypes = [kUTTypeImage, kUTTypeMovie]
        imagePicker.videoQuality = .TypeMedium
        imagePicker.allowsEditing = false
        return imagePicker
        }()

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
    
    struct Listener {
        static let Avatar = "ConversationViewController"
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)

        YepUserDefaults.avatarURLString.removeListenerWithName(Listener.Avatar)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // 尝试恢复原始的 NavigationControllerDelegate，如果自定义 push 了才需要
        if let delegate = originalNavigationControllerDelegate {
            navigationController?.delegate = delegate
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        realm = Realm()

        // 优先处理侧滑，而不是 scrollView 的上下滚动，避免出现你想侧滑返回的时候，结果触发了 scrollView 的上下滚动
        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKindOfClass(UIScreenEdgePanGestureRecognizer) {
                    conversationCollectionView.panGestureRecognizer.requireGestureRecognizerToFail(recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }

        navigationController?.interactivePopGestureRecognizer.delaysTouchesBegan = false
        
        let layout = ConversationLayout()
        layout.minimumLineSpacing = YepConfig.ChatCell.lineSpacing
        conversationCollectionView.setCollectionViewLayout(layout, animated: false)

        if messages.count >= messagesBunchCount {
            displayedMessagesRange = NSRange(location: Int(messages.count) - messagesBunchCount, length: messagesBunchCount)
        } else {
            displayedMessagesRange = NSRange(location: 0, length: Int(messages.count))
        }

        lastTimeMessagesCount = messages.count

        navigationItem.titleView = titleView

        if let withFriend = conversation?.withFriend {
            let moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_more"), style: UIBarButtonItemStyle.Plain, target: self, action: "moreAction")
            navigationItem.rightBarButtonItem = moreBarButtonItem
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleReceivedNewMessagesNotification:", name: YepNewMessagesReceivedNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "cleanForLogout", name: EditProfileViewController.Notification.Logout, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "tryInsertInActiveNewMessages:", name: AppDelegate.Notification.applicationDidBecomeActive, object: nil)

        YepUserDefaults.avatarURLString.bindListener(Listener.Avatar) { [weak self] _ in
            self?.reloadConversationCollectionView()
        }

        swipeUpView.hidden = true

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
        moreMessageTypesViewHeightConstraint.constant = moreMessageTypesViewDefaultHeight

        keyboardMan.animateWhenKeyboardAppear = { [weak self] appearPostIndex, keyboardHeight, keyboardHeightIncrement in

            print("appear \(keyboardHeight), \(keyboardHeightIncrement)\n")

            if let strongSelf = self {

                if strongSelf.messageToolbarBottomConstraint.constant > 0 {

                    // 注意第一次要减去已经有的高度偏移
                    if appearPostIndex == 0 {
                        strongSelf.conversationCollectionView.contentOffset.y += keyboardHeightIncrement - strongSelf.moreMessageTypesViewDefaultHeight
                    } else {
                        strongSelf.conversationCollectionView.contentOffset.y += keyboardHeightIncrement
                    }

                    strongSelf.conversationCollectionView.contentInset.bottom = keyboardHeight + strongSelf.messageToolbar.frame.height

                    strongSelf.messageToolbarBottomConstraint.constant = keyboardHeight
                    strongSelf.view.layoutIfNeeded()

                } else {
                    strongSelf.conversationCollectionView.contentOffset.y += keyboardHeightIncrement
                    strongSelf.conversationCollectionView.contentInset.bottom = keyboardHeight + strongSelf.messageToolbar.frame.height

                    strongSelf.messageToolbarBottomConstraint.constant = keyboardHeight
                    strongSelf.view.layoutIfNeeded()
                }
            }
        }

        keyboardMan.animateWhenKeyboardDisappear = { [weak self] keyboardHeight in

            print("disappear \(keyboardHeight)\n")

            if let strongSelf = self {

                if strongSelf.messageToolbar.state == .MoreMessages {
                    strongSelf.conversationCollectionView.contentOffset.y -= keyboardHeight - strongSelf.moreMessageTypesViewDefaultHeight
                    strongSelf.conversationCollectionView.contentInset.bottom = strongSelf.messageToolbar.frame.height + strongSelf.moreMessageTypesViewDefaultHeight

                    strongSelf.messageToolbarBottomConstraint.constant = strongSelf.moreMessageTypesViewDefaultHeight
                    strongSelf.view.layoutIfNeeded()

                } else {
                    strongSelf.conversationCollectionView.contentOffset.y -= keyboardHeight
                    strongSelf.conversationCollectionView.contentInset.bottom = strongSelf.messageToolbar.frame.height

                    strongSelf.messageToolbarBottomConstraint.constant = 0
                    strongSelf.view.layoutIfNeeded()
                }
            }
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

        navigationController?.setNavigationBarHidden(false, animated: true)
        setNeedsStatusBarAppearanceUpdate()

        conversationCollectionViewHasBeenMovedToBottomOnce = true

        FayeService.sharedManager.delegate = self

        // 进来时就尽快标记已读

        conversation.messages.filter({ message in
            if let fromFriend = message.fromFriend {
                return (message.readed == false) && (fromFriend.friendState != UserFriendState.Me.rawValue)
            } else {
                return false
            }
        }).map({ self.markMessageAsReaded($0) })

        // 尽量晚的设置一些属性和闭包

        if isFirstAppear {

            isFirstAppear = false

            // MARK: Notify Typing

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

            // MARK: Send Text

            messageToolbar.textSendAction = { [weak self] messageToolbar in

                let text = messageToolbar.messageTextView.text!.trimming(.WhitespaceAndNewline)

                self?.cleanTextInput()

                if text.isEmpty {
                    return
                }

                if let withFriend = self?.conversation.withFriend {

                    sendText(text, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { [weak self] message in

                        dispatch_async(dispatch_get_main_queue()) {
                            self?.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { success in
                            })
                        }

                    }, failureHandler: { [weak self] reason, errorMessage in
                        defaultFailureHandler(reason, errorMessage)

                        YepAlert.alertSorry(message: NSLocalizedString("Failed to send text!\nTry tap on message to resend.", comment: ""), inViewController: self)

                    }, completion: { success in
                        println("sendText to friend: \(success)")

                        // 发送过消息后才提示加好友
                        dispatch_async(dispatch_get_main_queue()) { [weak self] in
                            if let strongSelf = self {
                                if !strongSelf.isTryingShowFriendRequestView {
                                    strongSelf.isTryingShowFriendRequestView = true
                                    strongSelf.tryShowFriendRequestView()
                                }
                            }
                        }
                    })

                } else if let withGroup = self?.conversation.withGroup {

                    sendText(text, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { [weak self] message in

                        dispatch_async(dispatch_get_main_queue()) {
                            self?.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { _ in
                            })
                        }

                    }, failureHandler: { [weak self] reason, errorMessage in
                        defaultFailureHandler(reason, errorMessage)

                        dispatch_async(dispatch_get_main_queue()) {
                            YepAlert.alertSorry(message: NSLocalizedString("Failed to send text!\nTry tap on message to resend.", comment: ""), inViewController: self)
                        }

                    }, completion: { success in
                        println("sendText to group: \(success)")
                    })
                }
            }

            // MARK: Send Audio

            let hideWaver: () -> Void = { [weak self] in
                self?.swipeUpView.hidden = true
                self?.waverView.removeFromSuperview()
            }

            let sendAudioMessage: () -> Void = { [weak self] in
                // Prepare meta data

                var metaData: String? = nil

                if let audioSamples = self?.waverView.waver.compressSamples() {

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

                        let audioMetaDataInfo = [YepConfig.MetaData.audioSamples: audioSamples, YepConfig.MetaData.audioDuration: audioDuration]

                        if let audioMetaData = NSJSONSerialization.dataWithJSONObject(audioMetaDataInfo, options: nil, error: nil) {
                            let audioMetaDataString = NSString(data: audioMetaData, encoding: NSUTF8StringEncoding) as? String
                            metaData = audioMetaDataString
                        }
                    }
                }

                // Do send

                if let fileURL = YepAudioService.sharedManager.audioFileURL {
                    if let withFriend = self?.conversation.withFriend {
                        sendAudioInFilePath(fileURL.path!, orFileData: nil, metaData: metaData, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { [weak self] message in

                            dispatch_async(dispatch_get_main_queue()) {
                                if let realm = message.realm {
                                    realm.beginWrite()
                                    message.localAttachmentName = fileURL.path!.lastPathComponent.stringByDeletingPathExtension
                                    message.mediaType = MessageMediaType.Audio.rawValue
                                    if let metaDataString = metaData {
                                        message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                                    }
                                    realm.commitWrite()

                                    self?.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { _ in
                                    })
                                }
                            }

                        }, failureHandler: { [weak self] reason, errorMessage in
                            defaultFailureHandler(reason, errorMessage)

                            YepAlert.alertSorry(message: NSLocalizedString("Failed to send audio!\nTry tap on message to resend.", comment: ""), inViewController: self)

                        }, completion: { success in
                            println("send audio to friend: \(success)")
                        })

                    } else if let withGroup = self?.conversation.withGroup {
                        sendAudioInFilePath(fileURL.path!, orFileData: nil, metaData: metaData, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { [weak self] message in

                            dispatch_async(dispatch_get_main_queue()) {
                                if let realm = message.realm {
                                    realm.beginWrite()
                                    message.localAttachmentName = fileURL.path!.lastPathComponent.stringByDeletingPathExtension
                                    message.mediaType = MessageMediaType.Audio.rawValue
                                    if let metaDataString = metaData {
                                        message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                                    }
                                    realm.commitWrite()

                                    self?.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { _ in
                                    })
                                }
                            }

                        }, failureHandler: { [weak self] reason, errorMessage in
                            defaultFailureHandler(reason, errorMessage)

                            YepAlert.alertSorry(message: NSLocalizedString("Failed to send audio!\nTry tap on message to resend.", comment: ""), inViewController: self)

                        }, completion: { success in
                            println("send audio to group: \(success)")
                        })
                    }
                }
            }

            // MARK: Voice Record

            messageToolbar.voiceRecordBeginAction = { [weak self] messageToolbar in

                YepAudioService.sharedManager.shouldIgnoreStart = false
                
                if let strongSelf = self {

                    strongSelf.view.addSubview(strongSelf.waverView)

                    strongSelf.swipeUpPromptLabel.text = NSLocalizedString("Swipe Up to Cancel", comment: "")
                    strongSelf.swipeUpView.hidden = false
                    strongSelf.view.bringSubviewToFront(strongSelf.swipeUpView)

                    let audioFileName = NSUUID().UUIDString

                    strongSelf.waverView.waver.resetWaveSamples()
                    strongSelf.samplesCount = 0

                    if let fileURL = NSFileManager.yepMessageAudioURLWithName(audioFileName) {
                        
                        YepAudioService.sharedManager.beginRecordWithFileURL(fileURL, audioRecorderDelegate: strongSelf)

                        YepAudioService.sharedManager.recordTimeoutAction = {

                            hideWaver()

                            sendAudioMessage()
                        }

                        YepAudioService.sharedManager.startCheckRecordTimeoutTimer()
                    }

                    if let withFriend = strongSelf.conversation.withFriend {

                        let typingMessage: JSONDictionary = ["state": FayeService.InstantStateType.Audio.rawValue]

                        if FayeService.sharedManager.client.connected {
                            FayeService.sharedManager.sendPrivateMessage(typingMessage, messageType: .Instant, userID: withFriend.userID, completion: { (result, messageID) in
                                println("Send recording \(result)")
                            })
                        }
                    }
                }
            }
            
            messageToolbar.voiceRecordEndAction = { [weak self] messageToolbar in

                YepAudioService.sharedManager.shouldIgnoreStart = true
                
                hideWaver()

                let interruptAudioRecord: () -> Void = {
                    YepAudioService.sharedManager.endRecord()
                    YepAudioService.sharedManager.recordTimeoutAction = nil
                }

                // 小于 0.5 秒不创建消息
                if YepAudioService.sharedManager.audioRecorder?.currentTime < YepConfig.AudioRecord.shortestDuration {
                    
                    interruptAudioRecord()
                    return
                }

                interruptAudioRecord()

                sendAudioMessage()
            }

            messageToolbar.voiceRecordCancelAction = { [weak self] messageToolbar in
                
                self?.swipeUpView.hidden = true
                self?.waverView.removeFromSuperview()

                YepAudioService.sharedManager.endRecord()

                YepAudioService.sharedManager.recordTimeoutAction = nil
            }

            messageToolbar.voiceRecordingUpdateUIAction = { [weak self] topOffset in

                let text: String

                if topOffset > 40 {
                    text = NSLocalizedString("Release to Cancel", comment: "")
                } else {
                    text = NSLocalizedString("Swipe Up to Cancel", comment: "")
                }

                self?.swipeUpPromptLabel.text = text
            }

            // MARK: MessageToolbar State Transitions

            messageToolbar.stateTransitionAction = { [weak self] (messageToolbar, previousState, currentState) in

                if let strongSelf = self {

                    switch (previousState, currentState) {

                    case (.MoreMessages, .Default): fallthrough
                    case (.MoreMessages, .VoiceRecord):

                        dispatch_async(dispatch_get_main_queue()) { [weak self] in

                            UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseInOut, animations: { _ in

                                strongSelf.conversationCollectionView.contentOffset.y -= strongSelf.moreMessageTypesViewDefaultHeight
                                strongSelf.conversationCollectionView.contentInset.bottom = strongSelf.messageToolbar.frame.height

                                strongSelf.messageToolbarBottomConstraint.constant = 0
                                strongSelf.view.layoutIfNeeded()

                            }, completion: { finished in
                            })
                        }

                    default:

                        if currentState == .MoreMessages {

                            if previousState != .BeginTextInput && previousState != .TextInputing {

                                dispatch_async(dispatch_get_main_queue()) { [weak self] in

                                    UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseInOut, animations: { _ in

                                        strongSelf.conversationCollectionView.contentOffset.y += strongSelf.moreMessageTypesViewDefaultHeight
                                        strongSelf.conversationCollectionView.contentInset.bottom = strongSelf.messageToolbar.frame.height + strongSelf.moreMessageTypesViewDefaultHeight

                                        strongSelf.messageToolbarBottomConstraint.constant = strongSelf.moreMessageTypesViewDefaultHeight
                                        strongSelf.view.layoutIfNeeded()

                                    }, completion: { finished in
                                    })
                                }
                            }

                            // touch to create (if need) for faster appear
                            delay(0.2) {
                                self?.imagePicker.hidesBarsOnTap = false
                            }
                        }
                    }

                    // 尝试保留草稿

                    let realm = Realm()

                    if let draft = strongSelf.conversation.draft {
                        realm.write {
                            draft.messageToolbarState = currentState.rawValue

                            if currentState == .BeginTextInput || currentState == .TextInputing {
                                draft.text = messageToolbar.messageTextView.text
                            }
                        }

                    } else {
                        let draft = Draft()
                        draft.messageToolbarState = currentState.rawValue

                        realm.write {
                            strongSelf.conversation.draft = draft
                        }
                    }
                }
            }

            // 在这里才尝试恢复 messageToolbar 的状态，因为依赖 stateTransitionAction

            tryRecoverMessageToolBar()

            // MARK: More Message Types

            choosePhotoButton.title = NSLocalizedString("Choose photo", comment: "")
            choosePhotoButton.tapAction = { [weak self] in

                let openCameraRoll: ProposerAction = { [weak self] in
                    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary){
                        if let strongSelf = self {
                            strongSelf.imagePicker.sourceType = .PhotoLibrary
                            strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
                        }
                    }
                }

                proposeToAccess(.Photos, agreed: openCameraRoll, rejected: {
                    self?.alertCanNotAccessCameraRoll()
                })
            }

            takePhotoButton.title = NSLocalizedString("Take photo", comment: "")
            takePhotoButton.tapAction = { [weak self] in

                let openCamera: ProposerAction = { [weak self] in
                    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
                        if let strongSelf = self {
                            strongSelf.imagePicker.sourceType = .Camera
                            strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
                        }
                    }
                }

                proposeToAccess(.Camera, agreed: openCamera, rejected: {
                    self?.alertCanNotOpenCamera()
                })
            }

            addLocationButton.title = NSLocalizedString("Share location", comment: "")
            addLocationButton.tapAction = { [weak self] in
                self?.performSegueWithIdentifier("presentPickLocation", sender: nil)
            }
        }
    }

    private func markMessageAsReaded(message: Message) {

        if message.readed {
            return
        }

        // 防止未在此界面时被标记

        if navigationController?.topViewController == self {

            let messageID = message.messageID

            dispatch_async(realmQueue) {
                let realm = Realm()
                
                if let message = messageWithMessageID(messageID, inRealm: realm) {
                    realm.write {
                        message.readed = true
                    }

                    markAsReadMessage(message, failureHandler: nil) { success in
                        if success {
                            println("appear Mark message \(messageID) as read")
                        }
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // 初始时移动一次到底部
        if !conversationCollectionViewHasBeenMovedToBottomOnce {

            // 先调整一下初次的 contentInset
            setConversaitonCollectionViewOriginalContentInset()

            // 尽量滚到底部
            tryScrollToBottom()
        }
    }

    // MARK: UI

    func tryShowFriendRequestView() {

        if let user = conversation.withFriend {

            // 若是陌生人或还未收到回应才显示 FriendRequestView
            if user.friendState != UserFriendState.Stranger.rawValue && user.friendState != UserFriendState.IssuedRequest.rawValue {
                return
            }

            let userID = user.userID
            let userNickname = user.nickname

            stateOfFriendRequestWithUser(user, failureHandler: { reason, errorMessage in
                defaultFailureHandler(reason, errorMessage)

            }, completion: { isFriend, receivedFriendRequestState, receivedFriendRequestID, sentFriendRequestState in

                println("isFriend: \(isFriend)")
                println("receivedFriendRequestState: \(receivedFriendRequestState.rawValue)")
                println("receivedFriendRequestID: \(receivedFriendRequestID)")
                println("sentFriendRequestState: \(sentFriendRequestState.rawValue)")

                // 已是好友下面就不用处理了
                if isFriend {
                    return
                }

                dispatch_async(dispatch_get_main_queue()) { [weak self] in

                    if receivedFriendRequestState == .Pending {
                        self?.makeFriendRequestViewWithUser(user, state: .Consider(prompt: NSLocalizedString("try add you as friend.", comment: ""), friendRequestID: receivedFriendRequestID))

                    } else if receivedFriendRequestState == .Blocked {
                        YepAlert.confirmOrCancel(title: NSLocalizedString("Notice", comment: ""), message: String(format: NSLocalizedString("You have blocked %@! Do you want to unblock him or her?", comment: ""), "\(userNickname)")
                            , confirmTitle: NSLocalizedString("Unblock", comment: ""), cancelTitle: NSLocalizedString("No now", comment: ""), inViewController: self, withConfirmAction: {

                            unblockUserWithUserID(userID, failureHandler: nil, completion: { success in
                                println("unblockUserWithUserID \(success)")

                                self?.updateBlocked(false, forUserWithUserID: userID, needUpdateUI: false)
                            })

                        }, cancelAction: {
                        })

                    } else {
                        if sentFriendRequestState == .None {
                            if receivedFriendRequestState != .Rejected && receivedFriendRequestState != .Blocked {
                                self?.makeFriendRequestViewWithUser(user, state: .Add(prompt: NSLocalizedString("is not your friend.", comment: "")))
                            }

                        } else if sentFriendRequestState == .Rejected {
                            self?.makeFriendRequestViewWithUser(user, state: .Add(prompt: NSLocalizedString("reject your last friend request.", comment: "")))

                        } else if sentFriendRequestState == .Blocked {
                            YepAlert.alertSorry(message: String(format: NSLocalizedString("You have been blocked by %@!", comment: ""), "\(userNickname)"), inViewController: self)
                        }
                    }
                }
            })
        }
    }

    func makeFriendRequestViewWithUser(user: User, state: FriendRequestView.State) {

        let friendRequestView = FriendRequestView(state: state)

        friendRequestView.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addSubview(friendRequestView)

        let friendRequestViewLeading = NSLayoutConstraint(item: friendRequestView, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1, constant: 0)
        let friendRequestViewTrailing = NSLayoutConstraint(item: friendRequestView, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1, constant: 0)
        let friendRequestViewTop = NSLayoutConstraint(item: friendRequestView, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1, constant: 64 - FriendRequestView.height)
        let friendRequestViewHeight = NSLayoutConstraint(item: friendRequestView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: FriendRequestView.height)

        NSLayoutConstraint.activateConstraints([friendRequestViewLeading, friendRequestViewTrailing, friendRequestViewTop, friendRequestViewHeight])

        view.layoutIfNeeded()
        UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.conversationCollectionView.contentInset.top += FriendRequestView.height

            friendRequestViewTop.constant += FriendRequestView.height
            self.view.layoutIfNeeded()

        }, completion: { _ in })

        friendRequestView.user = user

        let userID = user.userID

        let hideFriendRequestView: () -> Void = {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in

                UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                    self?.conversationCollectionView.contentInset.top = 64

                    friendRequestViewTop.constant -= FriendRequestView.height
                    self?.view.layoutIfNeeded()

                }, completion: { _ in
                    friendRequestView.removeFromSuperview()

                    if let strongSelf = self {
                        strongSelf.isTryingShowFriendRequestView = false
                    }
                })
            }
        }

        friendRequestView.addAction = { [weak self] friendRequestView in
            println("try Send Friend Request")

            sendFriendRequestToUser(user, failureHandler: { [weak self] reason, errorMessage in
                YepAlert.alertSorry(message: NSLocalizedString("Send Friend Request failed!", comment: ""), inViewController: self)

            }, completion: { friendRequestState in
                println("friendRequestState: \(friendRequestState.rawValue)")

                dispatch_async(dispatch_get_main_queue()) {
                    let realm = Realm()
                    if let user = userWithUserID(userID, inRealm: realm) {
                        realm.write {
                            user.friendState = UserFriendState.IssuedRequest.rawValue
                        }
                    }
                }

                hideFriendRequestView()
            })
        }

        friendRequestView.acceptAction = { [weak self] friendRequestView in
            println("friendRequestView.acceptAction")

            if let friendRequestID = friendRequestView.state.friendRequestID {

                acceptFriendRequestWithID(friendRequestID, failureHandler: { [weak self] reason, errorMessage in
                    YepAlert.alertSorry(message: NSLocalizedString("Accept Friend Request failed!", comment: ""), inViewController: self)

                }, completion: { success in
                    println("acceptFriendRequestWithID: \(friendRequestID), \(success)")

                    dispatch_async(dispatch_get_main_queue()) {
                        let realm = Realm()
                        if let user = userWithUserID(userID, inRealm: realm) {
                            realm.write {
                                user.friendState = UserFriendState.Normal.rawValue
                            }
                        }
                    }
                    
                    hideFriendRequestView()
                })

            } else {
                println("NOT friendRequestID for acceptFriendRequestWithID")
            }
        }

        friendRequestView.rejectAction = { [weak self] friendRequestView in
            println("friendRequestView.rejectAction")

            let confirmAction: () -> Void = {

                if let friendRequestID = friendRequestView.state.friendRequestID {

                    rejectFriendRequestWithID(friendRequestID, failureHandler: { [weak self] reason, errorMessage in
                        YepAlert.alertSorry(message: NSLocalizedString("Reject Friend Request failed!", comment: ""), inViewController: self)

                    }, completion: { success in
                        println("rejectFriendRequestWithID: \(friendRequestID), \(success)")

                        hideFriendRequestView()
                    })

                } else {
                    println("NOT friendRequestID for rejectFriendRequestWithID")
                }
            }

            YepAlert.confirmOrCancel(title: NSLocalizedString("Notice", comment: ""), message: NSLocalizedString("Do you want to reject this friend request?", comment: "")
                , confirmTitle: NSLocalizedString("Reject", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction:confirmAction, cancelAction: {
            })
        }
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
            let rect = message.textContent.boundingRectWithSize(CGSize(width: messageTextLabelMaxWidth, height: CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: YepConfig.ChatCell.textAttributes, context: nil)

            height = max(ceil(rect.height) + (11 * 2), YepConfig.chatCellAvatarSize())

            if !key.isEmpty {
                textContentLabelWidths[key] = ceil(rect.width)
            }

        case MessageMediaType.Image.rawValue:

            if let (imageWidth, imageHeight) = imageMetaOfMessage(message) {

                let aspectRatio = imageWidth / imageHeight

                if aspectRatio >= 1 {
                    height = max(ceil(messageImagePreferredWidth / aspectRatio), YepConfig.ChatCell.mediaMinHeight)
                } else {
                    height = max(messageImagePreferredHeight, ceil(YepConfig.ChatCell.mediaMinWidth / aspectRatio))
                }

            } else {
                height = ceil(messageImagePreferredWidth / messageImagePreferredAspectRatio)
            }

        case MessageMediaType.Audio.rawValue:
            height = 40

        case MessageMediaType.Video.rawValue:

            if let (videoWidth, videoHeight) = videoMetaOfMessage(message) {

                let aspectRatio = videoWidth / videoHeight

                if aspectRatio >= 1 {
                    height = max(ceil(messageImagePreferredWidth / aspectRatio), YepConfig.ChatCell.mediaMinHeight)
                } else {
                    height = max(messageImagePreferredHeight, ceil(YepConfig.ChatCell.mediaMinWidth / aspectRatio))
                }

            } else {
                height = ceil(messageImagePreferredWidth / messageImagePreferredAspectRatio)
            }

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

        let rect = message.textContent.boundingRectWithSize(CGSize(width: messageTextLabelMaxWidth, height: CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: YepConfig.ChatCell.textAttributes, context: nil)

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

        // recover audio cells' UI

        if audioPlayedDuration == 0 {

            if let sender = message.fromFriend, index = messages.indexOf(message) {

                let indexPath = NSIndexPath(forItem: index - displayedMessagesRange.location, inSection: 0)

                if sender.friendState != UserFriendState.Me.rawValue { // from Friend
                    if let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatLeftAudioCell {
                        cell.audioPlayedDuration = 0
                    }

                } else {
                    if let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatRightAudioCell {
                        cell.audioPlayedDuration = 0
                    }
                }
            }
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

    func checkTypingStatus() {

        typingResetDelay = typingResetDelay - 0.5

        if typingResetDelay < 0 {
            self.updateStateInfoOfTitleView(titleView)
        }
    }

    func tryScrollToBottom() {

        if displayedMessagesRange.length > 0 {

            let messageToolBarTop = messageToolbarBottomConstraint.constant + CGRectGetHeight(messageToolbar.bounds)
            let invisibleHeight = messageToolBarTop + topBarsHeight
            let visibleHeight = conversationCollectionView.frame.height - invisibleHeight

            let canScroll = visibleHeight <= conversationCollectionView.contentSize.height

            if canScroll {
                conversationCollectionView.contentOffset.y = conversationCollectionView.contentSize.height - conversationCollectionView.frame.size.height + messageToolBarTop
                conversationCollectionView.contentInset.bottom = messageToolBarTop
            }
        }
    }

    func moreAction() {

        messageToolbar.state = .Default

        moreView.showProfileAction = { [weak self] in
            self?.performSegueWithIdentifier("showProfile", sender: nil)
        }

        if let user = conversation.withFriend {
            moreView.notificationEnabled = user.notificationEnabled
            moreView.blocked = user.blocked

            let userID = user.userID

            userInfoOfUserWithUserID(userID, failureHandler: nil, completion: { userInfo in
                //println("userInfoOfUserWithUserID \(userInfo)")

                if let doNotDisturb = userInfo["do_not_disturb"] as? Bool {
                    self.updateNotificationEnabled(!doNotDisturb, forUserWithUserID: userID)
                }

                if let blocked = userInfo["blocked"] as? Bool {
                    self.updateBlocked(blocked, forUserWithUserID: userID)
                }

                // 对非好友来说，必要

                updateUserWithUserID(userID, useUserInfo: userInfo)
            })
        }

        moreView.toggleDoNotDisturbAction = { [weak self] in
            self?.toggleDoNotDisturb()
        }

        moreView.toggleBlockAction = { [weak self] in
            self?.toggleBlock()
        }

        moreView.reportAction = { [weak self] in
            self?.report()
        }

        if let window = view.window {
            moreView.showInView(window)
        }
    }

    func updateNotificationEnabled(enabled: Bool, forUserWithUserID userID: String) {
        let realm = Realm()

        if let user = userWithUserID(userID, inRealm: realm) {
            realm.write {
                user.notificationEnabled = enabled
            }

            moreView.notificationEnabled = enabled
        }
    }

    func toggleDoNotDisturb() {

        if let user = conversation.withFriend {

            let userID = user.userID

            if user.notificationEnabled {
                disableNotificationFromUserWithUserID(userID, failureHandler: nil, completion: { success in
                    println("disableNotificationFromUserWithUserID \(success)")

                    self.updateNotificationEnabled(false, forUserWithUserID: userID)
                })

            } else {
                enableNotificationFromUserWithUserID(userID, failureHandler: nil, completion: { success in
                    println("enableNotificationFromUserWithUserID \(success)")

                    self.updateNotificationEnabled(true, forUserWithUserID: userID)
                })
            }
        }
    }

    func report() {

        let reportWithReason: ReportReason -> Void = { [weak self] reason in

            if let user = self?.conversation.withFriend {
                let profileUser = ProfileUser.UserType(user)

                reportProfileUser(profileUser, forReason: reason, failureHandler: { [weak self] (reason, errorMessage) in
                    defaultFailureHandler(reason, errorMessage)

                    if let errorMessage = errorMessage {
                        YepAlert.alertSorry(message: errorMessage, inViewController: self)
                    }

                }, completion: { [weak self] success in
                    YepAlert.alert(title: NSLocalizedString("Success", comment: ""), message: NSLocalizedString("Report recorded!", comment: ""), dismissTitle: NSLocalizedString("OK", comment: ""), inViewController: self, withDismissAction: nil)
                })
            }
        }

        let reportAlertController = UIAlertController(title: NSLocalizedString("Report Reason", comment: ""), message: nil, preferredStyle: .ActionSheet)

        let pornoReasonAction: UIAlertAction = UIAlertAction(title: ReportReason.Porno.description, style: .Default) { action -> Void in
            reportWithReason(.Porno)
        }
        reportAlertController.addAction(pornoReasonAction)

        let advertisingReasonAction: UIAlertAction = UIAlertAction(title: ReportReason.Advertising.description, style: .Default) { action -> Void in
            reportWithReason(.Advertising)
        }
        reportAlertController.addAction(advertisingReasonAction)

        let scamsReasonAction: UIAlertAction = UIAlertAction(title: ReportReason.Scams.description, style: .Default) { action -> Void in
            reportWithReason(.Scams)
        }
        reportAlertController.addAction(scamsReasonAction)

        let otherReasonAction: UIAlertAction = UIAlertAction(title: ReportReason.Other("").description, style: .Default) { [weak self] action -> Void in
            YepAlert.textInput(title: NSLocalizedString("Other Reason", comment: ""), placeholder: nil, oldText: nil, confirmTitle: NSLocalizedString("OK", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: { text in
                reportWithReason(.Other(text))
            }, cancelAction: nil)
        }
        reportAlertController.addAction(otherReasonAction)

        let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel) { action -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        reportAlertController.addAction(cancelAction)
        
        self.presentViewController(reportAlertController, animated: true, completion: nil)
    }

    func updateBlocked(blocked: Bool, forUserWithUserID userID: String, needUpdateUI: Bool = true) {
        let realm = Realm()

        if let user = userWithUserID(userID, inRealm: realm) {
            realm.write {
                user.blocked = blocked
            }

            if needUpdateUI {
                moreView.blocked = blocked
            }
        }
    }

    func toggleBlock() {

        if let user = conversation.withFriend {

            let userID = user.userID

            if user.blocked {
                unblockUserWithUserID(userID, failureHandler: nil, completion: { success in
                    println("unblockUserWithUserID \(success)")

                    self.updateBlocked(false, forUserWithUserID: userID)
                })

            } else {
                blockUserWithUserID(userID, failureHandler: nil, completion: { success in
                    println("blockUserWithUserID \(success)")

                    self.updateBlocked(true, forUserWithUserID: userID)
                })
            }
        }
    }

    func handleReceivedNewMessagesNotification(notification: NSNotification) {

        var messageIDs: [String]?

        if let messagesInfo = notification.object as? [String: [String]], let allMessageIDs = messagesInfo["messageIDs"] {

            // 按照 conversation 过滤消息，匹配的才能考虑插入

            if let conversation = conversation, conversationID = conversation.fakeID, realm = conversation.realm {

                var filteredMessageIDs = [String]()

                for messageID in allMessageIDs {
                    if let message = messageWithMessageID(messageID, inRealm: realm) {
                        if let messageInConversation = message.conversation, messageInConversationID = messageInConversation.fakeID {
                            if messageInConversationID == conversationID {
                                filteredMessageIDs.append(messageID)
                            }
                        }
                    }
                }

                messageIDs = filteredMessageIDs
            }
        }

        // 在前台时才能做插入

        if UIApplication.sharedApplication().applicationState == .Active {
            updateConversationCollectionViewWithMessageIDs(messageIDs, scrollToBottom: false, success: { _ in
            })

        } else {

            // 不然就先记下来

            if let messageIDs = messageIDs {
                for messageID in messageIDs {
                    inActiveNewMessageIDSet.insert(messageID)
                    println("inActiveNewMessageIDSet insert: \(messageID)")
                }
            }
        }
    }

    // App 进入前台时，根据通知插入处于后台状态时收到的消息

    func tryInsertInActiveNewMessages(notification: NSNotification) {

        if UIApplication.sharedApplication().applicationState == .Active {

            if inActiveNewMessageIDSet.count > 0 {
                updateConversationCollectionViewWithMessageIDs(Array(inActiveNewMessageIDSet), scrollToBottom: false, success: { _ in
                })

                inActiveNewMessageIDSet = []

                println("insert inActiveNewMessageIDSet to CollectionView")
            }
        }
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

        var newMessagesCount = Int(messages.count - _lastTimeMessagesCount)

        /*
        if let messageIDs = messageIDs {
            newMessagesCount = messageIDs.count
        }
        */

        let lastDisplayedMessagesRange = displayedMessagesRange

        displayedMessagesRange.length += newMessagesCount

        // 异常：两种计数不相等，治标：reload，避免插入
        if let messageIDs = messageIDs {
            if newMessagesCount != messageIDs.count {
                reloadConversationCollectionView()
                println("newMessagesCount != messageIDs.count")
                return
            }
        }

        if newMessagesCount > 0 {

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

                println("insert messages A")

            } else {
                println("self message")

                // 这里做了一个假设：本地刚创建的消息比所有的已有的消息都要新，这在创建消息里做保证（服务器可能传回创建在“未来”的消息）

                var indexPaths = [NSIndexPath]()

                for i in 0..<newMessagesCount {
                    let indexPath = NSIndexPath(forItem: lastDisplayedMessagesRange.length + i, inSection: 0)
                    indexPaths.append(indexPath)
                }

                conversationCollectionView.insertItemsAtIndexPaths(indexPaths)

                println("insert messages B")
            }
        }

        if newMessagesCount > 0 {
            
            var newMessagesTotalHeight: CGFloat = 0
            for i in _lastTimeMessagesCount..<messages.count {
                if let message = messages[safe: i] {
                    let height = heightOfMessage(message) + YepConfig.ChatCell.lineSpacing
                    newMessagesTotalHeight += height
                }
            }
            
            let keyboardAndToolBarHeight = adjustHeight
            
            let blockedHeight = topBarsHeight + keyboardAndToolBarHeight
            
            let visibleHeight = conversationCollectionView.frame.height - blockedHeight

            // cal the height can be used
            let useableHeight = visibleHeight - conversationCollectionView.contentSize.height

            let totalHeight = conversationCollectionView.contentSize.height + blockedHeight + newMessagesTotalHeight

            if totalHeight > conversationCollectionView.frame.height {

                UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { [weak self] in

                    if let strongSelf = self {

                        if (useableHeight > 0) {
                            let contentToScroll = newMessagesTotalHeight - useableHeight
                            strongSelf.conversationCollectionView.contentOffset.y += contentToScroll

                        } else {
                            if scrollToBottom {
                                let newContentSize = strongSelf.conversationCollectionView.collectionViewLayout.collectionViewContentSize()
                                let newContentOffsetY = newContentSize.height - strongSelf.conversationCollectionView.frame.height + keyboardAndToolBarHeight
                                strongSelf.conversationCollectionView.contentOffset.y = newContentOffsetY

                            } else {
                                strongSelf.conversationCollectionView.contentOffset.y += newMessagesTotalHeight
                            }
                        }
                    }

                }, completion: { _ in
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
        dispatch_async(dispatch_get_main_queue()) {
            self.conversationCollectionView.reloadData()
        }
    }

    func cleanTextInput() {
        messageToolbar.messageTextView.text = ""
        messageToolbar.state = .BeginTextInput
    }

    func updateStateInfoOfTitleView(titleView: ConversationTitleView) {
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            if let strongSelf = self {
                if let timeAgo = lastSignDateOfConversation(strongSelf.conversation)?.timeAgo {
                    titleView.stateInfoLabel.text = NSLocalizedString("Last seen ", comment: "") + timeAgo.lowercaseString
                } else if let friend = strongSelf.conversation.withFriend {
                    titleView.stateInfoLabel.text = NSLocalizedString("Last seen ", comment: "") + NSDate(timeIntervalSince1970: friend.lastSignInUnixTime).timeAgo.lowercaseString
                } else {
                    titleView.stateInfoLabel.text = NSLocalizedString("Begin chat just now", comment: "")
                }
            }
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

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showProfile" {

            let vc = segue.destinationViewController as! ProfileViewController

            if let user = sender as? User {
                vc.profileUser = ProfileUser.UserType(user)

            } else {
                if let withFriend = conversation?.withFriend {
                    if withFriend.userID != YepUserDefaults.userID.value {
                        vc.profileUser = ProfileUser.UserType(withFriend)
                    }
                }
            }

            vc.isFromConversation = true
            vc.setBackButtonWithTitle()

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
                    delegate.snapshot = UIScreen.mainScreen().snapshotViewAfterScreenUpdates(false)
                    delegate.frame = frame
                    delegate.thumbnailImage = message.thumbnailImage
                    delegate.transitionView = transitionView

                    navigationControllerDelegate = delegate

                    // 在自定义 push 之前，记录原始的 NavigationControllerDelegate 以便 pop 后恢复
                    originalNavigationControllerDelegate = navigationController!.delegate

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

            vc.sendLocationAction = { [weak self] coordinate in

                if let withFriend = self?.conversation.withFriend {

                    sendLocationWithCoordinate(coordinate, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { message in

                        dispatch_async(dispatch_get_main_queue()) {
                            self?.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { _ in
                            })
                        }

                    }, failureHandler: { [weak self] reason, errorMessage in
                        defaultFailureHandler(reason, errorMessage)

                        YepAlert.alertSorry(message: NSLocalizedString("Failed to send location!\nTry tap on message to resend.", comment: ""), inViewController: self)

                    }, completion: { success -> Void in
                        println("sendLocation to friend: \(success)")
                    })

                } else if let withGroup = self?.conversation.withGroup {

                    sendLocationWithCoordinate(coordinate, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { message in
                        dispatch_async(dispatch_get_main_queue()) {
                            self?.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { _ in
                            })
                        }

                    }, failureHandler: { [weak self] reason, errorMessage in
                        defaultFailureHandler(reason, errorMessage)

                        YepAlert.alertSorry(message: NSLocalizedString("Failed to send location!\nTry tap on message to resend.", comment: ""), inViewController: self)

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

        if let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] {

            if message.mediaType == MessageMediaType.SectionDate.rawValue {

                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatSectionDateCellIdentifier, forIndexPath: indexPath) as! ChatSectionDateCell

                return cell
            }

            if let sender = message.fromFriend {

                if sender.friendState != UserFriendState.Me.rawValue { // from Friend

                    markMessageAsReaded(message)

                    switch message.mediaType {

                    case MessageMediaType.Image.rawValue:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftImageCellIdentifier, forIndexPath: indexPath) as! ChatLeftImageCell

                        return cell

                    case MessageMediaType.Audio.rawValue:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftAudioCellIdentifier, forIndexPath: indexPath) as! ChatLeftAudioCell

                        return cell

                    case MessageMediaType.Video.rawValue:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftVideoCellIdentifier, forIndexPath: indexPath) as! ChatLeftVideoCell

                        return cell

                    case MessageMediaType.Location.rawValue:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftLocationCellIdentifier, forIndexPath: indexPath) as! ChatLeftLocationCell

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

                        return cell

                    case MessageMediaType.Audio.rawValue:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightAudioCellIdentifier, forIndexPath: indexPath) as! ChatRightAudioCell

                        return cell

                    case MessageMediaType.Video.rawValue:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightVideoCellIdentifier, forIndexPath: indexPath) as! ChatRightVideoCell

                        return cell

                    case MessageMediaType.Location.rawValue:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightLocationCellIdentifier, forIndexPath: indexPath) as! ChatRightLocationCell

                        return cell

                    default:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightTextCellIdentifier, forIndexPath: indexPath) as! ChatRightTextCell

                        return cell
                    }
                }
            }
        }

        println("🐌 Conversation: Should not be there")

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatSectionDateCellIdentifier, forIndexPath: indexPath) as! ChatSectionDateCell

        cell.sectionDateLabel.text = "🐌"

        return cell

    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {

        if let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] {

            if message.mediaType == MessageMediaType.SectionDate.rawValue {

                if let cell = cell as? ChatSectionDateCell {
                    let createdAt = NSDate(timeIntervalSince1970: message.createdUnixTime)

                    if createdAt.isInCurrentWeek() {
                        cell.sectionDateLabel.text = sectionDateInCurrentWeekFormatter.stringFromDate(createdAt)
                    } else {
                        cell.sectionDateLabel.text = sectionDateFormatter.stringFromDate(createdAt)
                    }
                }

                return
            }

            if let sender = message.fromFriend {

                if let cell = cell as? ChatBaseCell {
                    cell.tapAvatarAction = { [weak self] user in
                        self?.performSegueWithIdentifier("showProfile", sender: user)
                    }
                }

                if sender.friendState != UserFriendState.Me.rawValue { // from Friend

                    markMessageAsReaded(message)

                    switch message.mediaType {

                    case MessageMediaType.Image.rawValue:

                        if let cell = cell as? ChatLeftImageCell {

                            cell.configureWithMessage(message, messageImagePreferredWidth: messageImagePreferredWidth, messageImagePreferredHeight: messageImagePreferredHeight, messageImagePreferredAspectRatio: messageImagePreferredAspectRatio, mediaTapAction: { [weak self] in

                                if message.downloadState == MessageDownloadState.Downloaded.rawValue {
                                    self?.performSegueWithIdentifier("showMessageMedia", sender: message)

                                } else {
                                    YepAlert.alertSorry(message: NSLocalizedString("Please wait while the image is not dready!", comment: ""), inViewController: self)
                                }

                            }, collectionView: collectionView, indexPath: indexPath)
                        }

                    case MessageMediaType.Audio.rawValue:

                        if let cell = cell as? ChatLeftAudioCell {

                            let audioPlayedDuration = audioPlayedDurationOfMessage(message)

                            cell.configureWithMessage(message, audioPlayedDuration: audioPlayedDuration, audioBubbleTapAction: { [weak self] in

                                if message.downloadState == MessageDownloadState.Downloaded.rawValue {
                                    self?.playMessageAudioWithMessage(message)

                                } else {
                                    YepAlert.alertSorry(message: NSLocalizedString("Please wait while the audio is not dready!", comment: ""), inViewController: self)
                                }

                            }, collectionView: collectionView, indexPath: indexPath)
                        }

                    case MessageMediaType.Video.rawValue:

                        if let cell = cell as? ChatLeftVideoCell {

                            cell.configureWithMessage(message, messageImagePreferredWidth: messageImagePreferredWidth, messageImagePreferredHeight: messageImagePreferredHeight, messageImagePreferredAspectRatio: messageImagePreferredAspectRatio, mediaTapAction: { [weak self] in

                                if message.downloadState == MessageDownloadState.Downloaded.rawValue {
                                    self?.performSegueWithIdentifier("showMessageMedia", sender: message)

                                } else {
                                    YepAlert.alertSorry(message: NSLocalizedString("Please wait while the video is not dready!", comment: ""), inViewController: self)
                                }

                            }, collectionView: collectionView, indexPath: indexPath)
                        }

                    case MessageMediaType.Location.rawValue:

                        if let cell = cell as? ChatLeftLocationCell {

                            cell.configureWithMessage(message, mediaTapAction: { [weak self] in
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
                        }

                    default:

                        if let cell = cell as? ChatLeftTextCell {

                            cell.configureWithMessage(message, textContentLabelWidth: textContentLabelWidthOfMessage(message), collectionView: collectionView, indexPath: indexPath)
                        }
                    }

                } else { // from Me

                    switch message.mediaType {

                    case MessageMediaType.Image.rawValue:

                        if let cell = cell as? ChatRightImageCell {

                            cell.configureWithMessage(message, messageImagePreferredWidth: messageImagePreferredWidth, messageImagePreferredHeight: messageImagePreferredHeight, messageImagePreferredAspectRatio: messageImagePreferredAspectRatio, mediaTapAction: { [weak self] in

                                if message.sendState == MessageSendState.Failed.rawValue {

                                    YepAlert.confirmOrCancel(title: NSLocalizedString("Action", comment: ""), message: NSLocalizedString("Resend image?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: {

                                        resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                            defaultFailureHandler(reason, errorMessage)

                                            YepAlert.alertSorry(message: NSLocalizedString("Failed to resend image!\nPlease make sure your iPhone is connected to the Internet.", comment: ""), inViewController: self)

                                        }, completion: { success in
                                            println("resendImage: \(success)")
                                        })

                                    }, cancelAction: {
                                    })

                                } else {
                                    self?.performSegueWithIdentifier("showMessageMedia", sender: message)
                                }

                            }, collectionView: collectionView, indexPath: indexPath)
                        }

                    case MessageMediaType.Audio.rawValue:

                        if let cell = cell as? ChatRightAudioCell {

                            let audioPlayedDuration = audioPlayedDurationOfMessage(message)

                            cell.configureWithMessage(message, audioPlayedDuration: audioPlayedDuration, audioBubbleTapAction: { [weak self] in

                                if message.sendState == MessageSendState.Failed.rawValue {

                                    YepAlert.confirmOrCancel(title: NSLocalizedString("Action", comment: ""), message: NSLocalizedString("Resend audio?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: {

                                        resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                            defaultFailureHandler(reason, errorMessage)

                                            YepAlert.alertSorry(message: NSLocalizedString("Failed to resend audio!\nPlease make sure your iPhone is connected to the Internet.", comment: ""), inViewController: self)

                                        }, completion: { success in
                                            println("resendAudio: \(success)")
                                        })

                                    }, cancelAction: {
                                    })

                                    return
                                }

                                self?.playMessageAudioWithMessage(message)

                            }, collectionView: collectionView, indexPath: indexPath)
                        }

                    case MessageMediaType.Video.rawValue:

                        if let cell = cell as? ChatRightVideoCell {

                            cell.configureWithMessage(message, messageImagePreferredWidth: messageImagePreferredWidth, messageImagePreferredHeight: messageImagePreferredHeight, messageImagePreferredAspectRatio: messageImagePreferredAspectRatio, mediaTapAction: { [weak self] in

                                if message.sendState == MessageSendState.Failed.rawValue {

                                    YepAlert.confirmOrCancel(title: NSLocalizedString("Action", comment: ""), message: NSLocalizedString("Resend video?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: {

                                        resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                            defaultFailureHandler(reason, errorMessage)

                                            YepAlert.alertSorry(message: NSLocalizedString("Failed to resend video!\nPlease make sure your iPhone is connected to the Internet.", comment: ""), inViewController: self)

                                        }, completion: { success in
                                            println("resendVideo: \(success)")
                                        })

                                    }, cancelAction: {
                                    })

                                } else {
                                    self?.performSegueWithIdentifier("showMessageMedia", sender: message)
                                }

                            }, collectionView: collectionView, indexPath: indexPath)
                        }

                    case MessageMediaType.Location.rawValue:

                        if let cell = cell as? ChatRightLocationCell {

                            cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                                if message.sendState == MessageSendState.Failed.rawValue {

                                    YepAlert.confirmOrCancel(title: NSLocalizedString("Action", comment: ""), message: NSLocalizedString("Resend location?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: {

                                        resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                            defaultFailureHandler(reason, errorMessage)

                                            YepAlert.alertSorry(message: NSLocalizedString("Failed to resend location!\nPlease make sure your iPhone is connected to the Internet.", comment: ""), inViewController: self)

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
                        }

                    default:

                        if let cell = cell as? ChatRightTextCell {

                            cell.configureWithMessage(message, textContentLabelWidth: textContentLabelWidthOfMessage(message), mediaTapAction: { [weak self] in

                                if message.sendState == MessageSendState.Failed.rawValue {

                                    YepAlert.confirmOrCancel(title: NSLocalizedString("Action", comment: ""), message: NSLocalizedString("Resend text?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: {

                                        resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                            defaultFailureHandler(reason, errorMessage)

                                            YepAlert.alertSorry(message: NSLocalizedString("Failed to resend text!\nPlease make sure your iPhone is connected to the Internet.", comment: ""), inViewController: self)

                                        }, completion: { success in
                                            println("resendText: \(success)")
                                        })

                                    }, cancelAction: {
                                    })
                                }
                            }, collectionView: collectionView, indexPath: indexPath)

                            cell.longPressAction = { [weak self] in
                                dispatch_async(dispatch_get_main_queue()) {
                                    if let strongSelf = self, realm = message.realm {

                                        var sectionDateMessage: Message?

                                        if let currentMessageIndex = strongSelf.messages.indexOf(message) {

                                            let previousMessageIndex = currentMessageIndex - 1

                                            if let previousMessage = strongSelf.messages[safe: previousMessageIndex] {

                                                if previousMessage.mediaType == MessageMediaType.SectionDate.rawValue {
                                                    sectionDateMessage = previousMessage
                                                }
                                            }
                                        }

                                        let currentIndexPath: NSIndexPath
                                        if let index = strongSelf.messages.indexOf(message) {
                                            currentIndexPath = NSIndexPath(forItem: index - strongSelf.displayedMessagesRange.location, inSection: indexPath.section)
                                        } else {
                                            currentIndexPath = indexPath
                                        }

                                        if let sectionDateMessage = sectionDateMessage {

                                            var canDeleteTwoMessages = false // 考虑刚好的边界情况，例如消息为本束的最后一条，而 sectionDate 在上一束中
                                            if strongSelf.displayedMessagesRange.length >= 2 {
                                                strongSelf.displayedMessagesRange.length -= 2
                                                canDeleteTwoMessages = true

                                            } else {
                                                if strongSelf.displayedMessagesRange.location >= 1 {
                                                    strongSelf.displayedMessagesRange.location -= 1
                                                }
                                                strongSelf.displayedMessagesRange.length -= 1
                                            }

                                            realm.write {
                                                if let mediaMetaData = sectionDateMessage.mediaMetaData {
                                                    realm.delete(mediaMetaData)
                                                }
                                                if let mediaMetaData = message.mediaMetaData {
                                                    realm.delete(mediaMetaData)
                                                }
                                                realm.delete(sectionDateMessage)
                                                realm.delete(message)
                                            }

                                            if canDeleteTwoMessages {
                                                let previousIndexPath = NSIndexPath(forItem: currentIndexPath.item - 1, inSection: currentIndexPath.section)
                                                strongSelf.conversationCollectionView.deleteItemsAtIndexPaths([previousIndexPath, currentIndexPath])
                                            } else {
                                                strongSelf.conversationCollectionView.deleteItemsAtIndexPaths([currentIndexPath])
                                            }

                                        } else {
                                            strongSelf.displayedMessagesRange.length -= 1
                                            realm.write {
                                                if let mediaMetaData = message.mediaMetaData {
                                                    realm.delete(mediaMetaData)
                                                }
                                                realm.delete(message)
                                            }
                                            strongSelf.conversationCollectionView.deleteItemsAtIndexPaths([currentIndexPath])
                                        }

                                        // 必须更新，插入时需要
                                        strongSelf.lastTimeMessagesCount = strongSelf.messages.count
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        if let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] {
            return CGSize(width: collectionViewWidth, height: heightOfMessage(message))

        } else {
            return CGSize(width: collectionViewWidth, height: 0)
        }
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

}

// MARK: FayeServiceDelegate

extension ConversationViewController: FayeServiceDelegate {

    func fayeRecievedInstantStateType(instantStateType: FayeService.InstantStateType, userID: String) {

        if let withFriend = conversation.withFriend {

            if userID == withFriend.userID {

                let nickname = withFriend.nickname

                let content = "\(nickname)" + NSLocalizedString(" is ", comment: "正在") + "\(instantStateType)"

                titleView.stateInfoLabel.text = "\(content)..."

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

        delay(0.5) {

            pulllToRefreshView.endRefreshingAndDoFurtherAction() { [weak self] in

                if let strongSelf = self {
                    let lastDisplayedMessagesRange = strongSelf.displayedMessagesRange

                    var newMessagesCount = strongSelf.messagesBunchCount

                    if (strongSelf.displayedMessagesRange.location - newMessagesCount) < 0 {
                        newMessagesCount = strongSelf.displayedMessagesRange.location - newMessagesCount
                    }

                    if newMessagesCount > 0 {
                        strongSelf.displayedMessagesRange.location -= newMessagesCount
                        strongSelf.displayedMessagesRange.length += newMessagesCount

                        strongSelf.lastTimeMessagesCount = strongSelf.messages.count // 同样需要纪录它

                        var indexPaths = [NSIndexPath]()
                        for i in 0..<newMessagesCount {
                            let indexPath = NSIndexPath(forItem: Int(i), inSection: 0)
                            indexPaths.append(indexPath)
                        }

                        let bottomOffset = strongSelf.conversationCollectionView.contentSize.height - strongSelf.conversationCollectionView.contentOffset.y
                        
                        CATransaction.begin()
                        CATransaction.setDisableActions(true)

                        strongSelf.conversationCollectionView.performBatchUpdates({ [weak self] in
                            self?.conversationCollectionView.insertItemsAtIndexPaths(indexPaths)

                        }, completion: { [weak self] finished in
                            if let strongSelf = self {
                                var contentOffset = strongSelf.conversationCollectionView.contentOffset
                                contentOffset.y = strongSelf.conversationCollectionView.contentSize.height - bottomOffset

                                strongSelf.conversationCollectionView.setContentOffset(contentOffset, animated: false)

                                CATransaction.commit()

                                // 上面的 CATransaction 保证了 CollectionView 在插入后不闪动
                                // 此时再做个 scroll 动画比较自然
                                let indexPath = NSIndexPath(forItem: newMessagesCount - 1, inSection: 0)
                                strongSelf.conversationCollectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredVertically, animated: true)
                            }
                        })
                    }
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

        UIDevice.currentDevice().proximityMonitoringEnabled = false

        println("audioPlayerDidFinishPlaying \(flag)")

        if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
            playbackTimer.invalidate()
        }

        if let playingMessage = YepAudioService.sharedManager.playingMessage {
            setAudioPlayedDuration(0, ofMessage: playingMessage)
            println("setAudioPlayedDuration to 0")
        }

        func nextAudioMessageFrom(message: Message) -> Message? {

            if let index = messages.indexOf(message) {
                for i in (index + 1)..<messages.count {
                    if let message = messages[safe: i], friend = message.fromFriend {
                        if friend.friendState != UserFriendState.Me.rawValue {
                            if message.mediaType == MessageMediaType.Audio.rawValue {
                                return message
                            }
                        }
                    }
                }
            }

            return nil
        }

        // 尝试播放下一个
        if let playingMessage = YepAudioService.sharedManager.playingMessage {
            let nextAudioMessage = nextAudioMessageFrom(playingMessage)
            playMessageAudioWithMessage(nextAudioMessage)
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

            switch mediaType {

            case kUTTypeImage as! String:

                if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {

                    let imageWidth = image.size.width
                    let imageHeight = image.size.height

                    let fixedImageWidth: CGFloat
                    let fixedImageHeight: CGFloat

                    if imageWidth > imageHeight {
                        fixedImageWidth = min(imageWidth, YepConfig.Media.imageWidth)
                        fixedImageHeight = imageHeight * (fixedImageWidth / imageWidth)
                    } else {
                        fixedImageHeight = min(imageHeight, YepConfig.Media.imageHeight)
                        fixedImageWidth = imageWidth * (fixedImageHeight / imageHeight)
                    }

                    let fixedSize = CGSize(width: fixedImageWidth, height: fixedImageHeight)

                    // resize to smaller, not need fixRotation

                    if let fixedImage = image.resizeToSize(fixedSize, withInterpolationQuality: kCGInterpolationMedium) {
                        sendImage(fixedImage)
                    }
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

        let imageWidth = image.size.width
        let imageHeight = image.size.height

        let thumbnailWidth: CGFloat
        let thumbnailHeight: CGFloat

        if imageWidth > imageHeight {
            thumbnailWidth = min(imageWidth, YepConfig.MetaData.thumbnailMaxSize)
            thumbnailHeight = imageHeight * (thumbnailWidth / imageWidth)
        } else {
            thumbnailHeight = min(imageHeight, YepConfig.MetaData.thumbnailMaxSize)
            thumbnailWidth = imageWidth * (thumbnailHeight / imageHeight)
        }

        let audioMetaDataInfo: [String: AnyObject]

        if let thumbnail = image.resizeToSize(CGSize(width: thumbnailWidth, height: thumbnailHeight), withInterpolationQuality: kCGInterpolationLow) {
            let blurredThumbnail = thumbnail.blurredImageWithRadius(5, iterations: 7, tintColor: UIColor.clearColor())

            let data = UIImageJPEGRepresentation(blurredThumbnail, 0.7)

            let string = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(0))

            print("image blurredThumbnail string length: \(string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))\n")

            audioMetaDataInfo = [
                YepConfig.MetaData.imageWidth: imageWidth,
                YepConfig.MetaData.imageHeight: imageHeight,
                YepConfig.MetaData.blurredThumbnailString: string,
            ]

        } else {
            audioMetaDataInfo = [
                YepConfig.MetaData.imageWidth: imageWidth,
                YepConfig.MetaData.imageHeight: imageHeight
            ]
        }

        var metaData: String? = nil

        if let imageMetaData = NSJSONSerialization.dataWithJSONObject(audioMetaDataInfo, options: nil, error: nil) {
            let imageMetaDataString = NSString(data: imageMetaData, encoding: NSUTF8StringEncoding) as? String
            metaData = imageMetaDataString
        }

        // Do send

        let imageData = UIImageJPEGRepresentation(image, YepConfig.messageImageCompressionQuality())

        let messageImageName = NSUUID().UUIDString

        if let withFriend = conversation.withFriend {

            sendImageInFilePath(nil, orFileData: imageData, metaData: metaData, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { [weak self] message in

                dispatch_async(dispatch_get_main_queue()) {

                    if let messageImageURL = NSFileManager.saveMessageImageData(imageData, withName: messageImageName) {
                        if let realm = message.realm {
                            realm.beginWrite()
                            message.localAttachmentName = messageImageName
                            message.mediaType = MessageMediaType.Image.rawValue
                            if let metaDataString = metaData {
                                message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                            }
                            realm.commitWrite()
                        }
                    }

                    self?.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { _ in
                    })
                }

            }, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason, errorMessage)

                YepAlert.alertSorry(message: NSLocalizedString("Failed to send image!\nTry tap on message to resend.", comment: ""), inViewController: self)

            }, completion: { success -> Void in
                println("sendImage to friend: \(success)")
            })

        } else if let withGroup = conversation.withGroup {

            sendImageInFilePath(nil, orFileData: imageData, metaData: nil, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { [weak self] message in

                dispatch_async(dispatch_get_main_queue()) {
                    if let messageImageURL = NSFileManager.saveMessageImageData(imageData, withName: messageImageName) {
                        if let realm = message.realm {
                            realm.beginWrite()
                            message.localAttachmentName = messageImageName
                            message.mediaType = MessageMediaType.Image.rawValue
                            if let metaDataString = metaData {
                                message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                            }
                            realm.commitWrite()
                        }
                    }
                    
                    self?.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { _ in
                    })
                }
                
            }, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason, errorMessage)

                YepAlert.alertSorry(message: NSLocalizedString("Failed to send image!\nTry tap on message to resend.", comment: ""), inViewController: self)

            }, completion: { success in
                println("sendImage to group: \(success)")
            })
        }
    }

    func sendVideoWithVideoURL(videoURL: NSURL) {

        // Prepare meta data

        var metaData: String? = nil

        var thumbnailData: NSData?

        if let image = thumbnailImageOfVideoInVideoURL(videoURL) {

            let imageWidth = image.size.width
            let imageHeight = image.size.height

            let thumbnailWidth: CGFloat
            let thumbnailHeight: CGFloat

            if imageWidth > imageHeight {
                thumbnailWidth = min(imageWidth, YepConfig.MetaData.thumbnailMaxSize)
                thumbnailHeight = imageHeight * (thumbnailWidth / imageWidth)
            } else {
                thumbnailHeight = min(imageHeight, YepConfig.MetaData.thumbnailMaxSize)
                thumbnailWidth = imageWidth * (thumbnailHeight / imageHeight)
            }

            let videoMetaDataInfo: [String: AnyObject]

            if let thumbnail = image.resizeToSize(CGSize(width: thumbnailWidth, height: thumbnailHeight), withInterpolationQuality: kCGInterpolationLow) {
                let blurredThumbnail = thumbnail.blurredImageWithRadius(5, iterations: 7, tintColor: UIColor.clearColor())

                let data = UIImageJPEGRepresentation(blurredThumbnail, 0.7)

                let string = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(0))

                print("video blurredThumbnail string length: \(string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))\n")

                videoMetaDataInfo = [
                    YepConfig.MetaData.videoWidth: imageWidth,
                    YepConfig.MetaData.videoHeight: imageHeight,
                    YepConfig.MetaData.blurredThumbnailString: string,
                ]

            } else {
                videoMetaDataInfo = [
                    YepConfig.MetaData.videoWidth: imageWidth,
                    YepConfig.MetaData.videoHeight: imageHeight,
                ]
            }

            if let videoMetaData = NSJSONSerialization.dataWithJSONObject(videoMetaDataInfo, options: nil, error: nil) {
                let videoMetaDataString = NSString(data: videoMetaData, encoding: NSUTF8StringEncoding) as? String
                metaData = videoMetaDataString
            }

            thumbnailData = UIImageJPEGRepresentation(image, YepConfig.messageImageCompressionQuality())
        }

        let messageVideoName = NSUUID().UUIDString

        let afterCreatedMessageAction = { [weak self] (message: Message) in

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
                            if let metaDataString = metaData {
                                message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                            }
                            realm.commitWrite()
                        }
                    }

                    self?.updateConversationCollectionViewWithMessageIDs(nil, scrollToBottom: true, success: { _ in
                    })
                }
            }
        }

        if let withFriend = conversation.withFriend {

            sendVideoInFilePath(videoURL.path!, orFileData: nil, metaData: metaData, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: afterCreatedMessageAction, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason, errorMessage)

                YepAlert.alertSorry(message: NSLocalizedString("Failed to send video!\nTry tap on message to resend.", comment: ""), inViewController: self)

            }, completion: { success in
                println("sendVideo to friend: \(success)")
            })

        } else if let withGroup = conversation.withGroup {

            sendVideoInFilePath(videoURL.path!, orFileData: nil, metaData: nil, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: afterCreatedMessageAction, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason, errorMessage)

                YepAlert.alertSorry(message: NSLocalizedString("Failed to send video!\nTry tap on message to resend.", comment: ""), inViewController: self)

            }, completion: { success in
                println("sendVideo to group: \(success)")
            })
        }
    }
}

