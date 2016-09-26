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
import YepPreview
import AVFoundation
import MobileCoreServices.UTType
import MapKit
import Proposer
import KeyboardMan
import Navi
import MonkeyKing
import Ruler
import AudioBot

final class ConversationViewController: BaseViewController {

    var conversation: Conversation!
    var conversationFeed: ConversationFeed?

    var realm: Realm!
    var recipient: Recipient!

    // for peek
    var isPreviewed: Bool = false

    var afterSentMessageAction: (() -> Void)?
    var afterDeletedFeedAction: ((_ feedID: String) -> Void)?
    var conversationDirtyAction: ((_ groupID: String) -> Void)?
    var conversationIsDirty = false
    var syncPlayFeedAudioAction: (() -> Void)?

    var needDetectMention = false {
        didSet {
            messageToolbar.needDetectMention = needDetectMention
        }
    }

    var selectedIndexPathForMenu: IndexPath?

    var groupShareURLString: String?

    lazy var messages: Results<Message> = {
        return messagesOfConversation(self.conversation, inRealm: self.realm)
    }()

    internal fileprivate(set) var messagesUpdatedVersion = 0
    fileprivate var messagesNotificationToken: NotificationToken?

    var indexOfSearchedMessage: Int?
    let messagesBunchCount = 20 // 分段载入的“一束”消息的数量
    var displayedMessagesRange = NSRange()

    fileprivate var needReloadLoadPreviousSection: Bool = false

    // 上一次更新 UI 时的消息数
    var lastTimeMessagesCount: Int = 0

    // 位于后台时收到的消息
    fileprivate var inactiveNewMessageIDSet = Set<String>()

    var conversationCollectionViewHasBeenMovedToBottomOnce = false

    var checkTypingStatusTimer: Timer?
    var typingResetDelay: Float = 0

    // KeyboardMan 帮助我们做键盘动画
    fileprivate let keyboardMan = KeyboardMan()
    fileprivate var giveUpKeyboardHideAnimationWhenViewControllerDisapeear = false

    fileprivate var isFirstAppear = true

    lazy var titleView: ConversationTitleView = {
        let titleView = self.makeTitleView()
        return titleView
    }()

    lazy var moreViewManager: ConversationMoreViewManager = {
        let manager = self.makeConversationMoreViewManager()
        return manager
    }()

    fileprivate lazy var moreMessageTypesView: MoreMessageTypesView = {
        let view = self.makeMoreMessageTypesView()
        return view
    }()

    lazy var waverView: YepWaverView = {
        let view = self.makeWaverView()
        return view
    }()

    var feedView: FeedView?
    var dragBeginLocation: CGPoint?

    var isSubscribeViewShowing = false
    lazy var subscribeView: SubscribeView = {
        let view = self.makeSubscribeView()
        return view
    }()

    lazy var mentionView: MentionView = {
        let view = self.makeMentionView()
        return view
    }()

    let conversationCollectionViewContentInsetYOffset: CGFloat = 5
    @IBOutlet weak var conversationCollectionView: UICollectionView!

    @IBOutlet weak var messageToolbar: MessageToolbar!
    @IBOutlet fileprivate weak var messageToolbarBottomConstraint: NSLayoutConstraint! {
        didSet {
            messageToolbarBottomConstraint.constant = 0
        }
    }

    fileprivate lazy var swipeUpPromptView: SwipeUpPromptView = {
        let view = SwipeUpPromptView()

        self.view.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.heightAnchor.constraint(equalToConstant: 100).isActive = true
        view.leadingAnchor.constraint(equalTo: self.messageToolbar.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: self.messageToolbar.trailingAnchor).isActive = true
        self.messageToolbar.topAnchor.constraint(equalTo: view.bottomAnchor, constant: 20).isActive = true

        return view
    }()

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var isTryingShowFriendRequestView = false

    let sectionInsetTop: CGFloat = 10
    let sectionInsetBottom: CGFloat = 10

    fileprivate lazy var messageTextContentTextViewMaxWidth: CGFloat = {
        let maxWidth = self.collectionViewWidth - (YepConfig.chatCellGapBetweenWallAndAvatar() + YepConfig.chatCellAvatarSize() + YepConfig.chatCellGapBetweenTextContentLabelAndAvatar() + YepConfig.chatTextGapBetweenWallAndContentLabel())
        return maxWidth
    }()

    lazy var collectionViewWidth: CGFloat = {
        return self.conversationCollectionView.bounds.width
    }()

    lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        imagePicker.videoQuality = .typeMedium
        imagePicker.allowsEditing = false
        return imagePicker
    }()

    #if DEBUG
    private lazy var conversationFPSLabel: FPSLabel = {
        let label = FPSLabel()
        return label
    }()
    #endif

    fileprivate struct Listener {
        static let Avatar = "ConversationViewController"
    }

    var previewReferences: [Reference?]?
    var previewAttachmentPhotos: [PreviewAttachmentPhoto] = []
    var previewMessagePhotos: [PreviewMessagePhoto] = []

    deinit {
        NotificationCenter.default.removeObserver(self)

        YepUserDefaults.avatarURLString.removeListenerWithName(Listener.Avatar)

        conversationCollectionView?.delegate = nil

        checkTypingStatusTimer?.invalidate()

        messagesNotificationToken?.stop()

        println("deinit ConversationViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = nil
        navigationItem.titleView = titleView
        view.tintAdjustmentMode = .normal

        let moreBarButtonItem = UIBarButtonItem(image: UIImage.yep_iconMore, style: UIBarButtonItemStyle.plain, target: self, action: #selector(ConversationViewController.moreAction(_:)))
        navigationItem.rightBarButtonItem = moreBarButtonItem

        realm = conversation.realm

        recipient = conversation.recipient

        // 优先处理侧滑，而不是 scrollView 的上下滚动，避免出现你想侧滑返回的时候，结果触发了 scrollView 的上下滚动
        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self) {
                    conversationCollectionView.panGestureRecognizer.require(toFail: recognizer as! UIScreenEdgePanGestureRecognizer)
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

                // preload some old messages if can
                if displayedMessagesRange.length == 1 {
                    if let maxMessageID = messages.first?.messageID {
                        let timeDirection: TimeDirection = .past(maxMessageID: maxMessageID)
                        loadMessagesFromServer(with: timeDirection) { [weak self] (messageIDs, noMore) in
                            self?.noMorePreviousMessages = noMore

                            if !messageIDs.isEmpty {
                                tryPostNewMessagesReceivedNotificationWithMessageIDs(messageIDs, messageAge: timeDirection.messageAge)
                                _ = delay(0.25) { [weak self] in
                                    self?.trySnapContentOfConversationCollectionViewToBottom(forceAnimation: true)
                                }
                            }
                        }
                    }
                }
            }
        }

        lastTimeMessagesCount = messages.count

        NotificationCenter.default.addObserver(self, selector: #selector(ConversationViewController.handleReceivedNewMessagesNotification(_:)), name: Config.NotificationName.newMessages, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ConversationViewController.handleDeletedMessagesNotification(_:)), name: Config.NotificationName.deletedMessages, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ConversationViewController.cleanForLogout(_:)), name: YepConfig.NotificationName.logout, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ConversationViewController.handleApplicationDidBecomeActive(_:)), name: YepConfig.NotificationName.applicationDidBecomeActive, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ConversationViewController.didRecieveMenuWillShowNotification(_:)), name: Notification.Name.UIMenuControllerWillShowMenu, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ConversationViewController.didRecieveMenuWillHideNotification(_:)), name: Notification.Name.UIMenuControllerWillHideMenu, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ConversationViewController.messagesMarkAsReadByRecipient(_:)), name: Config.NotificationName.messageBatchMarkAsRead, object: nil)

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

        let job = FreeTimeJob(target: self, selector: #selector(ConversationViewController.prepareHeightOfMessagesInFreeTime))
        job.commit()

        messagesNotificationToken = messages.addNotificationBlock({ [weak self] (change: RealmCollectionChange) in
            guard let strongSelf = self else { return }
            switch change {
            case .initial:
                strongSelf.messagesUpdatedVersion = 0
             case .update(_, let deletions, let insertions, _):
                let x = (deletions.isEmpty && insertions.isEmpty) ? 0 : 1
                strongSelf.messagesUpdatedVersion += x
            case .error:
                strongSelf.reloadConversationCollectionView()
            }
        })

        #if DEBUG
            //view.addSubview(conversationFPSLabel)
        #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        trySyncMessages()

        if isFirstAppear {
            if let feed = conversation.withGroup?.withFeed {
                conversationFeed = ConversationFeed.feedType(feed)
            }

            if let conversationFeed = conversationFeed {
                self.feedView = makeFeedView(for: conversationFeed)
                tryFoldFeedView()
            }

            // 为记录草稿准备

            messageToolbar.conversation = conversation

            // MARK: MessageToolbar MoreMessageTypes

            messageToolbar.moreMessageTypesAction = { [weak self] in

                if let window = self?.view.window {
                    self?.moreMessageTypesView.showInView(window)

                    if let state = self?.messageToolbar.state , !state.isAtBottom {
                        self?.messageToolbar.state = .default
                    }

                    _ = delay(0.2) {
                        self?.imagePicker.hidesBarsOnTap = false
                    }
                }
            }

            // MARK: MessageToolbar State Transitions

            messageToolbar.stateTransitionAction = { [weak self] (messageToolbar, previousState, currentState) in

                //println("messageToolbar.messageTextView.text 1: \(messageToolbar.messageTextView.text)")
                switch currentState {

                case .beginTextInput:
                    self?.tryFoldFeedView()

                    self?.trySnapContentOfConversationCollectionViewToBottom(forceAnimation: true)

                case .textInputing:
                    self?.trySnapContentOfConversationCollectionViewToBottom()

                default:
                    if self?.needDetectMention ?? false {
                        self?.mentionView.hide()
                    }

                    if previousState != .textInputing {
                        if let
                            draft = self?.conversation.draft,
                            let state = MessageToolbarState(rawValue: draft.messageToolbarState) {
                                messageToolbar.messageTextView.text = draft.text
                        }
                    }
                }

                if previousState != currentState {
                    //println("messageToolbar.messageTextView.text 2: \(messageToolbar.messageTextView.text)")
                    NotificationCenter.default.post(name: YepConfig.NotificationName.updateDraftOfConversation, object: nil)
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
                    let state = MessageToolbarState(rawValue: draft.messageToolbarState) {

                        if state == .textInputing || state == .default {
                            messageToolbar.messageTextView.text = draft.text
                        }

                        // 恢复时特别注意：因为键盘改由用户触发，因此
                        if state == .textInputing || state == .beginTextInput {
                            // 这两种状态时不恢复 messageToolbar.state
                            return
                        }

                        // 这句要放在最后，因为它会触发 stateTransitionAction
                        // 只恢复不改变高度的状态
                        if state == .voiceRecord {
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        conversationCollectionViewHasBeenMovedToBottomOnce = true

        navigationController?.setNavigationBarHidden(false, animated: true)
        setNeedsStatusBarAppearanceUpdate()

        YepFayeService.sharedManager.delegate = self

        // 进来时就尽快标记已读

        _ = delay(0.1) { [weak self] in
            self?.batchMarkMessagesAsReaded(updateOlderMessagesIfNeeded: true)

            guard let realm = self?.conversation.realm else { return }
            let _ = try? realm.write {
                self?.conversation.mentionedMe = false
            }
        }

        // MARK: Notify Typing

        // 为 nil 时才新建
        if checkTypingStatusTimer == nil {
            checkTypingStatusTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ConversationViewController.checkTypingStatus(_:)), userInfo: nil, repeats: true)
        }

        // 尽量晚的设置一些属性和闭包

        if isFirstAppear {

            messageToolbar.notifyTypingAction = { [weak self] in

                self?.trySendInstantMessageWithType(.text)
            }

            // MARK: Send Text

            messageToolbar.textSendAction = { [weak self] messageToolbar in

                let text = messageToolbar.messageTextView.text!.trimming(.whitespaceAndNewline)
                self?.cleanTextInput()
                self?.trySnapContentOfConversationCollectionViewToBottom()
                self?.sendText(text)
            }

            // MARK: Voice Record

            let hideWaver: () -> Void = { [weak self] in

                self?.swipeUpPromptView.isHidden = true
                self?.waverView.removeFromSuperview()
            }

            let stopRecordAndSendAudio: () -> Void = {

                AudioBot.stopRecord { [weak self] fileURL, duration, decibelSamples in

                    guard duration > YepConfig.AudioRecord.shortestDuration else {
                        return
                    }

                    let compressedDecibelSamples = AudioBot.compressDecibelSamples(decibelSamples, withSamplingInterval: 6, minNumberOfDecibelSamples: 20, maxNumberOfDecibelSamples: 60)
                    self?.sendAudio(at: fileURL, with: compressedDecibelSamples)
                }
            }

            messageToolbar.voiceRecordBeginAction = { [weak self] _ in

                proposeToAccess(.microphone, agreed: { [weak self] in

                    SafeDispatch.async { [weak self] in
                        guard let strongSelf = self else { return }

                        strongSelf.view.addSubview(strongSelf.waverView)

                        strongSelf.swipeUpPromptView.text = NSLocalizedString("Swipe Up to Cancel", comment: "")
                        strongSelf.swipeUpPromptView.isHidden = false

                        strongSelf.view.bringSubview(toFront: strongSelf.swipeUpPromptView)
                        strongSelf.view.bringSubview(toFront: strongSelf.messageToolbar)
                        strongSelf.view.bringSubview(toFront: strongSelf.moreMessageTypesView)

                        strongSelf.waverView.waver.resetWaveSamples()
                    }

                    do {
                        self?.waverView.waver.waverCallback = { _ in
                        }

                        let decibelSamplePeriodicReport: AudioBot.PeriodicReport = (reportingFrequency: 60, report: { decibelSample in

                            SafeDispatch.async { [weak self] in
                                self?.waverView.waver.level = CGFloat(decibelSample)
                            }
                        })

                        AudioBot.mixWithOthersWhenRecording = true

                        try AudioBot.startRecordAudioToFileURL(nil, forUsage: .normal, withDecibelSamplePeriodicReport: decibelSamplePeriodicReport)

                        AudioBot.reportRecordingDuration = { duration in

                            if duration > YepConfig.AudioRecord.longestDuration {
                                hideWaver()

                                stopRecordAndSendAudio()
                            }
                        }
                        
                        self?.trySendInstantMessageWithType(.audio)
                        
                    } catch let error {
                        println("record error: \(error)")
                    }

                }, rejected: { [weak self] in
                    self?.alertCanNotAccessMicrophone()
                })

                self?.trySendInstantMessageWithType(.audio)
            }

            messageToolbar.voiceRecordEndAction = { _ in

                hideWaver()

                stopRecordAndSendAudio()
            }

            messageToolbar.voiceRecordCancelAction = { _ in

                hideWaver()

                AudioBot.stopRecord { _, _, _ in
                    println("voiceRecordCancelAction")
                }
            }

            messageToolbar.voiceRecordingUpdateUIAction = { [weak self] topOffset in

                let text: String

                if topOffset > 40 {
                    text = NSLocalizedString("Release to Cancel", comment: "")
                } else {
                    text = NSLocalizedString("Swipe Up to Cancel", comment: "")
                }

                self?.swipeUpPromptView.text = text
            }
        }

        if !isFirstAppear {
            syncMessagesReadStatus()
        }

        isFirstAppear = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if conversationIsDirty && !conversation.isInvalidated {
            if let groupID = conversation.withGroup?.groupID {
                conversationDirtyAction?(groupID)
            }
        }

        checkTypingStatusTimer?.invalidate()

        NotificationCenter.default.post(name: YepConfig.NotificationName.updateDraftOfConversation, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        YepFayeService.sharedManager.delegate = nil
        checkTypingStatusTimer?.invalidate()
        checkTypingStatusTimer = nil // 及时释放

        waverView.removeFromSuperview()

        // stop audio playing if need

        if let audioPlayer = YepAudioService.sharedManager.audioPlayer {
            if audioPlayer.isPlaying, let delegate = audioPlayer.delegate as? ConversationViewController , delegate == self {
                audioPlayer.stop()

                UIDevice.current.isProximityMonitoringEnabled = false
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
                    let indexPath = IndexPath(item: index, section: Section.message.rawValue)
                    conversationCollectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)

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

    // MARK: - Preview Actions

    override var previewActionItems : [UIPreviewActionItem] {

        guard let group = conversation.withGroup , !group.includeMe else {
            return []
        }

        let groupID = group.groupID

        let subscribeAction = UIPreviewAction(title: NSLocalizedString("Subscribe", comment: ""), style: .default) { (action, previewViewController) in

            joinGroup(groupID: groupID, failureHandler: nil, completion: { [weak self] in
                println("subscribe OK")

                self?.updateGroupToIncludeMe() {
                    SafeDispatch.async { [weak self] in
                        guard let strongSelf = self else { return }
                        if strongSelf.isSubscribeViewShowing {
                            strongSelf.subscribeView.hide()
                        }
                    }
                }
            })
        }

        return [subscribeAction]
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let identifier = segue.identifier else {
            return
        }

        messageToolbar.state = .default

        switch identifier {

        case "showProfileWithUsername":

            let vc = segue.destination as! ProfileViewController

            let profileUser = (sender as! Box<ProfileUser>).value
            vc.prepare(withProfileUser: profileUser)

            vc.fromType = .groupConversation

        case "showProfileFromFeedView":

            let vc = segue.destination as! ProfileViewController

            if let user = feedView?.feed?.creator {
                vc.prepare(withUser: user)
            }

            vc.fromType = .groupConversation

        case "showProfile":

            let vc = segue.destination as! ProfileViewController

            if let user = sender as? User {
                vc.prepare(withUser: user)

            } else {
                if let withFriend = conversation?.withFriend {
                    vc.prepare(withUser: withFriend)
                }
            }

            switch conversation.type {
            case ConversationType.oneToOne.rawValue:
                vc.fromType = .oneToOneConversation
            case ConversationType.group.rawValue:
                vc.fromType = .groupConversation
            default:
                break
            }

        case "showConversationWithFeed":

            let vc = segue.destination as! ConversationViewController

            guard let realm = try? Realm() else {
                return
            }

            let feed = (sender as! Box<DiscoveredFeed>).value

            realm.beginWrite()
            let feedConversation = vc.prepareConversation(for: feed, in: realm)
            let _ = try? realm.commitWrite()

            vc.conversation = feedConversation
            vc.conversationFeed = ConversationFeed.discoveredFeedType(feed)

        case "presentNewFeed":

            guard let
                nvc = segue.destination as? UINavigationController,
                let vc = nvc.topViewController as? NewFeedViewController
                else {
                    return
            }

            if let socialWork = sender as? MessageSocialWork {
                vc.attachment = .socialWork(socialWork)

                vc.afterCreatedFeedAction = { [weak self] feed in

                    guard let type = MessageSocialWorkType(rawValue: socialWork.type), let realm = socialWork.realm else {
                        return
                    }

                    let _ = try? realm.write {

                        switch type {

                        case .githubRepo:
                            socialWork.githubRepo?.synced = true

                        case .dribbbleShot:
                            socialWork.dribbbleShot?.synced = true

                        case .instagramMedia:
                            break
                        }
                    }

                    self?.reloadConversationCollectionView()
                }
            }

        case "presentPickLocation":

            let nvc = segue.destination as! UINavigationController
            let vc = nvc.topViewController as! PickLocationViewController

            vc.sendLocationAction = { [weak self] locationInfo in
                self?.sendLocation(with: locationInfo)
            }

        default:
            break
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

    fileprivate func trySnapContentOfConversationCollectionViewToBottom(forceAnimation: Bool = false) {

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

            UIView.animate(withDuration: 0.1, delay: 0.0, options: UIViewAnimationOptions(), animations: { [weak self] in
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

        UIView.animate(withDuration: forceAnimation ? 0.25 : 0.1, delay: 0.0, options: UIViewAnimationOptions(), animations: { [weak self] in
            if let strongSelf = self {
                strongSelf.conversationCollectionView.contentInset.bottom = bottom
                strongSelf.conversationCollectionView.scrollIndicatorInsets.bottom = bottom
                strongSelf.conversationCollectionView.contentOffset.y = newContentOffsetY
            }
        }, completion: { _ in })
    }

    // MARK: After send message

    func showFriendRequestViewIfNeed() {

        SafeDispatch.async { [weak self] in
            if let strongSelf = self {
                if !strongSelf.isTryingShowFriendRequestView {
                    strongSelf.isTryingShowFriendRequestView = true
                    strongSelf.tryShowFriendRequestView()
                }
            }
        }
    }

    func updateGroupToIncludeMe(_ finish: (() -> Void)? = nil) {

        SafeDispatch.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            guard !strongSelf.conversation.isInvalidated else {
                return
            }
            guard let group = strongSelf.conversation.withGroup, !group.isInvalidated else {
                return
            }

            _ = try? strongSelf.realm.write {
                group.includeMe = true
                group.conversation?.updatedUnixTime = NSDate().timeIntervalSince1970
            }

            NotificationCenter.default.post(name: Config.NotificationName.changedConversation, object: nil)

            strongSelf.moreViewManager.updateForGroupAffair()

            finish?()
        }
    }

    // MARK: Private

    fileprivate func setConversaitonCollectionViewOriginalBottomContentInset() {

        let messageToolbarHeight = messageToolbar.bounds.height
        conversationCollectionView.contentInset.bottom = messageToolbarHeight + sectionInsetBottom
        conversationCollectionView.scrollIndicatorInsets.bottom = messageToolbarHeight
    }

    fileprivate func setConversaitonCollectionViewOriginalContentInset() {

        let feedViewHeight: CGFloat = (feedView == nil) ? 0 : FeedView.foldHeight
        conversationCollectionView.contentInset.top = 64 + feedViewHeight + conversationCollectionViewContentInsetYOffset

        setConversaitonCollectionViewOriginalBottomContentInset()
    }

    fileprivate var messageHeights = [String: CGFloat]()

    func heightOfMessage(_ message: Message) -> CGFloat {

        let key = message.messageID

        if !key.isEmpty {
            if let messageHeight = messageHeights[key] {
                return messageHeight
            }
        }

        var height: CGFloat = 0

        switch message.mediaType {

        case MessageMediaType.text.rawValue:

            if message.isIndicator {
                height = 26

            } else {
                let rect: CGRect
                if let _rect = ChatTextCellLayout.textContentTextViewFrameOfMessage(message) {
                    rect = _rect

                } else {
                    rect = message.textContent.boundingRect(with: CGSize(width: messageTextContentTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: YepConfig.ChatCell.textAttributes, context: nil)

                    ChatTextCellLayout.updateTextContentTextViewWidth(ceil(rect.width), forMessage: message)
                }

                height = max(ceil(rect.height) + (11 * 2), YepConfig.chatCellAvatarSize())

                if message.openGraphInfo != nil {
                    height += 100 + 10
                }
            }

        case MessageMediaType.image.rawValue:
            height = ceil(message.fixedImageSize.height)

        case MessageMediaType.audio.rawValue:
            height = 40

        case MessageMediaType.video.rawValue:
            height = ceil(message.fixedVideoSize.height)

        case MessageMediaType.location.rawValue:
            height = 108

        case MessageMediaType.sectionDate.rawValue:
            height = 20

        case MessageMediaType.socialWork.rawValue:
            height = 135
        
        case MessageMediaType.shareFeed.rawValue:
            height = 60

        default:
            height = 20
        }

        // inGroup, plus height for show name
        if conversation.withGroup != nil {
            if message.mediaType != MessageMediaType.sectionDate.rawValue && !message.isIndicator {
                if let sender = message.fromFriend {
                    if sender.friendState != UserFriendState.me.rawValue {
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

    func clearHeightOfMessageWithKey(_ key: String) {
        messageHeights[key] = nil
    }

    @objc fileprivate func prepareHeightOfMessagesInFreeTime() {

        messages.reversed().forEach({
            _ = heightOfMessage($0)
        })
    }

    func chatTextCellLayoutCacheOfMessage(_ message: Message) -> ChatTextCellLayoutCache {

        let layoutCache = ChatTextCellLayout.layoutCacheOfMessage(message, textContentTextViewMaxWidth: messageTextContentTextViewMaxWidth)

        return layoutCache
    }

    fileprivate var audioPlayedDurations = [String: TimeInterval]()

    func audioPlayedDurationOfMessage(_ message: Message) -> TimeInterval {
        let key = message.messageID

        if !key.isEmpty {
            if let playedDuration = audioPlayedDurations[key] {
                return playedDuration
            }
        }

        return 0
    }

    func setAudioPlayedDuration(_ audioPlayedDuration: TimeInterval, ofMessage message: Message) {

        let key = message.messageID
        if !key.isEmpty {
            audioPlayedDurations[key] = audioPlayedDuration
        }

        // recover audio cells' UI

        if audioPlayedDuration == 0 {

            if let sender = message.fromFriend, let index = messages.index(of: message) {

                let indexPath = IndexPath(item: index - displayedMessagesRange.location, section: Section.message.rawValue)

                if sender.friendState != UserFriendState.me.rawValue { // from Friend
                    if let cell = conversationCollectionView.cellForItem(at: indexPath) as? ChatLeftAudioCell {
                        cell.audioPlayedDuration = 0
                    }

                } else {
                    if let cell = conversationCollectionView.cellForItem(at: indexPath) as? ChatRightAudioCell {
                        cell.audioPlayedDuration = 0
                    }
                }
            }
        }
    }

    var isLoadingPreviousMessages = false
    var noMorePreviousMessages = false {
        didSet {
            if noMorePreviousMessages {
                SafeDispatch.async { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.realm.beginWrite()
                    strongSelf.conversation.hasOlderMessages = false
                    _ = try? strongSelf.realm.commitWrite()
                }
            }
        }
    }

    fileprivate func trySendInstantMessageWithType(_ type: YepFayeService.InstantStateType) {

        guard YepFayeService.sharedManager.fayeClient.isConnected else {
            return
        }
        guard recipient.type == .oneToOne else {
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

    @objc fileprivate func messagesMarkAsReadByRecipient(_ notification: Notification) {

        guard let lastRead = (notification.object as? Box<LastRead>)?.value else {
            println("Error: messagesMarkAsReadByRecipient: \(notification.object)")
            return
        }

        guard lastRead.recipient == recipient else {
            return
        }

        markAsReadAllSentMesagesBeforeUnixTime(lastRead.atUnixTime, lastReadMessageID: lastRead.messageID)
    }

    @objc fileprivate func tapToCollapseMessageToolBar(_ sender: UITapGestureRecognizer) {
        if selectedIndexPathForMenu == nil {
            if messageToolbar.state != .voiceRecord {
                messageToolbar.state = .default
            }
        }
    }

    @objc fileprivate func checkTypingStatus(_ sender: Timer) {

        typingResetDelay = typingResetDelay - 1

        if typingResetDelay < 0 {
            self.updateStateInfoOfTitleView(titleView)
        }
    }

    fileprivate func tryScrollToBottom() {

        if displayedMessagesRange.length > 0 {

            let messageToolBarTop = messageToolbarBottomConstraint.constant + messageToolbar.bounds.height

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

    @objc fileprivate func moreAction(_ sender: AnyObject) {

        messageToolbar.state = .default

        if let window = view.window {
            moreViewManager.moreView.showInView(window)
        }
    }

    @objc fileprivate func handleReceivedNewMessagesNotification(_ notification: Notification) {

        guard let
            messagesInfo = notification.object as? [String: AnyObject],
            let messageIDs = messagesInfo["messageIDs"] as? [String],
            let messageAgeRawValue = messagesInfo["messageAge"] as? String,
            let messageAge = MessageAge(rawValue: messageAgeRawValue) else {
                println("Can NOT handleReceivedNewMessagesNotification")
                return
        }

        handleRecievedNewMessages(messageIDs, messageAge: messageAge)
    }

    fileprivate func handleRecievedNewMessages(_ messageIDs: [String], messageAge: MessageAge) {

        if !isPreviewed {
            //Make sure insert cell when in conversation viewcontroller
            guard self.navigationController?.visibleViewController is ConversationViewController else {
                return
            }
        }

        realm.refresh() // 确保是最新数据

        guard let conversation = conversation, let conversationID = conversation.fakeID else {
            return
        }

        // 按照 conversation 过滤消息，匹配的才能考虑插入
        var filteredMessageIDs: [String] = []
        for messageID in messageIDs {
            if let message = messageWithMessageID(messageID, inRealm: realm) {
                if let messageInConversationID = message.conversation?.fakeID {
                    if messageInConversationID == conversationID {
                        filteredMessageIDs.append(messageID)
                    }
                }
            }
        }
        guard !filteredMessageIDs.isEmpty else {
            return
        }

        // 在前台时才能做插入
        if UIApplication.shared.applicationState == .active {
            updateConversationCollectionViewWithMessageIDs(filteredMessageIDs, messageAge: messageAge, scrollToBottom: false)

        } else {
            // 不然就先记下来
            inactiveNewMessageIDSet.formUnion(filteredMessageIDs)
            println("inactiveNewMessageIDSet: \(inactiveNewMessageIDSet)")
        }
    }

    @objc fileprivate func handleDeletedMessagesNotification(_ notification: Notification) {

        defer {
            reloadConversationCollectionView()
        }

        guard let info = notification.object as? [String: AnyObject], let messageIDs = info["messageIDs"] as? [String] else {
            return
        }

        messageIDs.forEach {
            clearHeightOfMessageWithKey($0)
        }
    }

    // App 进入前台时，根据通知插入处于后台状态时收到的消息

    @objc fileprivate func handleApplicationDidBecomeActive(_ notification: Notification) {

        guard UIApplication.shared.applicationState == .active else {
            return
        }

        tryInsertInActiveNewMessages()

        trySyncMessages()
    }

    fileprivate func tryInsertInActiveNewMessages() {

        if inactiveNewMessageIDSet.count > 0 {
            updateConversationCollectionViewWithMessageIDs(Array(inactiveNewMessageIDSet), messageAge: .New, scrollToBottom: false)

            inactiveNewMessageIDSet = []

            println("insert inactiveNewMessageIDSet to CollectionView")
        }
    }

    func updateConversationCollectionViewWithMessageIDs(_ messageIDs: [String]?, messageAge: MessageAge, scrollToBottom: Bool, success: ((Bool) -> Void)? = nil) {

        // 重要
        if !isPreviewed {
            guard navigationController?.topViewController == self else { // 防止 pop/push 后，原来未释放的 VC 也执行这下面的代码
                return
            }
        }

        if messageIDs != nil {
            batchMarkMessagesAsReaded()
        }

        let subscribeViewHeight = isSubscribeViewShowing ? SubscribeView.height : 0
        let keyboardAndToolBarHeight = messageToolbarBottomConstraint.constant + messageToolbar.bounds.height + subscribeViewHeight

        adjustConversationCollectionViewWithMessageIDs(messageIDs, messageAge: messageAge, adjustHeight: keyboardAndToolBarHeight, scrollToBottom: scrollToBottom) { finished in
            success?(finished)
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

                _ = delay(0.5) { [weak self] in
                    self?.subscribeView.hide()
                }

                moreViewManager.updateForGroupAffair()
            }
        }
    }

    fileprivate func adjustConversationCollectionViewWithMessageIDs(_ messageIDs: [String]?, messageAge: MessageAge, adjustHeight: CGFloat, scrollToBottom: Bool, success: @escaping (Bool) -> Void) {

        let oldMessagesUpdatedVersion = self.messagesUpdatedVersion

        let _lastTimeMessagesCount = lastTimeMessagesCount
        lastTimeMessagesCount = messages.count

        // 保证是增加消息
        if messages.count <= _lastTimeMessagesCount {
            return
        }

        let newMessagesCount = Int(messages.count - _lastTimeMessagesCount)

        // 异常：两种计数不相等，治标：reload，避免插入
        if let messageIDs = messageIDs {
            guard newMessagesCount == messageIDs.count else {
                reloadConversationCollectionView()
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

                var indexPaths = [IndexPath]()

                for messageID in messageIDs {
                    if let
                        message = messageWithMessageID(messageID, inRealm: realm),
                        let index = messages.index(of: message) {
                        let indexPath = IndexPath(item: index - displayedMessagesRange.location, section: Section.message.rawValue)
                        indexPaths.append(indexPath)

                    } else {
                        #if DEBUG
                            YepAlert.alertSorry(message: "Unknown message: \(messageID)", inViewController: self)
                        #endif

                        reloadConversationCollectionView()
                        return
                    }
                }

                switch messageAge {

                case .New:

                    conversationCollectionView.performBatchUpdates({ [weak self] in
                        guard let strongSelf = self else {
                            return
                        }

                        if needReloadLoadPreviousSection {
                            strongSelf.conversationCollectionView.reloadSections(IndexSet(integer: Section.loadPrevious.rawValue))
                            strongSelf.needReloadLoadPreviousSection = false
                        }

                        guard strongSelf.messagesUpdatedVersion == oldMessagesUpdatedVersion else {
                            strongSelf.conversationCollectionView.reloadSections(IndexSet(integer: Section.message.rawValue))
                            strongSelf.lastTimeMessagesCount = strongSelf.messages.count
                            println("double check failed! \(strongSelf.messages.count), \(_lastTimeMessagesCount)")
                            return
                        }

                        strongSelf.conversationCollectionView.insertItems(at: indexPaths)

                    }, completion: nil)

                case .Old:
                    // 用 CATransaction 保证 CollectionView 在插入后不闪动
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)

                    let bottomOffset = conversationCollectionView.contentSize.height - conversationCollectionView.contentOffset.y

                    conversationCollectionView.performBatchUpdates({ [weak self] in
                        guard let strongSelf = self else {
                            return
                        }

                        if needReloadLoadPreviousSection {
                            strongSelf.conversationCollectionView.reloadSections(IndexSet(integer: Section.loadPrevious.rawValue))
                            strongSelf.needReloadLoadPreviousSection = false
                        }

                        guard strongSelf.messagesUpdatedVersion == oldMessagesUpdatedVersion else {
                            strongSelf.conversationCollectionView.reloadSections(IndexSet(integer: Section.message.rawValue))
                            strongSelf.lastTimeMessagesCount = strongSelf.messages.count
                            println("double check failed! \(strongSelf.messages.count), \(_lastTimeMessagesCount)")
                            return
                        }

                        strongSelf.conversationCollectionView.insertItems(at: indexPaths)

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

                var indexPaths = [IndexPath]()

                for i in 0..<newMessagesCount {
                    let indexPath = IndexPath(item: lastDisplayedMessagesRange.length + i, section: Section.message.rawValue)
                    indexPaths.append(indexPath)
                }

                conversationCollectionView.performBatchUpdates({ [weak self] in
                    guard let strongSelf = self else {
                        return
                    }

                    if needReloadLoadPreviousSection {
                        strongSelf.conversationCollectionView.reloadSections(IndexSet(integer: Section.loadPrevious.rawValue))
                        strongSelf.needReloadLoadPreviousSection = false
                    }

                    guard strongSelf.messagesUpdatedVersion == oldMessagesUpdatedVersion else {
                        strongSelf.conversationCollectionView.reloadSections(IndexSet(integer: Section.message.rawValue))
                        strongSelf.lastTimeMessagesCount = strongSelf.messages.count
                        println("double check failed! \(strongSelf.messages.count), \(_lastTimeMessagesCount)")
                        return
                    }

                    strongSelf.conversationCollectionView.insertItems(at: indexPaths)

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

                UIView.animate(withDuration: 0.25, delay: 0.0, options: UIViewAnimationOptions(), animations: { [weak self] in

                    if let strongSelf = self {

                        if scrollToBottom {
                            let newContentSize = strongSelf.conversationCollectionView.collectionViewLayout.collectionViewContentSize
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

    @objc internal func reloadConversationCollectionView() {
        SafeDispatch.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.conversationCollectionView.reloadData()
            strongSelf.lastTimeMessagesCount = strongSelf.messages.count
        }
    }

    fileprivate func cleanTextInput() {
        messageToolbar.messageTextView.text = ""
        messageToolbar.state = .beginTextInput
    }

    @objc fileprivate func cleanForLogout(_ sender: Notification) {
        displayedMessagesRange.length = 0
    }
}

