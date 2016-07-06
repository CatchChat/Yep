//
//  ConversationViewController.swift
//  Yep
//
//  Created by NIX on 15/3/23.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import YepKit
import YepNetworking
import AVFoundation
import MobileCoreServices.UTType
import MapKit
import Proposer
import KeyboardMan
import Navi
import MonkeyKing
import Ruler

final class ConversationViewController: BaseViewController {

    var conversation: Conversation!
    var conversationFeed: ConversationFeed?

    // for peek
    var isPreviewed: Bool = false
    
    var recipient: Recipient?

    var afterSentMessageAction: (() -> Void)?
    var afterDeletedFeedAction: ((feedID: String) -> Void)?
    var conversationDirtyAction: ((groupID: String) -> Void)?
    var conversationIsDirty = false
    var syncPlayFeedAudioAction: (() -> Void)?

    private var needDetectMention = false {
        didSet {
            messageToolbar.needDetectMention = needDetectMention
        }
    }

    var selectedIndexPathForMenu: NSIndexPath?

    var realm: Realm!

    var groupShareURLString: String?

    lazy var messages: Results<Message> = {
        return messagesOfConversation(self.conversation, inRealm: self.realm)
    }()

    var indexOfSearchedMessage: Int?
    let messagesBunchCount = 20 // TODO: 分段载入的“一束”消息的数量
    var displayedMessagesRange = NSRange() {
        didSet {
            needShowLoadPreviousSection = displayedMessagesRange.length >= messagesBunchCount
        }
    }
    private var needShowLoadPreviousSection: Bool = false {
        didSet {
            if needShowLoadPreviousSection != oldValue {
                //needReloadLoadPreviousSection = true
            }
        }
    }
    private var needReloadLoadPreviousSection: Bool = false

    // 上一次更新 UI 时的消息数
    var lastTimeMessagesCount: Int = 0

    // 位于后台时收到的消息
    private var inActiveNewMessageIDSet = Set<String>()

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

    var checkTypingStatusTimer: NSTimer?
    var typingResetDelay: Float = 0

    // KeyboardMan 帮助我们做键盘动画
    private let keyboardMan = KeyboardMan()
    private var giveUpKeyboardHideAnimationWhenViewControllerDisapeear = false

    private var isFirstAppear = true

    lazy var titleView: ConversationTitleView = {
        let titleView = self.makeTitleView()
        return titleView
    }()

    lazy var moreViewManager: ConversationMoreViewManager = {
        let manager = self.makeConversationMoreViewManager()
        return manager
    }()

    private lazy var moreMessageTypesView: MoreMessageTypesView = {
        let view = self.makeMoreMessageTypesView()
        return view
    }()

    private lazy var waverView: YepWaverView = {
        let view = self.makeWaverView()
        return view
    }()
    private var samplesCount = 0
    private let samplingInterval = 6

    var feedView: FeedView?
    var dragBeginLocation: CGPoint?

    var isSubscribeViewShowing = false
    lazy var subscribeView: SubscribeView = {
        let view = self.makeSubscribeView()
        return view
    }()

    private lazy var mentionView: MentionView = {
        let view = self.makeMentionView()
        return view
    }()

    let conversationCollectionViewContentInsetYOffset: CGFloat = 5
    @IBOutlet weak var conversationCollectionView: UICollectionView!

    @IBOutlet weak var messageToolbar: MessageToolbar!
    @IBOutlet private weak var messageToolbarBottomConstraint: NSLayoutConstraint! {
        didSet {
            messageToolbarBottomConstraint.constant = 0
        }
    }

    @IBOutlet private weak var swipeUpView: UIView! {
        didSet {
            swipeUpView.hidden = true
        }
    }
    @IBOutlet private weak var swipeUpPromptLabel: UILabel!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var isTryingShowFriendRequestView = false

    let sectionInsetTop: CGFloat = 10
    let sectionInsetBottom: CGFloat = 10

