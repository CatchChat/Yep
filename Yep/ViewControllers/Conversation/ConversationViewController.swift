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
import Navi

struct MessageNotification {
    static let MessageStateChanged = "MessageStateChangedNotification"
}

enum ConversationFeed {
    case DiscoveredFeedType(DiscoveredFeed)
    case FeedType(Feed)
    
    var feedID: String {
        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            return discoveredFeed.id
            
        case .FeedType(let feed):
            return feed.feedID
        }
    }
    
    var body: String {
        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            return discoveredFeed.body
            
        case .FeedType(let feed):
            return feed.body
        }
    }
    
    var creator: User? {
        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            guard let realm = try? Realm() else {
                return nil
            }
            return getOrCreateUserWithDiscoverUser(discoveredFeed.creator, inRealm: realm)
            
        case .FeedType(let feed):
            return feed.creator
        }
    }
    
    var distance: Double? {
        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            return discoveredFeed.distance
            
        case .FeedType(let feed):
            return feed.distance
        }
    }
    
    var attachments: [Attachment] {
        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            return attachmentFromDiscoveredAttachment(discoveredFeed.attachments, inRealm: nil)
            
        case .FeedType(let feed):
            return Array(feed.attachments)
        }
    }
    
    var createdUnixTime: NSTimeInterval {
        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            return discoveredFeed.createdUnixTime
            
        case .FeedType(let feed):
            return feed.createdUnixTime
        }
    }
}

class ConversationViewController: BaseViewController {
    
    var conversationFeed: ConversationFeed?
    
    var conversation: Conversation!
    
    var selectedIndexPathForMenu: NSIndexPath?

    var realm: Realm!
    
    lazy var messages: Results<Message> = {
        return messagesOfConversation(self.conversation, inRealm: self.realm)
        }()

    let messagesBunchCount = 30 // TODO: 分段载入的“一束”消息的数量
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
        
        if nameOfConversation(self.conversation) != "" {
            titleView.nameLabel.text = nameOfConversation(self.conversation)
        } else {
            titleView.nameLabel.text = NSLocalizedString("Discussion", comment: "")
        }

        self.updateStateInfoOfTitleView(titleView)
        return titleView
        }()

    lazy var moreView: ConversationMoreView = ConversationMoreView()

    lazy var moreMessageTypesView: MoreMessageTypesView = {

        let view =  MoreMessageTypesView()

        view.alertCanNotAccessCameraRollAction = { [weak self] in
            self?.alertCanNotAccessCameraRoll()
        }

        view.sendImageAction = { [weak self] image in
            self?.sendImage(image)
        }

        view.takePhotoAction = { [weak self] in

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

        view.choosePhotoAction = { [weak self] in

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

        view.pickLocationAction = { [weak self] in
            self?.performSegueWithIdentifier("presentPickLocation", sender: nil)
        }

        return view
        }()

    lazy var pullToRefreshView: PullToRefreshView = {

        let pullToRefreshView = PullToRefreshView()
        pullToRefreshView.delegate = self

        self.conversationCollectionView.insertSubview(pullToRefreshView, atIndex: 0)

        pullToRefreshView.translatesAutoresizingMaskIntoConstraints = false

        let viewsDictionary = [
            "pullToRefreshView": pullToRefreshView,
            "view": self.view,
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(-200)-[pullToRefreshView(200)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)

        // 非常奇怪，若直接用 "H:|[pullToRefreshView]|" 得到的实际宽度为 0
        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[pullToRefreshView(==view)]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints(constraintsH)

        return pullToRefreshView
        }()

    lazy var waverView: YepWaverView = {
        let frame = self.view.bounds
        let view = YepWaverView(frame: frame)

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

    var feedView: FeedView?
    var dragBeginLocation: CGPoint?

    @IBOutlet weak var conversationCollectionView: UICollectionView!
    let conversationCollectionViewContentInsetYOffset: CGFloat = 10

    @IBOutlet weak var messageToolbar: MessageToolbar!
    @IBOutlet weak var messageToolbarBottomConstraint: NSLayoutConstraint!

    //@IBOutlet weak var moreMessageTypesView: UIView!
    //@IBOutlet weak var moreMessageTypesViewHeightConstraint: NSLayoutConstraint!
    //let moreMessageTypesViewDefaultHeight: CGFloat = 110

    //@IBOutlet weak var choosePhotoButton: MessageTypeButton!
    //@IBOutlet weak var takePhotoButton: MessageTypeButton!
    //@IBOutlet weak var addLocationButton: MessageTypeButton!

    @IBOutlet weak var swipeUpView: UIView!
    @IBOutlet weak var swipeUpPromptLabel: UILabel!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
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
        imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
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

        conversationCollectionView.delegate = nil

        println("deinit ConversationViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        UIMenuController.sharedMenuController().menuItems = [ UIMenuItem(title: NSLocalizedString("Delete", comment: ""), action: "deleteMessage:") ]
        
        realm = try! Realm()

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

        view.tintAdjustmentMode = .Normal

        if messages.count >= messagesBunchCount {
            displayedMessagesRange = NSRange(location: Int(messages.count) - messagesBunchCount, length: messagesBunchCount)
        } else {
            displayedMessagesRange = NSRange(location: 0, length: Int(messages.count))
        }

        lastTimeMessagesCount = messages.count

        navigationItem.titleView = titleView

        if let _ = conversation?.withFriend {
            let moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_more"), style: UIBarButtonItemStyle.Plain, target: self, action: "moreAction")
            navigationItem.rightBarButtonItem = moreBarButtonItem
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleReceivedNewMessagesNotification:", name: YepNewMessagesReceivedNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "cleanForLogout", name: EditProfileViewController.Notification.Logout, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "tryInsertInActiveNewMessages:", name: AppDelegate.Notification.applicationDidBecomeActive, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didRecieveMenuWillShowNotification:", name: UIMenuControllerWillShowMenuNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didRecieveMenuWillHideNotification:", name: UIMenuControllerWillHideMenuNotification, object: nil)

        YepUserDefaults.avatarURLString.bindListener(Listener.Avatar) { [weak self] _ in
            dispatch_async(dispatch_get_main_queue()) {
                self?.reloadConversationCollectionView()
            }
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


        let tap = UITapGestureRecognizer(target: self, action: "tapToCollapseMessageToolBar:")
        conversationCollectionView.addGestureRecognizer(tap)

        messageToolbarBottomConstraint.constant = 0
        //moreMessageTypesViewHeightConstraint.constant = moreMessageTypesViewDefaultHeight

        keyboardMan.animateWhenKeyboardAppear = { [weak self] appearPostIndex, keyboardHeight, keyboardHeightIncrement in

            println("appear \(keyboardHeight), \(keyboardHeightIncrement)\n")

            if let strongSelf = self {

                if strongSelf.messageToolbarBottomConstraint.constant > 0 {

                    // 注意第一次要减去已经有的高度偏移
                    if appearPostIndex == 0 {
                        strongSelf.conversationCollectionView.contentOffset.y += keyboardHeightIncrement //- strongSelf.moreMessageTypesViewDefaultHeight
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

            println("disappear \(keyboardHeight)\n")

            if let strongSelf = self {

                strongSelf.conversationCollectionView.contentOffset.y -= keyboardHeight
                strongSelf.conversationCollectionView.contentInset.bottom = strongSelf.messageToolbar.frame.height

                strongSelf.messageToolbarBottomConstraint.constant = 0
                strongSelf.view.layoutIfNeeded()
            }
        }

        // sync messages

        let syncMessages: () -> Void = {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in

                if let recipient = self?.conversation.recipient {
                    
                    let timeDirection: TimeDirection
                    if let minMessageID = self?.messages.last?.messageID {
                        timeDirection = .Future(minMessageID: minMessageID)
                    } else {
                        timeDirection = .None

                        self?.activityIndicator.startAnimating()
                    }
                    
                    messagesFromRecipient(recipient, withTimeDirection: timeDirection, failureHandler: nil, completion: { messageIDs in
                        println("messagesFromRecipient: \(messageIDs.count)")

                        dispatch_async(dispatch_get_main_queue()) { [weak self] in

                            tryPostNewMessagesReceivedNotificationWithMessageIDs(messageIDs, withMessageAge: timeDirection.messageAge)

                            self?.activityIndicator.stopAnimating()
                        }
                    })
                }
            }
        }

        switch conversation.type {

        case ConversationType.OneToOne.rawValue:
            syncMessages()

        case ConversationType.Group.rawValue:

            if let groupID = conversation.withGroup?.groupID {

                joinGroup(groupID: groupID, failureHandler: nil, completion: { result in

                    syncMessages()

                    dispatch_async(dispatch_get_main_queue()) {
                        FayeService.sharedManager.subscribeGroup(groupID: groupID)
                    }
                })
            }

        default:
            break
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // 尝试恢复原始的 NavigationControllerDelegate，如果自定义 push 了才需要
        if let delegate = originalNavigationControllerDelegate {
            navigationController?.delegate = delegate
        }

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
                    
                    self?.messageToolbar.state = .Default

                    delay(0.2) {
                        self?.imagePicker.hidesBarsOnTap = false
                    }
                }
            }

            // MARK: MessageToolbar State Transitions

            messageToolbar.stateTransitionAction = { [weak self] (messageToolbar, previousState, currentState) in

                if let strongSelf = self {
                    switch currentState {
                    case .BeginTextInput:
                        self?.tryFoldFeedView()
                    default:
                        break
                    }
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
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
        setNeedsStatusBarAppearanceUpdate()

        conversationCollectionViewHasBeenMovedToBottomOnce = true

        FayeService.sharedManager.delegate = self

        // 进来时就尽快标记已读

        batchMarkMessagesAsReaded(needUpdateAllMessages: true)

        // MARK: Notify Typing

        // 为 nil 时才新建
        if checkTypingStatusTimer == nil {
            checkTypingStatusTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("checkTypingStatus"), userInfo: nil, repeats: true)
        }

        // 尽量晚的设置一些属性和闭包

        if isFirstAppear {

            isFirstAppear = false

            messageToolbar.notifyTypingAction = { [weak self] in

                if let withFriend = self?.conversation.withFriend {

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
                            self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { success in
                            })
                        }

                    }, failureHandler: { [weak self] reason, errorMessage in
                        defaultFailureHandler(reason, errorMessage: errorMessage)

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
                            self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                            })
                        }

                    }, failureHandler: { [weak self] reason, errorMessage in
                        defaultFailureHandler(reason, errorMessage: errorMessage)

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

                            dispatch_async(dispatch_get_main_queue()) {
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
                            defaultFailureHandler(reason, errorMessage: errorMessage)

                            YepAlert.alertSorry(message: NSLocalizedString("Failed to send audio!\nTry tap on message to resend.", comment: ""), inViewController: self)

                        }, completion: { success in
                            println("send audio to friend: \(success)")
                        })

                    } else if let withGroup = self?.conversation.withGroup {
                        sendAudioInFilePath(fileURL.path!, orFileData: nil, metaData: metaData, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { [weak self] message in

                            dispatch_async(dispatch_get_main_queue()) {
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
                            defaultFailureHandler(reason, errorMessage: errorMessage)

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
    }

    private func batchMarkMessagesAsReaded(needUpdateAllMessages needUpdateAllMessages: Bool = false) {

        if let recipient = conversation.recipient, latestMessage = messages.last {

            var needMarkInServer = false

            if needUpdateAllMessages {
                
                var predicate = NSPredicate(format: "readed = 0", argumentArray: nil)
                
                if let recipientType = conversation.recipient?.type {
                    if recipientType == .OneToOne {
                        predicate = NSPredicate(format: "readed = 0 AND fromFriend != nil AND fromFriend.friendState != %d", UserFriendState.Me.rawValue)
                    }
                }
                
                messages.filter(predicate).forEach { message in
                    let _ = try? realm.write {
                        message.readed = true
                    }

                    needMarkInServer = true
                }

            } else {
                let _ = try? realm.write {
                    latestMessage.readed = true

                    needMarkInServer = true
                }
            }

            if needMarkInServer {
                batchMarkAsReadOfMessagesToRecipient(recipient, beforeMessage: latestMessage, failureHandler: nil, completion: {
                    println("batchMarkAsReadOfMessagesToRecipient OK")
                })

            } else {
                println("don't needMarkInServer")
            }
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        NSNotificationCenter.defaultCenter().postNotificationName(MessageToolbar.Notification.updateDraft, object: nil)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        FayeService.sharedManager.delegate = nil
        checkTypingStatusTimer?.invalidate()
        checkTypingStatusTimer = nil // 及时释放

        waverView.removeFromSuperview()
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
                defaultFailureHandler(reason, errorMessage: errorMessage)

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
                            , confirmTitle: NSLocalizedString("Unblock", comment: ""), cancelTitle: NSLocalizedString("Not now", comment: ""), inViewController: self, withConfirmAction: {

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

        friendRequestView.translatesAutoresizingMaskIntoConstraints = false
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
                    if let strongSelf = self {
                        strongSelf.conversationCollectionView.contentInset.top = 64 + strongSelf.conversationCollectionViewContentInsetYOffset

                        friendRequestViewTop.constant -= FriendRequestView.height
                        strongSelf.view.layoutIfNeeded()
                    }

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
                    guard let realm = try? Realm() else {
                        return
                    }
                    if let user = userWithUserID(userID, inRealm: realm) {
                        let _ = try? realm.write {
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
                        guard let realm = try? Realm() else {
                            return
                        }
                        if let user = userWithUserID(userID, inRealm: realm) {
                            let _ = try? realm.write {
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

    private func makeFeedViewWithFeed(feed: ConversationFeed) {

        let feedView = FeedView.instanceFromNib()

        feedView.feed = feed

        feedView.tapAvatarAction = { [weak self] in
            self?.performSegueWithIdentifier("showProfileFromFeedView", sender: nil)
        }

        feedView.foldAction = { [weak self] in
            if let strongSelf = self {
                self?.conversationCollectionView.contentInset.top = 64 + FeedView.foldHeight + strongSelf.conversationCollectionViewContentInsetYOffset
            }
        }
        
        feedView.unfoldAction = { [weak self] feedView in
            if let strongSelf = self {
                self?.conversationCollectionView.contentInset.top = 64 + feedView.normalHeight + strongSelf.conversationCollectionViewContentInsetYOffset
            }
        }

        feedView.tapMediaAction = { [weak self] transitionView, imageURL in
            let info = [
                "transitionView": transitionView,
                "imageURL": imageURL,
            ]
            self?.performSegueWithIdentifier("showFeedMedia", sender: info)
        }

        //feedView.backgroundColor = UIColor.orangeColor()
        feedView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(feedView)

        let views = [
            "feedView": feedView
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[feedView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)

        let top = NSLayoutConstraint(item: feedView, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1.0, constant: 64)
        let height = NSLayoutConstraint(item: feedView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: feedView.normalHeight)

        NSLayoutConstraint.activateConstraints(constraintsH)
        //NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints([top, height])

        feedView.heightConstraint = height

        self.feedView = feedView
    }

    // MARK: Private

    private func setConversaitonCollectionViewContentInsetBottom(bottom: CGFloat) {
        var contentInset = conversationCollectionView.contentInset
        contentInset.bottom = bottom
        conversationCollectionView.contentInset = contentInset
    }

    private func setConversaitonCollectionViewOriginalContentInset() {

        let feedViewHeight: CGFloat = (feedView == nil) ? 0 : feedView!.height
        conversationCollectionView.contentInset.top = 64 + feedViewHeight + conversationCollectionViewContentInsetYOffset

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
            let rect = message.textContent.boundingRectWithSize(CGSize(width: messageTextLabelMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.ChatCell.textAttributes, context: nil)

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

        let rect = message.textContent.boundingRectWithSize(CGSize(width: messageTextLabelMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.ChatCell.textAttributes, context: nil)

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

    private func tryFoldFeedView() {

        guard let feedView = feedView else {
            return
        }

        if feedView.foldProgress != 1.0 {

            feedView.foldProgress = 1.0
        }
    }

    // MARK: Actions

    func tapToCollapseMessageToolBar(sender: UITapGestureRecognizer) {
        if selectedIndexPathForMenu == nil {
            messageToolbar.state = .Default
        }
    }

    func checkTypingStatus() {

        typingResetDelay = typingResetDelay - 0.5

        if typingResetDelay < 0 {
            self.updateStateInfoOfTitleView(titleView)
        }
    }

    func tryScrollToBottom() {

        if displayedMessagesRange.length > 0 {

            let messageToolBarTop = messageToolbarBottomConstraint.constant + CGRectGetHeight(messageToolbar.bounds)

            let feedViewHeight: CGFloat = (feedView == nil) ? 0 : feedView!.height
            let invisibleHeight = messageToolBarTop + topBarsHeight + feedViewHeight
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

            /*
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
            */

            settingsForUserWithUserID(userID, failureHandler: nil, completion: { [weak self] blocked, doNotDisturb in
                self?.updateNotificationEnabled(!doNotDisturb, forUserWithUserID: userID)
                self?.updateBlocked(blocked, forUserWithUserID: userID)
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

        guard let realm = try? Realm() else {
            return
        }

        if let user = userWithUserID(userID, inRealm: realm) {
            let _ = try? realm.write {
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
                    defaultFailureHandler(reason, errorMessage: errorMessage)

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
            YepAlert.textInput(title: NSLocalizedString("Other Reason", comment: ""), message: nil, placeholder: nil, oldText: nil, confirmTitle: NSLocalizedString("OK", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: { text in
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

        guard let realm = try? Realm() else {
            return
        }

        if let user = userWithUserID(userID, inRealm: realm) {
            let _ = try? realm.write {
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

        guard let
            messagesInfo = notification.object as? [String: AnyObject],
            allMessageIDs = messagesInfo["messageIDs"] as? [String],
            messageAgeRawValue = messagesInfo["messageAge"] as? String,
            messageAge = MessageAge(rawValue: messageAgeRawValue) else {
                println("Can NOT handleReceivedNewMessagesNotification")
                return
        }

        // 按照 conversation 过滤消息，匹配的才能考虑插入
        if let conversation = conversation {
            
            if let conversationID = conversation.fakeID, realm = conversation.realm {
                
                var filteredMessageIDs = [String]()
                
                for messageID in allMessageIDs {
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

    // App 进入前台时，根据通知插入处于后台状态时收到的消息

    func tryInsertInActiveNewMessages(notification: NSNotification) {

        if UIApplication.sharedApplication().applicationState == .Active {

            if inActiveNewMessageIDSet.count > 0 {
                updateConversationCollectionViewWithMessageIDs(Array(inActiveNewMessageIDSet), messageAge: .New, scrollToBottom: false, success: { _ in
                })

                inActiveNewMessageIDSet = []

                println("insert inActiveNewMessageIDSet to CollectionView")
            }
        }
    }

    func updateConversationCollectionViewWithMessageIDs(messageIDs: [String]?, messageAge: MessageAge, scrollToBottom: Bool, success: (Bool) -> Void) {

        if navigationController?.topViewController == self { // 防止 pop/push 后，原来未释放的 VC 也执行这下面的代码

            let keyboardAndToolBarHeight = messageToolbarBottomConstraint.constant + CGRectGetHeight(messageToolbar.bounds)

            adjustConversationCollectionViewWithMessageIDs(messageIDs, messageAge: messageAge, adjustHeight: keyboardAndToolBarHeight, scrollToBottom: scrollToBottom) { finished in
                success(finished)
            }
        }
    }

    func adjustConversationCollectionViewWithMessageIDs(messageIDs: [String]?, messageAge: MessageAge, adjustHeight: CGFloat, scrollToBottom: Bool, success: (Bool) -> Void) {

        let _lastTimeMessagesCount = lastTimeMessagesCount
        lastTimeMessagesCount = messages.count

        // 保证是增加消息
        if messages.count <= _lastTimeMessagesCount {
            return
        }

        let newMessagesCount = Int(messages.count - _lastTimeMessagesCount)

        let lastDisplayedMessagesRange = displayedMessagesRange

        displayedMessagesRange.length += newMessagesCount

        // 异常：两种计数不相等，治标：reload，避免插入
        if let messageIDs = messageIDs {
            if newMessagesCount != messageIDs.count {
                reloadConversationCollectionView()
                println("newMessagesCount != messageIDs.count")
                #if DEBUG
                    YepAlert.alertSorry(message: "请截屏报告!\nnewMessagesCount: \(newMessagesCount)\nmessageIDs.count: \(messageIDs.count): \(messageIDs)", inViewController: self)
                #endif
                return
            }
        }

        if newMessagesCount > 0 {

            if let messageIDs = messageIDs {

                var indexPaths = [NSIndexPath]()

                for messageID in messageIDs {
                    if let
                        message = messageWithMessageID(messageID, inRealm: realm),
                        index = messages.indexOf(message) {
                            let indexPath = NSIndexPath(forItem: index - displayedMessagesRange.location, inSection: 0)
                            println("insert item: \(indexPath.item), \(index), \(displayedMessagesRange.location)")

                            indexPaths.append(indexPath)

                    } else {
                        println("unknown message")
                    }
                }

                switch messageAge {

                case .New:
                    conversationCollectionView.insertItemsAtIndexPaths(indexPaths)

                case .Old:
                    let bottomOffset = conversationCollectionView.contentSize.height - conversationCollectionView.contentOffset.y
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)

                    conversationCollectionView.performBatchUpdates({ [weak self] in
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
                
                titleView.stateInfoLabel.textColor = UIColor.grayColor()
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

        if segue.identifier == "showProfileFromFeedView" {

            let vc = segue.destinationViewController as! ProfileViewController

            if let user = feedView?.feed?.creator {
                vc.profileUser = ProfileUser.UserType(user)
            }

            vc.fromType = .GroupConversation
            vc.setBackButtonWithTitle()

        } else if segue.identifier == "showProfile" {

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

            switch conversation.type {
            case ConversationType.OneToOne.rawValue:
                vc.fromType = .OneToOneConversation
            case ConversationType.Group.rawValue:
                vc.fromType = .GroupConversation
            default:
                break
            }

            vc.setBackButtonWithTitle()

        } else if segue.identifier == "showFeedMedia" {

            let info = sender as! [String: AnyObject]

            let vc = segue.destinationViewController as! MessageMediaViewController
            vc.previewMedia = PreviewMedia.AttachmentType(imageURL: info["imageURL"] as! NSURL )

            let transitionView = info["transitionView"] as! UIImageView

            let delegate = ConversationMessagePreviewNavigationControllerDelegate()
            delegate.isFeedMedia = true
            delegate.snapshot = UIScreen.mainScreen().snapshotViewAfterScreenUpdates(false)

            var frame = transitionView.convertRect(transitionView.frame, toView: view)
            delegate.frame = frame
            if let image = transitionView.image {
                let width = image.size.width
                let height = image.size.height
                if width > height {
                    let newWidth = frame.width * (width / height)
                    frame.origin.x -= (newWidth - frame.width) / 2
                    frame.size.width = newWidth
                } else {
                    let newHeight = frame.height * (height / width)
                    frame.origin.y -= (newHeight - frame.height) / 2
                    frame.size.height = newHeight
                }
                delegate.thumbnailImage = image
            }
            delegate.thumbnailFrame = frame

            delegate.transitionView = transitionView

            navigationControllerDelegate = delegate

            // 在自定义 push 之前，记录原始的 NavigationControllerDelegate 以便 pop 后恢复
            originalNavigationControllerDelegate = navigationController!.delegate
            
            navigationController?.delegate = delegate

        } else if segue.identifier == "showMessageMedia" {

            let vc = segue.destinationViewController as! MessageMediaViewController

            if let message = sender as? Message, messageIndex = messages.indexOf(message) {

                vc.previewMedia = PreviewMedia.MessageType(message: message)

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
                    delegate.thumbnailFrame = frame
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

                vc.previewMedia = PreviewMedia.MessageType(message: message)

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

            vc.sendLocationAction = { [weak self] locationInfo in

                if let withFriend = self?.conversation.withFriend {

                    sendLocationWithLocationInfo(locationInfo, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { message in

                        dispatch_async(dispatch_get_main_queue()) {
                            self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                            })
                        }

                    }, failureHandler: { [weak self] reason, errorMessage in
                        defaultFailureHandler(reason, errorMessage: errorMessage)

                        YepAlert.alertSorry(message: NSLocalizedString("Failed to send location!\nTry tap on message to resend.", comment: ""), inViewController: self)

                    }, completion: { success -> Void in
                        println("sendLocation to friend: \(success)")
                    })

                } else if let withGroup = self?.conversation.withGroup {

                    sendLocationWithLocationInfo(locationInfo, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { message in
                        dispatch_async(dispatch_get_main_queue()) {
                            self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                            })
                        }

                    }, failureHandler: { [weak self] reason, errorMessage in
                        defaultFailureHandler(reason, errorMessage: errorMessage)

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
    
    func didRecieveMenuWillHideNotification(notification: NSNotification) {
        print("Menu Will hide")
        
        selectedIndexPathForMenu = nil
        
    }
    
    func didRecieveMenuWillShowNotification(notification: NSNotification) {
        
        print("Menu Will show")
        
        if let menu = notification.object as? UIMenuController,
            selectedIndexPathForMenu = selectedIndexPathForMenu
        {
            
            var bubbleFrame = CGRectZero
            
            if let cell = conversationCollectionView.cellForItemAtIndexPath(selectedIndexPathForMenu) as? ChatRightTextCell {
                bubbleFrame = cell.convertRect(cell.textContainerView.frame, toView: view)
            } else if let cell = conversationCollectionView.cellForItemAtIndexPath(selectedIndexPathForMenu) as? ChatLeftTextCell {
                bubbleFrame = cell.convertRect(cell.textContainerView.frame, toView: view)
            } else {
                return
            }
            
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIMenuControllerWillShowMenuNotification, object: nil)

            menu.setTargetRect(bubbleFrame, inView: view)

            menu.setMenuVisible(true, animated: true)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "didRecieveMenuWillShowNotification:", name: UIMenuControllerWillShowMenuNotification, object: nil)


        }

        
    }
    
    func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        
        if action == "copy:" {
            return true
        
        } else if action == "deleteMessage:" {
            return true
        }
        
        return false
    }
    
    
    func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        
        if let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatRightTextCell {
            if action == "copy:" {
                UIPasteboard.generalPasteboard().string = cell.textContentTextView.text
            }
        } else if let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatLeftTextCell {
            if action == "copy:" {
                UIPasteboard.generalPasteboard().string = cell.textContentTextView.text
            }
        }
        
    }
    
    func deleteMessageAtIndexPath(message: Message, indexPath: NSIndexPath) {
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
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
                    
                    let _ = try? realm.write {
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
                    let _ = try? realm.write {
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
    
    func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        selectedIndexPathForMenu = indexPath
        
        if let _ = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatRightTextCell {

            return true
        } else if let _ = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatLeftTextCell {
            return true
        } else {
            selectedIndexPathForMenu = nil
        }

        return false
    }
    
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
                collectionViewConfigCell(collectionView, cell: cell, forItemAtIndexPath: indexPath)
                return cell
            }

            if let sender = message.fromFriend {

                if sender.friendState != UserFriendState.Me.rawValue { // from Friend

                    if !message.readed {
                        batchMarkMessagesAsReaded()
                    }

                    switch message.mediaType {

                    case MessageMediaType.Image.rawValue:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftImageCellIdentifier, forIndexPath: indexPath) as! ChatLeftImageCell
                        collectionViewConfigCell(collectionView, cell: cell, forItemAtIndexPath: indexPath)
                        return cell

                    case MessageMediaType.Audio.rawValue:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftAudioCellIdentifier, forIndexPath: indexPath) as! ChatLeftAudioCell
                        collectionViewConfigCell(collectionView, cell: cell, forItemAtIndexPath: indexPath)
                        return cell

                    case MessageMediaType.Video.rawValue:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftVideoCellIdentifier, forIndexPath: indexPath) as! ChatLeftVideoCell
                        collectionViewConfigCell(collectionView, cell: cell, forItemAtIndexPath: indexPath)
                        return cell

                    case MessageMediaType.Location.rawValue:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftLocationCellIdentifier, forIndexPath: indexPath) as! ChatLeftLocationCell
                        collectionViewConfigCell(collectionView, cell: cell, forItemAtIndexPath: indexPath)
                        return cell

                    default:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftTextCellIdentifier, forIndexPath: indexPath) as! ChatLeftTextCell
                        collectionViewConfigCell(collectionView, cell: cell, forItemAtIndexPath: indexPath)
                        return cell
                    }

                } else { // from Me

                    switch message.mediaType {

                    case MessageMediaType.Image.rawValue:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightImageCellIdentifier, forIndexPath: indexPath) as! ChatRightImageCell
                        collectionViewConfigCell(collectionView, cell: cell, forItemAtIndexPath: indexPath)
                        return cell

                    case MessageMediaType.Audio.rawValue:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightAudioCellIdentifier, forIndexPath: indexPath) as! ChatRightAudioCell
                        collectionViewConfigCell(collectionView, cell: cell, forItemAtIndexPath: indexPath)
                        return cell

                    case MessageMediaType.Video.rawValue:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightVideoCellIdentifier, forIndexPath: indexPath) as! ChatRightVideoCell
                        collectionViewConfigCell(collectionView, cell: cell, forItemAtIndexPath: indexPath)
                        return cell

                    case MessageMediaType.Location.rawValue:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightLocationCellIdentifier, forIndexPath: indexPath) as! ChatRightLocationCell
                        collectionViewConfigCell(collectionView, cell: cell, forItemAtIndexPath: indexPath)
                        return cell

                    default:

                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightTextCellIdentifier, forIndexPath: indexPath) as! ChatRightTextCell
                        collectionViewConfigCell(collectionView, cell: cell, forItemAtIndexPath: indexPath)
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

    func collectionViewConfigCell(collectionView: UICollectionView, cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {

        if let message = self.messages[safe: (self.displayedMessagesRange.location + indexPath.item)] {
            
            if message.mediaType == MessageMediaType.SectionDate.rawValue {
                
                if let cell = cell as? ChatSectionDateCell {
                    let createdAt = NSDate(timeIntervalSince1970: message.createdUnixTime)
                    
                    if createdAt.isInCurrentWeek() {
                        cell.sectionDateLabel.text = self.sectionDateInCurrentWeekFormatter.stringFromDate(createdAt)
                    } else {
                        cell.sectionDateLabel.text = self.sectionDateFormatter.stringFromDate(createdAt)
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

                if let cell = cell as? ChatRightBaseCell {
                    if let _ = self.conversation.withGroup {
                        cell.inGroup = true
                    }
                }
                
                if sender.friendState != UserFriendState.Me.rawValue { // from Friend
                    
                    switch message.mediaType {
                        
                    case MessageMediaType.Image.rawValue:
                        
                        if let cell = cell as? ChatLeftImageCell {
                            
                            cell.configureWithMessage(message, messageImagePreferredWidth: self.messageImagePreferredWidth, messageImagePreferredHeight: self.messageImagePreferredHeight, messageImagePreferredAspectRatio: self.messageImagePreferredAspectRatio, mediaTapAction: { [weak self] in
                                
                                if message.downloadState == MessageDownloadState.Downloaded.rawValue {
                                    
                                    if let messageTextView = self?.messageToolbar.messageTextView {
                                        if messageTextView.isFirstResponder() {
                                            self?.messageToolbar.state = .Default
                                            return
                                        }
                                    }
                                    
                                    self?.performSegueWithIdentifier("showMessageMedia", sender: message)
                                    
                                } else {
                                    //YepAlert.alertSorry(message: NSLocalizedString("Please wait while the image is not ready!", comment: ""), inViewController: self)
                                }
                                
                                }, collectionView: collectionView, indexPath: indexPath)
                        }
                        
                    case MessageMediaType.Audio.rawValue:
                        
                        if let cell = cell as? ChatLeftAudioCell {
                            
                            let audioPlayedDuration = self.audioPlayedDurationOfMessage(message)
                            
                            cell.configureWithMessage(message, audioPlayedDuration: audioPlayedDuration, audioBubbleTapAction: { [weak self] in
                                
                                if message.downloadState == MessageDownloadState.Downloaded.rawValue {
                                    self?.playMessageAudioWithMessage(message)
                                    
                                } else {
                                    //YepAlert.alertSorry(message: NSLocalizedString("Please wait while the audio is not ready!", comment: ""), inViewController: self)
                                }
                                
                                }, collectionView: collectionView, indexPath: indexPath)
                        }
                        
                    case MessageMediaType.Video.rawValue:
                        
                        if let cell = cell as? ChatLeftVideoCell {
                            
                            cell.configureWithMessage(message, messageImagePreferredWidth: self.messageImagePreferredWidth, messageImagePreferredHeight: self.messageImagePreferredHeight, messageImagePreferredAspectRatio: self.messageImagePreferredAspectRatio, mediaTapAction: { [weak self] in
                                
                                if message.downloadState == MessageDownloadState.Downloaded.rawValue {
                                    
                                    if let messageTextView = self?.messageToolbar.messageTextView {
                                        if messageTextView.isFirstResponder() {
                                            self?.messageToolbar.state = .Default
                                            return
                                        }
                                    }
                                    
                                    self?.performSegueWithIdentifier("showMessageMedia", sender: message)
                                    
                                } else {
                                    //YepAlert.alertSorry(message: NSLocalizedString("Please wait while the video is not ready!", comment: ""), inViewController: self)
                                }
                                
                                }, collectionView: collectionView, indexPath: indexPath)
                        }
                        
                    case MessageMediaType.Location.rawValue:
                        
                        if let cell = cell as? ChatLeftLocationCell {
                            
                            cell.configureWithMessage(message, mediaTapAction: {
                                if let coordinate = message.coordinate {
                                    let locationCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
                                    mapItem.name = message.textContent
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
                            
                            cell.configureWithMessage(message, textContentLabelWidth: self.textContentLabelWidthOfMessage(message), collectionView: collectionView, indexPath: indexPath)
                        }
                    }
                    
                } else { // from Me
                    
                    switch message.mediaType {
                        
                    case MessageMediaType.Image.rawValue:
                        
                        if let cell = cell as? ChatRightImageCell {
                            
                            cell.configureWithMessage(message, messageImagePreferredWidth: self.messageImagePreferredWidth, messageImagePreferredHeight: self.messageImagePreferredHeight, messageImagePreferredAspectRatio: self.messageImagePreferredAspectRatio, mediaTapAction: { [weak self] in
                                
                                if message.sendState == MessageSendState.Failed.rawValue {
                                    
                                    YepAlert.confirmOrCancel(title: NSLocalizedString("Action", comment: ""), message: NSLocalizedString("Resend image?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: {
                                        
                                        resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                            defaultFailureHandler(reason, errorMessage: errorMessage)
                                            
                                            YepAlert.alertSorry(message: NSLocalizedString("Failed to resend image!\nPlease make sure your iPhone is connected to the Internet.", comment: ""), inViewController: self)
                                            
                                            }, completion: { success in
                                                println("resendImage: \(success)")
                                        })
                                        
                                        }, cancelAction: {
                                    })
                                    
                                } else {
                                    if let messageTextView = self?.messageToolbar.messageTextView {
                                        if messageTextView.isFirstResponder() {
                                            self?.messageToolbar.state = .Default
                                            return
                                        }
                                    }
                                    
                                    self?.performSegueWithIdentifier("showMessageMedia", sender: message)
                                }
                                
                                }, collectionView: collectionView, indexPath: indexPath)
                        }
                        
                    case MessageMediaType.Audio.rawValue:
                        
                        if let cell = cell as? ChatRightAudioCell {
                            
                            let audioPlayedDuration = self.audioPlayedDurationOfMessage(message)
                            
                            cell.configureWithMessage(message, audioPlayedDuration: audioPlayedDuration, audioBubbleTapAction: { [weak self] in
                                
                                if message.sendState == MessageSendState.Failed.rawValue {
                                    
                                    YepAlert.confirmOrCancel(title: NSLocalizedString("Action", comment: ""), message: NSLocalizedString("Resend audio?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: {
                                        
                                        resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                            defaultFailureHandler(reason, errorMessage: errorMessage)
                                            
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
                            
                            cell.configureWithMessage(message, messageImagePreferredWidth: self.messageImagePreferredWidth, messageImagePreferredHeight: self.messageImagePreferredHeight, messageImagePreferredAspectRatio: self.messageImagePreferredAspectRatio, mediaTapAction: { [weak self] in
                                
                                if message.sendState == MessageSendState.Failed.rawValue {
                                    
                                    YepAlert.confirmOrCancel(title: NSLocalizedString("Action", comment: ""), message: NSLocalizedString("Resend video?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: {
                                        
                                        resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                            defaultFailureHandler(reason, errorMessage: errorMessage)
                                            
                                            YepAlert.alertSorry(message: NSLocalizedString("Failed to resend video!\nPlease make sure your iPhone is connected to the Internet.", comment: ""), inViewController: self)
                                            
                                            }, completion: { success in
                                                println("resendVideo: \(success)")
                                        })
                                        
                                        }, cancelAction: {
                                    })
                                    
                                } else {
                                    if let messageTextView = self?.messageToolbar.messageTextView {
                                        if messageTextView.isFirstResponder() {
                                            self?.messageToolbar.state = .Default
                                            return
                                        }
                                    }
                                    
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
                                            defaultFailureHandler(reason, errorMessage: errorMessage)
                                            
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
                                        mapItem.name = message.textContent
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
                            
                            cell.configureWithMessage(message, textContentLabelWidth: self.textContentLabelWidthOfMessage(message), mediaTapAction: { [weak self] in
                                
                                if message.sendState == MessageSendState.Failed.rawValue {
                                    
                                    YepAlert.confirmOrCancel(title: NSLocalizedString("Action", comment: ""), message: NSLocalizedString("Resend text?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: {
                                        
                                        resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                            defaultFailureHandler(reason, errorMessage: errorMessage)
                                            
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
                                            
                                            let _ = try? realm.write {
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
                                            let _ = try? realm.write {
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

        case .BeginTextInput, .TextInputing:
            messageToolbar.state = .Default

        default:
            break
        }
    }

    // MARK: UIScrollViewDelegate

    func scrollViewWillBeginDragging(scrollView: UIScrollView) {

        let location = scrollView.panGestureRecognizer.locationInView(view)
        dragBeginLocation = location
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {

        pullToRefreshView.scrollViewDidScroll(scrollView)

        if let dragBeginLocation = dragBeginLocation {
            let location = scrollView.panGestureRecognizer.locationInView(view)
            let deltaY = location.y - dragBeginLocation.y

            if deltaY < -30 {
                tryFoldFeedView()
            }
        }
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

//                let nickname = withFriend.nickname

                let content = NSLocalizedString(" is ", comment: "正在") + "\(instantStateType)"

                titleView.stateInfoLabel.text = "\(content)..."
                titleView.stateInfoLabel.textColor = UIColor.yepTintColor()

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

        if displayedMessagesRange.location == 0 {

            if let recipient = conversation.recipient {

                let timeDirection: TimeDirection
                if let maxMessageID = messages.first?.messageID {
                    timeDirection = .Past(maxMessageID: maxMessageID)
                } else {
                    timeDirection = .None
                }

                messagesFromRecipient(recipient, withTimeDirection: timeDirection, failureHandler: nil, completion: { messageIDs in
                    println("messagesFromRecipient: \(messageIDs.count)")

                    dispatch_async(dispatch_get_main_queue()) {
                        pulllToRefreshView.endRefreshingAndDoFurtherAction() {
                            dispatch_async(dispatch_get_main_queue()) {
                                tryPostNewMessagesReceivedNotificationWithMessageIDs(messageIDs, withMessageAge: timeDirection.messageAge)
                            }
                        }
                    }
                })
            }

        } else {

            delay(0.5) {

                pulllToRefreshView.endRefreshingAndDoFurtherAction() { [weak self] in

                    if let strongSelf = self {
                        //let lastDisplayedMessagesRange = strongSelf.displayedMessagesRange

                        var newMessagesCount = strongSelf.messagesBunchCount

                        if (strongSelf.displayedMessagesRange.location - newMessagesCount) < 0 {
                            newMessagesCount = strongSelf.displayedMessagesRange.location
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
    }

    func scrollView() -> UIScrollView {
        return conversationCollectionView
    }
}

// MARK: AVAudioRecorderDelegate

extension ConversationViewController : AVAudioRecorderDelegate {

    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        println("finished recording \(flag)")
    }

    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder, error: NSError?) {
        println("\(error?.localizedDescription)")
    }
}

// MARK: AVAudioPlayerDelegate

extension ConversationViewController: AVAudioPlayerDelegate {

    func audioPlayerBeginInterruption(player: AVAudioPlayer) {

        println("audioPlayerBeginInterruption")

        if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
            playbackTimer.invalidate()
        }
    }

    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {

        println("audioPlayerDecodeErrorDidOccur")
    }

    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {

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

    func audioPlayerEndInterruption(player: AVAudioPlayer) {

        println("audioPlayerEndInterruption")
    }
}

// MARK: UIImagePicker

extension ConversationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {

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

                    if let fixedImage = image.navi_resizeToSize(fixedSize, withInterpolationQuality: CGInterpolationQuality.Medium) {
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

        if let thumbnail = image.navi_resizeToSize(CGSize(width: thumbnailWidth, height: thumbnailHeight), withInterpolationQuality: CGInterpolationQuality.Low) {
            let blurredThumbnail = thumbnail.blurredImageWithRadius(5, iterations: 7, tintColor: UIColor.clearColor())

            let data = UIImageJPEGRepresentation(blurredThumbnail, 0.7)

            let string = data!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))

            println("image blurredThumbnail string length: \(string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))\n")

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

        if let imageMetaData = try? NSJSONSerialization.dataWithJSONObject(audioMetaDataInfo, options: []) {
            let imageMetaDataString = NSString(data: imageMetaData, encoding: NSUTF8StringEncoding) as? String
            metaData = imageMetaDataString
        }

        // Do send

        let imageData = UIImageJPEGRepresentation(image, YepConfig.messageImageCompressionQuality())!

        let messageImageName = NSUUID().UUIDString

        if let withFriend = conversation.withFriend {

            sendImageInFilePath(nil, orFileData: imageData, metaData: metaData, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { [weak self] message in

                dispatch_async(dispatch_get_main_queue()) {

                    if let _ = NSFileManager.saveMessageImageData(imageData, withName: messageImageName) {
                        if let realm = message.realm {
                            let _ = try? realm.write {
                                message.localAttachmentName = messageImageName
                                message.mediaType = MessageMediaType.Image.rawValue
                                if let metaDataString = metaData {
                                    message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                                }
                            }
                        }
                    }

                    self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                    })
                }

            }, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason, errorMessage: errorMessage)

                YepAlert.alertSorry(message: NSLocalizedString("Failed to send image!\nTry tap on message to resend.", comment: ""), inViewController: self)

            }, completion: { success -> Void in
                println("sendImage to friend: \(success)")
            })

        } else if let withGroup = conversation.withGroup {

            sendImageInFilePath(nil, orFileData: imageData, metaData: metaData, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { [weak self] message in

                dispatch_async(dispatch_get_main_queue()) {
                    if let _ = NSFileManager.saveMessageImageData(imageData, withName: messageImageName) {
                        if let realm = message.realm {
                            let _ = try? realm.write {
                                message.localAttachmentName = messageImageName
                                message.mediaType = MessageMediaType.Image.rawValue
                                if let metaDataString = metaData {
                                    message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                                }
                            }
                        }
                    }
                    
                    self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                    })
                }
                
            }, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason, errorMessage: errorMessage)

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

            if let thumbnail = image.navi_resizeToSize(CGSize(width: thumbnailWidth, height: thumbnailHeight), withInterpolationQuality: CGInterpolationQuality.Low) {
                let blurredThumbnail = thumbnail.blurredImageWithRadius(5, iterations: 7, tintColor: UIColor.clearColor())

                let data = UIImageJPEGRepresentation(blurredThumbnail, 0.7)!

                let string = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))

                println("video blurredThumbnail string length: \(string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))\n")

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

            if let videoMetaData = try? NSJSONSerialization.dataWithJSONObject(videoMetaDataInfo, options: []) {
                let videoMetaDataString = NSString(data: videoMetaData, encoding: NSUTF8StringEncoding) as? String
                metaData = videoMetaDataString
            }

            thumbnailData = UIImageJPEGRepresentation(image, YepConfig.messageImageCompressionQuality())
        }

        let messageVideoName = NSUUID().UUIDString

        let afterCreatedMessageAction = { [weak self] (message: Message) in

            dispatch_async(dispatch_get_main_queue()) {

                if let videoData = NSData(contentsOfURL: videoURL) {

                    if let _ = NSFileManager.saveMessageVideoData(videoData, withName: messageVideoName) {
                        if let realm = message.realm {
                            let _ = try? realm.write {

                                if let thumbnailData = thumbnailData {
                                    if let _ = NSFileManager.saveMessageImageData(thumbnailData, withName: messageVideoName) {
                                        message.localThumbnailName = messageVideoName
                                    }
                                }

                                message.localAttachmentName = messageVideoName

                                message.mediaType = MessageMediaType.Video.rawValue
                                if let metaDataString = metaData {
                                    message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                                }
                            }
                        }
                    }

                    self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                    })
                }
            }
        }

        if let withFriend = conversation.withFriend {

            sendVideoInFilePath(videoURL.path!, orFileData: nil, metaData: metaData, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: afterCreatedMessageAction, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason, errorMessage: errorMessage)

                YepAlert.alertSorry(message: NSLocalizedString("Failed to send video!\nTry tap on message to resend.", comment: ""), inViewController: self)

            }, completion: { success in
                println("sendVideo to friend: \(success)")
            })

        } else if let withGroup = conversation.withGroup {

            sendVideoInFilePath(videoURL.path!, orFileData: nil, metaData: metaData, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: afterCreatedMessageAction, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason, errorMessage: errorMessage)

                YepAlert.alertSorry(message: NSLocalizedString("Failed to send video!\nTry tap on message to resend.", comment: ""), inViewController: self)

            }, completion: { success in
                println("sendVideo to group: \(success)")
            })
        }
    }
}