    private lazy var messageTextContentTextViewMaxWidth: CGFloat = {
        let maxWidth = self.collectionViewWidth - (YepConfig.chatCellGapBetweenWallAndAvatar() + YepConfig.chatCellAvatarSize() + YepConfig.chatCellGapBetweenTextContentLabelAndAvatar() + YepConfig.chatTextGapBetweenWallAndContentLabel())
        return maxWidth
    }()

    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.conversationCollectionView.bounds)
    }()

    let messageImagePreferredWidth = YepConfig.ChatCell.mediaPreferredWidth
    let messageImagePreferredHeight = YepConfig.ChatCell.mediaPreferredHeight
    let messageImagePreferredAspectRatio: CGFloat = 4.0 / 3.0

    lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        imagePicker.videoQuality = .TypeMedium
        imagePicker.allowsEditing = false
        return imagePicker
    }()

    #if DEBUG
    private lazy var conversationFPSLabel: FPSLabel = {
        let label = FPSLabel()
        return label
    }()
    #endif

    private struct Listener {
        static let Avatar = "ConversationViewController"
    }

    var previewTransitionViews: [UIView?]?
    var previewAttachmentPhotos: [PreviewAttachmentPhoto] = []
    var previewMessagePhotos: [PreviewMessagePhoto] = []

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)

        YepUserDefaults.avatarURLString.removeListenerWithName(Listener.Avatar)

        conversationCollectionView?.delegate = nil

        checkTypingStatusTimer?.invalidate()

        println("deinit ConversationViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = nil
        navigationItem.titleView = titleView
        view.tintAdjustmentMode = .Normal

        let moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_more"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ConversationViewController.moreAction(_:)))
        navigationItem.rightBarButtonItem = moreBarButtonItem

        realm = try! Realm()

        recipient = conversation.recipient

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

        navigationController?.interactivePopGestureRecognizer?.delaysTouchesBegan = false

        do {
            prepareConversationCollectionView()
            let tap = UITapGestureRecognizer(target: self, action: #selector(ConversationViewController.tapToCollapseMessageToolBar(_:)))
            conversationCollectionView.addGestureRecognizer(tap)
        }

        if let indexOfSearchedMessage = indexOfSearchedMessage {
            let fixedIndexOfSearchedMessage = max(0, indexOfSearchedMessage - Ruler.iPhoneVertical(5, 6, 8, 10).value)
            displayedMessagesRange = NSRange(location: fixedIndexOfSearchedMessage, length: messages.count - fixedIndexOfSearchedMessage)

        } else {
            if messages.count >= messagesBunchCount {
                displayedMessagesRange = NSRange(location: messages.count - messagesBunchCount, length: messagesBunchCount)
            } else {
                displayedMessagesRange = NSRange(location: 0, length: messages.count)
            }
        }

        lastTimeMessagesCount = messages.count

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationViewController.handleReceivedNewMessagesNotification(_:)), name: Config.Notification.newMessages, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationViewController.handleDeletedMessagesNotification(_:)), name: Config.Notification.deletedMessages, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationViewController.cleanForLogout(_:)), name: EditProfileViewController.Notification.Logout, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationViewController.handleApplicationDidBecomeActive(_:)), name: AppDelegate.Notification.applicationDidBecomeActive, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationViewController.didRecieveMenuWillShowNotification(_:)), name: UIMenuControllerWillShowMenuNotification, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationViewController.didRecieveMenuWillHideNotification(_:)), name: UIMenuControllerWillHideMenuNotification, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationViewController.messagesMarkAsReadByRecipient(_:)), name: Config.Message.Notification.MessageBatchMarkAsRead, object: nil)

        YepUserDefaults.avatarURLString.bindListener(Listener.Avatar) { [weak self] _ in
            SafeDispatch.async {
                self?.reloadConversationCollectionView()
            }
        }

        keyboardMan.animateWhenKeyboardAppear = { [weak self] appearPostIndex, keyboardHeight, keyboardHeightIncrement in

            guard self?.navigationController?.topViewController == self else {
                return
            }

            if let giveUp = self?.giveUpKeyboardHideAnimationWhenViewControllerDisapeear {

                if giveUp {
                    self?.giveUpKeyboardHideAnimationWhenViewControllerDisapeear = false
                    return
                }
            }

            //println("appear \(keyboardHeight), \(keyboardHeightIncrement)\n")

            if let strongSelf = self {

                let subscribeViewHeight = strongSelf.isSubscribeViewShowing ? SubscribeView.height : 0

                if strongSelf.messageToolbarBottomConstraint.constant > 0 {

                    // 注意第一次要减去已经有的高度偏移
                    if appearPostIndex == 0 {
                        strongSelf.conversationCollectionView.contentOffset.y += keyboardHeightIncrement //- strongSelf.moreMessageTypesViewDefaultHeight
                    } else {
                        strongSelf.conversationCollectionView.contentOffset.y += keyboardHeightIncrement
                    }

                    let bottom = keyboardHeight + strongSelf.messageToolbar.frame.height + subscribeViewHeight
                    strongSelf.conversationCollectionView.contentInset.bottom = bottom
                    strongSelf.conversationCollectionView.scrollIndicatorInsets.bottom = bottom

                    strongSelf.messageToolbarBottomConstraint.constant = keyboardHeight
                    strongSelf.view.layoutIfNeeded()

                } else {
                    strongSelf.conversationCollectionView.contentOffset.y += keyboardHeightIncrement
                    let bottom = keyboardHeight + strongSelf.messageToolbar.frame.height + subscribeViewHeight
                    strongSelf.conversationCollectionView.contentInset.bottom = bottom
                    strongSelf.conversationCollectionView.scrollIndicatorInsets.bottom = bottom

                    strongSelf.messageToolbarBottomConstraint.constant = keyboardHeight
                    strongSelf.view.layoutIfNeeded()
                }
            }
        }

        keyboardMan.animateWhenKeyboardDisappear = { [weak self] keyboardHeight in

            guard self?.navigationController?.topViewController == self else {
                return
            }

            if let nvc = self?.navigationController {
                if nvc.topViewController != self {
                    self?.giveUpKeyboardHideAnimationWhenViewControllerDisapeear = true
                    return
                }
            }

            //println("disappear \(keyboardHeight)\n")

            if let strongSelf = self {

                if strongSelf.messageToolbarBottomConstraint.constant > 0 {

                    strongSelf.conversationCollectionView.contentOffset.y -= keyboardHeight

                    let subscribeViewHeight = strongSelf.isSubscribeViewShowing ? SubscribeView.height : 0
                    let bottom = strongSelf.messageToolbar.frame.height + subscribeViewHeight
                    strongSelf.conversationCollectionView.contentInset.bottom = bottom
                    strongSelf.conversationCollectionView.scrollIndicatorInsets.bottom = bottom

                    strongSelf.messageToolbarBottomConstraint.constant = 0
                    strongSelf.view.layoutIfNeeded()
                }
            }
        }

        tryShowSubscribeView()

        needDetectMention = conversation.needDetectMention

        #if DEBUG
            //view.addSubview(conversationFPSLabel)
        #endif
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        trySyncMessages()

        if isFirstAppear {
            if let feed = conversation.withGroup?.withFeed {
                conversationFeed = ConversationFeed.FeedType(feed)
            }

            if let conversationFeed = conversationFeed {
                makeFeedViewWithFeed(conversationFeed)
                tryFoldFeedView()
            }

            // 为记录草稿准备

            messageToolbar.conversation = conversation

            // MARK: MessageToolbar MoreMessageTypes

            messageToolbar.moreMessageTypesAction = { [weak self] in

                if let window = self?.view.window {
                    self?.moreMessageTypesView.showInView(window)

                    if let state = self?.messageToolbar.state where !state.isAtBottom {
                        self?.messageToolbar.state = .Default
                    }

                    delay(0.2) {
                        self?.imagePicker.hidesBarsOnTap = false
                    }
                }
            }

            // MARK: MessageToolbar State Transitions

            messageToolbar.stateTransitionAction = { [weak self] (messageToolbar, previousState, currentState) in

                //println("messageToolbar.messageTextView.text 1: \(messageToolbar.messageTextView.text)")
                switch currentState {

                case .BeginTextInput:
                    self?.tryFoldFeedView()

                    self?.trySnapContentOfConversationCollectionViewToBottom(forceAnimation: true)

                case .TextInputing:
                    self?.trySnapContentOfConversationCollectionViewToBottom()

                default:
                    if self?.needDetectMention ?? false {
                        self?.mentionView.hide()
                    }

                    if previousState != .TextInputing {
                        if let
                            draft = self?.conversation.draft,
                            state = MessageToolbarState(rawValue: draft.messageToolbarState) {
                                messageToolbar.messageTextView.text = draft.text
                        }
                    }
                }

                if previousState != currentState {
                    //println("messageToolbar.messageTextView.text 2: \(messageToolbar.messageTextView.text)")
                    NSNotificationCenter.defaultCenter().postNotificationName(MessageToolbar.Notification.updateDraft, object: nil)
                }
            }

            // MARK: Mention

            if needDetectMention {

                messageToolbar.initMentionUserAction = { [weak self] in

                    let users = self?.conversation.mentionInitUsers ?? []

                    self?.mentionView.users = users

                    guard !users.isEmpty else {
                        self?.mentionView.hide()
                        return
                    }

                    self?.view.layoutIfNeeded()
                    self?.mentionView.show()
                }

                messageToolbar.tryMentionUserAction = { [weak self] usernamePrefix in

                    let usernamePrefix = usernamePrefix.yep_removeAllWhitespaces

                    guard !usernamePrefix.isEmpty else {
                        return
                    }

                    usersMatchWithUsernamePrefix(usernamePrefix, failureHandler: nil) { users in
                        SafeDispatch.async { [weak self] in

                            self?.mentionView.users = users

                            guard !users.isEmpty else {
                                self?.mentionView.hide()
                                return
                            }

                            self?.view.layoutIfNeeded()
                            self?.mentionView.show()
                        }
                    }
                }

                messageToolbar.giveUpMentionUserAction = { [weak self] in
                    self?.mentionView.hide()
                }
            }

            // 在这里才尝试恢复 messageToolbar 的状态，因为依赖 stateTransitionAction

            func tryRecoverMessageToolBar() {
                if let
                    draft = conversation.draft,
                    state = MessageToolbarState(rawValue: draft.messageToolbarState) {

                        if state == .TextInputing || state == .Default {
                            messageToolbar.messageTextView.text = draft.text
                        }

                        // 恢复时特别注意：因为键盘改由用户触发，因此
                        if state == .TextInputing || state == .BeginTextInput {
                            // 这两种状态时不恢复 messageToolbar.state
                            return
                        }

                        // 这句要放在最后，因为它会触发 stateTransitionAction
                        // 只恢复不改变高度的状态
                        if state == .VoiceRecord {
                            messageToolbar.state = state
                        }
                }
            }

            tryRecoverMessageToolBar()

            if isPreviewed {
                if conversationFeed != nil {
                    conversationCollectionView.contentInset.top = FeedView.foldHeight + conversationCollectionViewContentInsetYOffset
                } else {
                    conversationCollectionView.contentInset.top = conversationCollectionViewContentInsetYOffset
                }

                setConversaitonCollectionViewOriginalBottomContentInset()
            }
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        conversationCollectionViewHasBeenMovedToBottomOnce = true

        navigationController?.setNavigationBarHidden(false, animated: true)
        setNeedsStatusBarAppearanceUpdate()

        YepFayeService.sharedManager.delegate = self

        // 进来时就尽快标记已读

        delay(0.1) { [weak self] in
            self?.batchMarkMessagesAsReaded(updateOlderMessagesIfNeeded: true)

            guard let realm = self?.conversation.realm else { return }
            let _ = try? realm.write {
                self?.conversation.mentionedMe = false
            }
        }

        // MARK: Notify Typing

        // 为 nil 时才新建
        if checkTypingStatusTimer == nil {
            checkTypingStatusTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(ConversationViewController.checkTypingStatus(_:)), userInfo: nil, repeats: true)
        }

        // 尽量晚的设置一些属性和闭包

        if isFirstAppear {

            messageToolbar.notifyTypingAction = { [weak self] in

                self?.trySendInstantMessageWithType(.Text)
            }

            // MARK: Send Text

            messageToolbar.textSendAction = { [weak self] messageToolbar in

                let text = messageToolbar.messageTextView.text!.trimming(.WhitespaceAndNewline)

                self?.cleanTextInput()

                self?.trySnapContentOfConversationCollectionViewToBottom()

                if text.isEmpty {
                    return
                }

                if let withFriend = self?.conversation.withFriend {

                    println("try sendText to User: \(withFriend.userID)")
                    println("my userID: \(YepUserDefaults.userID.value)")

                    sendText(text, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { [weak self] message in

                        SafeDispatch.async {
                            self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                            })
                        }

                    }, failureHandler: { [weak self] reason, errorMessage in
                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                        self?.promptSendMessageFailed(
                            reason: reason,
                            errorMessage: errorMessage,
                            reserveErrorMessage: NSLocalizedString("Failed to send text!\nTry tap on message to resend.", comment: "")
                        )

                    }, completion: { success in
                        println("sendText to friend: \(success)")

                        // 发送过消息后才提示加好友
                        SafeDispatch.async { [weak self] in
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

                        SafeDispatch.async {
                            self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                            })
                        }

                    }, failureHandler: { [weak self] reason, errorMessage in
                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                        SafeDispatch.async {
                            YepAlert.alertSorry(message: NSLocalizedString("Failed to send text!\nTry tap on message to resend.", comment: ""), inViewController: self)
                        }

                    }, completion: { success in
                        println("sendText to group: \(success)")

                        SafeDispatch.async { [weak self] in
                            guard let strongSelf = self else {
                                return
                            }
                            guard !strongSelf.conversation.invalidated else {
                                return
                            }

                            guard let group = strongSelf.conversation.withGroup where !group.invalidated else {
                                return
                            }

                            _ = try? strongSelf.realm.write {
                                group.includeMe = true
                                group.conversation?.updatedUnixTime = NSDate().timeIntervalSince1970
                                strongSelf.moreViewManager.updateForGroupAffair()
                            }
                        }
                    })
                }

                if self?.needDetectMention ?? false {
                    self?.mentionView.hide()
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

                        let audioMetaDataInfo = [
                            Config.MetaData.audioDuration: audioDuration,
                            Config.MetaData.audioSamples: audioSamples,
                        ]

                        if let audioMetaData = try? NSJSONSerialization.dataWithJSONObject(audioMetaDataInfo, options: []) {
                            let audioMetaDataString = NSString(data: audioMetaData, encoding: NSUTF8StringEncoding) as? String
                            metaData = audioMetaDataString
                        }
                    }
                }

                // Do send

                if let fileURL = YepAudioService.sharedManager.audioFileURL {
                    if let withFriend = self?.conversation.withFriend {
                        sendAudioInFilePath(fileURL.path!, orFileData: nil, metaData: metaData, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { [weak self] message in

                            SafeDispatch.async {
                                if let realm = message.realm {
                                    let _ = try? realm.write {
                                        message.localAttachmentName = fileURL.URLByDeletingPathExtension?.lastPathComponent ?? ""
                                        message.mediaType = MessageMediaType.Audio.rawValue
                                        if let metaDataString = metaData {
                                            message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                                        }
                                    }

                                    self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                                    })
                                }
                            }

                        }, failureHandler: { [weak self] reason, errorMessage in
                            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                            self?.promptSendMessageFailed(
                                reason: reason,
                                errorMessage: errorMessage,
                                reserveErrorMessage: NSLocalizedString("Failed to send audio!\nTry tap on message to resend.", comment: "")
                            )

                        }, completion: { success in
                            println("send audio to friend: \(success)")
                        })

                    } else if let withGroup = self?.conversation.withGroup {
                        sendAudioInFilePath(fileURL.path!, orFileData: nil, metaData: metaData, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { [weak self] message in

                            SafeDispatch.async {
                                if let realm = message.realm {
                                    let _ = try? realm.write {
                                        message.localAttachmentName = fileURL.URLByDeletingPathExtension?.lastPathComponent ?? ""
                                        message.mediaType = MessageMediaType.Audio.rawValue
                                        if let metaDataString = metaData {
                                            message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                                        }
                                    }

                                    self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                                    })
                                }
                            }

                        }, failureHandler: { [weak self] reason, errorMessage in
                            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

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
                    strongSelf.view.bringSubviewToFront(strongSelf.messageToolbar)
                    strongSelf.view.bringSubviewToFront(strongSelf.moreMessageTypesView)

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

                    self?.trySendInstantMessageWithType(.Audio)
                }
            }

            messageToolbar.voiceRecordEndAction = { messageToolbar in

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
        }

        if !isFirstAppear {
            syncMessagesReadStatus()
        }

        isFirstAppear = false
    }

    private func batchMarkMessagesAsReaded(updateOlderMessagesIfNeeded updateOlderMessagesIfNeeded: Bool = true) {

        SafeDispatch.async { [weak self] in

            guard let strongSelf = self else {
                return
            }

            guard let recipient = strongSelf.recipient, latestMessage = strongSelf.messages.last else {
                return
            }

            var needMarkInServer = false

            if updateOlderMessagesIfNeeded {

                var predicate = NSPredicate(format: "readed = false", argumentArray: nil)
                //var predicate = NSPredicate(format: "readed = false AND fromFriend != nil AND fromFriend.friendState != %d", UserFriendState.Me.rawValue)

                if case .OneToOne = recipient.type {
                    predicate = NSPredicate(format: "readed = false AND fromFriend != nil AND fromFriend.friendState != %d", UserFriendState.Me.rawValue)
                }

                /*
                let hasUnread: Bool = messages.map({ !$0.readed }).reduce(false, combine: { return $0 || $1 })
                println("hasUnread: \(hasUnread)")

                messages.filter("readed = false").forEach {
                    println("unread message.textContent: \($0.textContent), \($0.fromFriend?.nickname)")
                }
                */

                let filteredMessages = strongSelf.messages.filter(predicate)

                println("filteredMessages.count: \(filteredMessages.count)")
                println("conversation.unreadMessagesCount: \(strongSelf.conversation.unreadMessagesCount)")

                needMarkInServer = (!filteredMessages.isEmpty || (strongSelf.conversation.unreadMessagesCount > 0))

                filteredMessages.forEach { message in
                    let _ = try? strongSelf.realm.write {
                        message.readed = true
                    }
                }

            } else {
                let _ = try? strongSelf.realm.write {
                    latestMessage.readed = true
                }

                needMarkInServer = true

                println("mark latestMessage readed")
            }

            // 群组里没有我，不需要标记
            if recipient.type == .Group {
                if let group = strongSelf.conversation.withGroup where !group.includeMe {

                    // 此情况强制所有消息“已读”
                    let _ = try? strongSelf.realm.write {
                        strongSelf.messages.forEach { message in
                            message.readed = true
                        }
                    }

                    needMarkInServer = false
                }
            }

            if needMarkInServer {

                SafeDispatch.async {
                    NSNotificationCenter.defaultCenter().postNotificationName(Config.Notification.markAsReaded, object: nil)
                }

                if latestMessage.isReal {
                    batchMarkAsReadOfMessagesToRecipient(recipient, beforeMessage: latestMessage, failureHandler: nil, completion: {
                        println("batchMarkAsReadOfMessagesToRecipient OK")
                    })

                } else {
                    println("not need batchMarkAsRead fake message")
                }

            } else {
                println("don't needMarkInServer")
            }
        }

        let _ = try? realm.write { [weak self] in
            self?.conversation.unreadMessagesCount = 0
            self?.conversation.hasUnreadMessages = false
            self?.conversation.mentionedMe = false
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        if conversationIsDirty {
            if let groupID = conversation.withGroup?.groupID {
                conversationDirtyAction?(groupID: groupID)
            }
        }

        checkTypingStatusTimer?.invalidate()

        NSNotificationCenter.defaultCenter().postNotificationName(MessageToolbar.Notification.updateDraft, object: nil)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        YepFayeService.sharedManager.delegate = nil
        checkTypingStatusTimer?.invalidate()
        checkTypingStatusTimer = nil // 及时释放

        waverView.removeFromSuperview()

        // stop audio playing if need

        if let audioPlayer = YepAudioService.sharedManager.audioPlayer {
            if audioPlayer.playing, let delegate = audioPlayer.delegate as? ConversationViewController where delegate == self {
                audioPlayer.stop()

                UIDevice.currentDevice().proximityMonitoringEnabled = false
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // 初始时移动一次到底部
        if !conversationCollectionViewHasBeenMovedToBottomOnce {

            // 先调整一下初次的 contentInset
            setConversaitonCollectionViewOriginalContentInset()

            if let indexOfSearchedMessage = indexOfSearchedMessage {
                let index = indexOfSearchedMessage - displayedMessagesRange.location

                if abs(index - displayedMessagesRange.length) > 3 {
                    let indexPath = NSIndexPath(forItem: index, inSection: Section.Message.rawValue)
                    conversationCollectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredVertically, animated: false)

                } else {
                    // 尽量滚到底部
                    tryScrollToBottom()
                }

            } else {
                // 尽量滚到底部
                tryScrollToBottom()
            }
        }
    }

    // MARK: UI

    func tryUpdateConversationCollectionViewWith(newContentInsetBottom bottom: CGFloat, newContentOffsetY: CGFloat) {

        guard newContentOffsetY + conversationCollectionView.contentInset.top > 0 else {
            conversationCollectionView.contentInset.bottom = bottom
            conversationCollectionView.scrollIndicatorInsets.bottom = bottom
            return
        }

        var needUpdate = false

        let bottomInsetOffset = bottom - conversationCollectionView.contentInset.bottom

        if bottomInsetOffset != 0 {
            needUpdate = true
        }

        if conversationCollectionView.contentOffset.y != newContentOffsetY {
            needUpdate = true
        }

        guard needUpdate else {
            return
        }

        conversationCollectionView.contentInset.bottom = bottom
        conversationCollectionView.scrollIndicatorInsets.bottom = bottom
        conversationCollectionView.contentOffset.y = newContentOffsetY
    }

    private func trySnapContentOfConversationCollectionViewToBottom(forceAnimation forceAnimation: Bool = false) {

        ///// Provent form unwanted scrolling
        if let lastToolbarFrame = messageToolbar.lastToolbarFrame {
            if lastToolbarFrame == messageToolbar.frame {
                return
            } else {
                messageToolbar.lastToolbarFrame = messageToolbar.frame
            }
        } else {
            messageToolbar.lastToolbarFrame = messageToolbar.frame
        }
        /////


        let subscribeViewHeight = isSubscribeViewShowing ? SubscribeView.height : 0

        let newContentOffsetY = conversationCollectionView.contentSize.height - messageToolbar.frame.origin.y + subscribeViewHeight

        let bottom = view.bounds.height - messageToolbar.frame.origin.y + subscribeViewHeight

        guard newContentOffsetY + conversationCollectionView.contentInset.top > 0 else {

            UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
                if let strongSelf = self {
                    strongSelf.conversationCollectionView.contentInset.bottom = bottom
                    strongSelf.conversationCollectionView.scrollIndicatorInsets.bottom = bottom
                }
            }, completion: { _ in })

            return
        }

        var needDoAnimation = forceAnimation

        let bottomInsetOffset = bottom - conversationCollectionView.contentInset.bottom

        if bottomInsetOffset != 0 {
            needDoAnimation = true
        }

        if conversationCollectionView.contentOffset.y != newContentOffsetY {
            needDoAnimation = true
        }

        guard needDoAnimation else {
            return
        }

        UIView.animateWithDuration(forceAnimation ? 0.25 : 0.1, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
            if let strongSelf = self {
                strongSelf.conversationCollectionView.contentInset.bottom = bottom
                strongSelf.conversationCollectionView.scrollIndicatorInsets.bottom = bottom
                strongSelf.conversationCollectionView.contentOffset.y = newContentOffsetY
            }
        }, completion: { _ in })
    }

    // MARK: Private

    private func setConversaitonCollectionViewOriginalBottomContentInset() {

        let messageToolbarHeight = messageToolbar.bounds.height
        conversationCollectionView.contentInset.bottom = messageToolbarHeight + sectionInsetBottom
        conversationCollectionView.scrollIndicatorInsets.bottom = messageToolbarHeight
    }

    private func setConversaitonCollectionViewOriginalContentInset() {

        let feedViewHeight: CGFloat = (feedView == nil) ? 0 : FeedView.foldHeight
        conversationCollectionView.contentInset.top = 64 + feedViewHeight + conversationCollectionViewContentInsetYOffset

        setConversaitonCollectionViewOriginalBottomContentInset()
    }

    private var messageHeights = [String: CGFloat]()
    func heightOfMessage(message: Message) -> CGFloat {

        let key = message.messageID

        if !key.isEmpty {
            if let messageHeight = messageHeights[key] {
                return messageHeight
            }
        }

        var height: CGFloat = 0

        switch message.mediaType {

        case MessageMediaType.Text.rawValue:

            if message.isIndicator {
                height = 26

            } else {
                let rect: CGRect
                if let _rect = ChatTextCellLayout.textContentTextViewFrameOfMessage(message) {
                    rect = _rect

                } else {
                    rect = message.textContent.boundingRectWithSize(CGSize(width: messageTextContentTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.ChatCell.textAttributes, context: nil)

                    ChatTextCellLayout.updateTextContentTextViewWidth(ceil(rect.width), forMessage: message)
                }

                height = max(ceil(rect.height) + (11 * 2), YepConfig.chatCellAvatarSize())

                if message.openGraphInfo != nil {
                    height += 100 + 10
                }
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

        case MessageMediaType.SocialWork.rawValue:
            height = 135
        
        case MessageMediaType.ShareFeed.rawValue:
            height = 60
        default:
            height = 20
        }

        // inGroup, plus height for show name
        if conversation.withGroup != nil {
            if message.mediaType != MessageMediaType.SectionDate.rawValue && !message.isIndicator {
                if let sender = message.fromFriend {
                    if sender.friendState != UserFriendState.Me.rawValue {
                        height += YepConfig.ChatCell.marginTopForGroup
                    }
                }
            }
        }

        if !key.isEmpty {
            messageHeights[key] = height
        }

        return height
    }
    func clearHeightOfMessageWithKey(key: String) {
        messageHeights[key] = nil
    }

    func chatTextCellLayoutCacheOfMessage(message: Message) -> ChatTextCellLayoutCache {

        let layoutCache = ChatTextCellLayout.layoutCacheOfMessage(message, textContentTextViewMaxWidth: messageTextContentTextViewMaxWidth)

        return layoutCache
    }

    private var audioPlayedDurations = [String: NSTimeInterval]()

    func audioPlayedDurationOfMessage(message: Message) -> NSTimeInterval {
        let key = message.messageID

        if !key.isEmpty {
            if let playedDuration = audioPlayedDurations[key] {
                return playedDuration
            }
        }

        return 0
    }

    func setAudioPlayedDuration(audioPlayedDuration: NSTimeInterval, ofMessage message: Message) {
        let key = message.messageID
        if !key.isEmpty {
            audioPlayedDurations[key] = audioPlayedDuration
        }

        // recover audio cells' UI

        if audioPlayedDuration == 0 {

            if let sender = message.fromFriend, index = messages.indexOf(message) {

                let indexPath = NSIndexPath(forItem: index - displayedMessagesRange.location, inSection: Section.Message.rawValue)

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

    var isLoadingPreviousMessages = false
    var noMorePreviousMessages = false

    private func trySendInstantMessageWithType(type: YepFayeService.InstantStateType) {

        guard YepFayeService.sharedManager.fayeClient.isConnected else {
            return
        }

        guard let _ = self.conversation.withFriend else {
            return
        }

        guard let recipient = self.recipient else {
            return
        }

        let instantMessage: JSONDictionary = [
            "state": type.rawValue,
            "recipient_type": recipient.type.nameForServer,
            "recipient_id": recipient.ID,
        ]

        YepFayeService.sharedManager.sendInstantMessage(instantMessage) { success in
            println("sendInstantMessage \(type) \(success)")
        }
    }

    // MARK: Actions

    @objc private func messagesMarkAsReadByRecipient(notification: NSNotification) {

        guard let
            messageDataInfo = notification.object as? [String: AnyObject],
            lastReadUnixTime = messageDataInfo["last_read_at"] as? NSTimeInterval,
            lastReadMessageID = messageDataInfo["last_read_id"] as? String,
            recipientType = messageDataInfo["recipient_type"] as? String,
            recipientID = messageDataInfo["recipient_id"] as? String else {
                return
        }

        /*
        println("lastReadMessageID: \(lastReadMessageID), \(lastReadUnixTime)")
        println("recipient_id: \(recipientID), \(recipientType)")
        println("recipient: \(recipient)")
         */

        if recipientID == recipient?.ID && recipientType == recipient?.type.nameForServer {
            markAsReadAllSentMesagesBeforeUnixTime(lastReadUnixTime, lastReadMessageID: lastReadMessageID)
        }
    }

    @objc private func tapToCollapseMessageToolBar(sender: UITapGestureRecognizer) {
        if selectedIndexPathForMenu == nil {
            if messageToolbar.state != .VoiceRecord {
                messageToolbar.state = .Default
            }
        }
    }

    @objc private func checkTypingStatus(sender: NSTimer) {

        typingResetDelay = typingResetDelay - 1

        if typingResetDelay < 0 {
            self.updateStateInfoOfTitleView(titleView)
        }
    }

    private func tryScrollToBottom() {

        if displayedMessagesRange.length > 0 {

            let messageToolBarTop = messageToolbarBottomConstraint.constant + CGRectGetHeight(messageToolbar.bounds)

            let feedViewHeight: CGFloat = (feedView == nil) ? 0 : FeedView.foldHeight
            let invisibleHeight = messageToolBarTop + topBarsHeight + feedViewHeight
            let visibleHeight = conversationCollectionView.frame.height - invisibleHeight

            let canScroll = visibleHeight <= conversationCollectionView.contentSize.height

            if canScroll {
                conversationCollectionView.contentOffset.y = conversationCollectionView.contentSize.height - conversationCollectionView.frame.size.height + messageToolBarTop
                conversationCollectionView.contentInset.bottom = messageToolBarTop
                conversationCollectionView.scrollIndicatorInsets.bottom = messageToolBarTop
            }
        }
    }

    @objc private func moreAction(sender: AnyObject) {

        messageToolbar.state = .Default

        if let window = view.window {
            moreViewManager.moreView.showInView(window)
        }
    }

    @objc private func handleReceivedNewMessagesNotification(notification: NSNotification) {

        guard let
            messagesInfo = notification.object as? [String: AnyObject],
            messageIDs = messagesInfo["messageIDs"] as? [String],
            messageAgeRawValue = messagesInfo["messageAge"] as? String,
            messageAge = MessageAge(rawValue: messageAgeRawValue) else {
                println("Can NOT handleReceivedNewMessagesNotification")
                return
        }

        handleRecievedNewMessages(messageIDs, messageAge: messageAge)
    }

    private func handleRecievedNewMessages(_messageIDs: [String], messageAge: MessageAge) {

        var messageIDs: [String]?

        //Make sure insert cell when in conversation viewcontroller
        guard let conversationController = self.navigationController?.visibleViewController as? ConversationViewController else {
            return
        }

        realm.refresh() // 确保是最新数据

        // 按照 conversation 过滤消息，匹配的才能考虑插入
        if let conversation = conversation {

            if let conversationID = conversation.fakeID, realm = conversation.realm, currentVisibleConversationID = conversationController.conversation.fakeID {

                if currentVisibleConversationID != conversationID {
                    return
                }

                var filteredMessageIDs = [String]()

                for messageID in _messageIDs {
                    if let message = messageWithMessageID(messageID, inRealm: realm) {
                        if let messageInConversationID = message.conversation?.fakeID {
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
            updateConversationCollectionViewWithMessageIDs(messageIDs, messageAge: messageAge, scrollToBottom: false, success: { _ in
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

    @objc private func handleDeletedMessagesNotification(notification: NSNotification) {

        defer {
            reloadConversationCollectionView()
        }

        guard let info = notification.object as? [String: AnyObject], messageIDs = info["messageIDs"] as? [String] else {
            return
        }

        messageIDs.forEach {
            clearHeightOfMessageWithKey($0)
        }
    }

    // App 进入前台时，根据通知插入处于后台状态时收到的消息

    @objc private func handleApplicationDidBecomeActive(notification: NSNotification) {

        guard UIApplication.sharedApplication().applicationState == .Active else {
            return
        }

        tryInsertInActiveNewMessages()

        trySyncMessages()
    }

    private func tryInsertInActiveNewMessages() {

        if inActiveNewMessageIDSet.count > 0 {
            updateConversationCollectionViewWithMessageIDs(Array(inActiveNewMessageIDSet), messageAge: .New, scrollToBottom: false, success: { _ in
            })

            inActiveNewMessageIDSet = []

            println("insert inActiveNewMessageIDSet to CollectionView")
        }
    }

    func updateConversationCollectionViewWithMessageIDs(messageIDs: [String]?, messageAge: MessageAge, scrollToBottom: Bool, success: (Bool) -> Void) {

        // 重要
        guard navigationController?.topViewController == self else { // 防止 pop/push 后，原来未释放的 VC 也执行这下面的代码
            return
        }

        if messageIDs != nil {
            batchMarkMessagesAsReaded()
        }

        let subscribeViewHeight = isSubscribeViewShowing ? SubscribeView.height : 0
        let keyboardAndToolBarHeight = messageToolbarBottomConstraint.constant + CGRectGetHeight(messageToolbar.bounds) + subscribeViewHeight

        adjustConversationCollectionViewWithMessageIDs(messageIDs, messageAge: messageAge, adjustHeight: keyboardAndToolBarHeight, scrollToBottom: scrollToBottom) { finished in
            success(finished)
        }

        if messageAge == .New {
            conversationIsDirty = true
        }

        if messageIDs == nil {
            afterSentMessageAction?()

            if isSubscribeViewShowing {

                realm.beginWrite()
                conversation.withGroup?.includeMe = true
                let _ = try? realm.commitWrite()

                delay(0.5) { [weak self] in
                    self?.subscribeView.hide()
                }

                moreViewManager.updateForGroupAffair()
            }
        }
    }

    private func adjustConversationCollectionViewWithMessageIDs(messageIDs: [String]?, messageAge: MessageAge, adjustHeight: CGFloat, scrollToBottom: Bool, success: (Bool) -> Void) {

        let _lastTimeMessagesCount = lastTimeMessagesCount
        lastTimeMessagesCount = messages.count

        // 保证是增加消息
        if messages.count <= _lastTimeMessagesCount {
            return
        }

        let newMessagesCount = Int(messages.count - _lastTimeMessagesCount)

        // 异常：两种计数不相等，治标：reload，避免插入
        if let messageIDs = messageIDs {
            if newMessagesCount != messageIDs.count {
                reloadConversationCollectionView()
                println("newMessagesCount != messageIDs.count")
                #if DEBUG
                    YepAlert.alertSorry(message: "请截屏报告!\nnewMessagesCount: \(newMessagesCount)\nmessageIDs.count: \(messageIDs.count)", inViewController: self)
                #endif
                return
            }
        }

        let lastDisplayedMessagesRange = displayedMessagesRange

        displayedMessagesRange.length += newMessagesCount

        let needReloadLoadPreviousSection = self.needReloadLoadPreviousSection

        if newMessagesCount > 0 {

            if let messageIDs = messageIDs {

                var indexPaths = [NSIndexPath]()

                for messageID in messageIDs {
                    if let
                        message = messageWithMessageID(messageID, inRealm: realm),
                        index = messages.indexOf(message) {
                        let indexPath = NSIndexPath(forItem: index - displayedMessagesRange.location, inSection: Section.Message.rawValue)
                        //println("insert item: \(indexPath.item), \(index), \(displayedMessagesRange.location)")

                        indexPaths.append(indexPath)

                    } else {
                        println("unknown message")

                        #if DEBUG
                            YepAlert.alertSorry(message: "unknown message: \(messageID)", inViewController: self)
                        #endif

                        reloadConversationCollectionView()
                        return
                    }
                }

                switch messageAge {

                case .New:
                    conversationCollectionView.performBatchUpdates({ [weak self] in
                        if needReloadLoadPreviousSection {
                            self?.conversationCollectionView.reloadSections(NSIndexSet(index: Section.LoadPrevious.rawValue))
                            self?.needReloadLoadPreviousSection = false
                        }

                        self?.conversationCollectionView.insertItemsAtIndexPaths(indexPaths)

                    }, completion: nil)

                case .Old:
                    // 用 CATransaction 保证 CollectionView 在插入后不闪动
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)

                    let bottomOffset = conversationCollectionView.contentSize.height - conversationCollectionView.contentOffset.y

                    conversationCollectionView.performBatchUpdates({ [weak self] in
                        if needReloadLoadPreviousSection {
                            self?.conversationCollectionView.reloadSections(NSIndexSet(index: Section.LoadPrevious.rawValue))
                            self?.needReloadLoadPreviousSection = false
                        }

                        self?.conversationCollectionView.insertItemsAtIndexPaths(indexPaths)

                    }, completion: { [weak self] finished in
                        if let strongSelf = self {
                            var contentOffset = strongSelf.conversationCollectionView.contentOffset
                            contentOffset.y = strongSelf.conversationCollectionView.contentSize.height - bottomOffset

                            strongSelf.conversationCollectionView.setContentOffset(contentOffset, animated: false)

                            CATransaction.commit()
                        }
                    })
                }

                println("insert other messages")

            } else {
                // 这里做了一个假设：本地刚创建的消息比所有的已有的消息都要新，这在创建消息里做保证（服务器可能传回创建在“未来”的消息）

                var indexPaths = [NSIndexPath]()

                for i in 0..<newMessagesCount {
                    let indexPath = NSIndexPath(forItem: lastDisplayedMessagesRange.length + i, inSection: Section.Message.rawValue)
                    indexPaths.append(indexPath)
                }

                conversationCollectionView.performBatchUpdates({ [weak self] in
                    if needReloadLoadPreviousSection {
                        self?.conversationCollectionView.reloadSections(NSIndexSet(index: Section.LoadPrevious.rawValue))
                        self?.needReloadLoadPreviousSection = false
                    }

                    self?.conversationCollectionView.insertItemsAtIndexPaths(indexPaths)

                }, completion: nil)

                println("insert self messages")
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

            let blockedHeight = topBarsHeight + (feedView != nil ? FeedView.foldHeight : 0) + keyboardAndToolBarHeight

            let visibleHeight = conversationCollectionView.frame.height - blockedHeight

            // cal the height can be used
            let useableHeight = visibleHeight - conversationCollectionView.contentSize.height

            if newMessagesTotalHeight > useableHeight {

                UIView.animateWithDuration(0.25, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { [weak self] in

                    if let strongSelf = self {

                        if scrollToBottom {
                            let newContentSize = strongSelf.conversationCollectionView.collectionViewLayout.collectionViewContentSize()
                            let newContentOffsetY = newContentSize.height - strongSelf.conversationCollectionView.frame.height + keyboardAndToolBarHeight
                            strongSelf.conversationCollectionView.contentOffset.y = newContentOffsetY

                        } else {
                            strongSelf.conversationCollectionView.contentOffset.y += newMessagesTotalHeight
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

    @objc private func reloadConversationCollectionView() {
        SafeDispatch.async {
            self.conversationCollectionView.reloadData()
        }
    }

    private func cleanTextInput() {
        messageToolbar.messageTextView.text = ""
        messageToolbar.state = .BeginTextInput
    }

    @objc private func cleanForLogout(sender: NSNotification) {
        displayedMessagesRange.length = 0
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        messageToolbar.state = .Default

        switch identifier {

        case "showProfileWithUsername":

            let vc = segue.destinationViewController as! ProfileViewController

            let profileUser = (sender as! Box<ProfileUser>).value
            vc.prepare(withProfileUser: profileUser)

            vc.fromType = .GroupConversation

        case "showProfileFromFeedView":

            let vc = segue.destinationViewController as! ProfileViewController

            if let user = feedView?.feed?.creator {
                vc.prepare(withUser: user)
            }

            vc.fromType = .GroupConversation

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

        case "showConversationWithFeed":

            let vc = segue.destinationViewController as! ConversationViewController

            guard let realm = try? Realm() else {
                return
            }

            let feed = (sender as! Box<DiscoveredFeed>).value

            realm.beginWrite()
            let feedConversation = vc.prepareConversationForFeed(feed, inRealm: realm)
            let _ = try? realm.commitWrite()

            vc.conversation = feedConversation
            vc.conversationFeed = ConversationFeed.DiscoveredFeedType(feed)

        case "presentNewFeed":

            guard let
                nvc = segue.destinationViewController as? UINavigationController,
                vc = nvc.topViewController as? NewFeedViewController
                else {
                    return
            }

            if let socialWork = sender as? MessageSocialWork {
                vc.attachment = .SocialWork(socialWork)

                vc.afterCreatedFeedAction = { [weak self] feed in

                    guard let type = MessageSocialWorkType(rawValue: socialWork.type), realm = socialWork.realm else {
                        return
                    }

                    let _ = try? realm.write {

                        switch type {

                        case .GithubRepo:
                            socialWork.githubRepo?.synced = true

                        case .DribbbleShot:
                            socialWork.dribbbleShot?.synced = true

                        case .InstagramMedia:
                            break
                        }
                    }

                    self?.reloadConversationCollectionView()
                }
            }

        case "presentPickLocation":

            let nvc = segue.destinationViewController as! UINavigationController
            let vc = nvc.topViewController as! PickLocationViewController

            vc.sendLocationAction = { [weak self] locationInfo in

                if let user = self?.conversation.withFriend {
                    self?.sendLocationInfo(locationInfo, toUser: user)

                } else if let group = self?.conversation.withGroup {
                    self?.sendLocationInfo(locationInfo, toGroup: group)
                }
            }

        default:
            break
        }
    }
}

