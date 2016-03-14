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
import MonkeyKing

struct MessageNotification {
    static let MessageStateChanged = "MessageStateChangedNotification"
    static let MessageBatchMarkAsRead = "MessageBatchMarkAsReadNotification"
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
            realm.beginWrite()
            let user = getOrCreateUserWithDiscoverUser(discoveredFeed.creator, inRealm: realm)
            let _ = try? realm.commitWrite()

            return user

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

    var kind: FeedKind? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            return discoveredFeed.kind
        case .FeedType(let feed):
            return FeedKind(rawValue: feed.kind)
        }
    }

    var hasSocialImage: Bool {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            return discoveredFeed.hasSocialImage
        case .FeedType(let feed):
            if let _ = feed.socialWork?.dribbbleShot?.imageURLString {
                return true
            }
        }

        return false
    }

    var hasMapImage: Bool {

        if let kind = kind {
            switch kind {
            case .Location:
                return true
            default:
                return false
            }
        }

        return false
    }

    var hasAttachment: Bool {

        guard let kind = kind else {
            return false
        }

        return kind != .Text
    }

    var githubRepoName: String? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .Github(githubRepo) = attachment {
                    return githubRepo.name
                }
            }
        case .FeedType(let feed):
            return feed.socialWork?.githubRepo?.name
        }

        return nil
    }

    var githubRepoDescription: String? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .Github(githubRepo) = attachment {
                    return githubRepo.description
                }
            }
        case .FeedType(let feed):
            return feed.socialWork?.githubRepo?.repoDescription
        }

        return nil
    }

    var githubRepoURL: NSURL? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .Github(githubRepo) = attachment {
                    return NSURL(string: githubRepo.URLString)
                }
            }
        case .FeedType(let feed):
            if let URLString = feed.socialWork?.githubRepo?.URLString {
                return NSURL(string: URLString)
            }
        }

        return nil
    }

    var dribbbleShotImageURL: NSURL? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .Dribbble(dribbbleShot) = attachment {
                    return NSURL(string: dribbbleShot.imageURLString)
                }
            }
        case .FeedType(let feed):
            if let imageURLString = feed.socialWork?.dribbbleShot?.imageURLString {
                return NSURL(string: imageURLString)
            }
        }

        return nil
    }

    var dribbbleShotURL: NSURL? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .Dribbble(dribbbleShot) = attachment {
                    return NSURL(string: dribbbleShot.htmlURLString)
                }
            }
        case .FeedType(let feed):
            if let htmlURLString = feed.socialWork?.dribbbleShot?.htmlURLString {
                return NSURL(string: htmlURLString)
            }
        }

        return nil
    }

    var audioMetaInfo: (duration: NSTimeInterval, samples: [CGFloat])? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .Audio(audioInfo) = attachment {
                    return (audioInfo.duration, audioInfo.sampleValues)
                }
            }
        case .FeedType(let feed):
            if let audioMetaInfo = feed.audio?.audioMetaInfo {
                return audioMetaInfo
            }
        }

        return nil
    }

    var locationName: String? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .Location(locationInfo) = attachment {
                    return locationInfo.name
                }
            }
        case .FeedType(let feed):
            if let location = feed.location {
                return location.name
            }
        }

        return nil
    }

    var locationCoordinate: CLLocationCoordinate2D? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .Location(locationInfo) = attachment {
                    return locationInfo.coordinate
                }
            }
        case .FeedType(let feed):
            if let location = feed.location {
                return location.coordinate?.locationCoordinate
            }
        }

        return nil
    }

    var openGraphInfo: OpenGraphInfoType? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .URL(openGraphInfo) = attachment {
                    return openGraphInfo
                }
            }
        case .FeedType(let feed):
            if let openGraphInfo = feed.openGraphInfo {
                return openGraphInfo
            }
        }

        return nil
    }

    var attachments: [Attachment] {
        switch self {
        case .DiscoveredFeedType(let discoveredFeed):

            if let attachment = discoveredFeed.attachment {
                if case let .Images(attachments) = attachment {
                    return attachmentFromDiscoveredAttachment(attachments)
                }
            }

            return []

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

    var conversation: Conversation!
    var conversationFeed: ConversationFeed?

    var afterSentMessageAction: (() -> Void)?
    var afterDeletedFeedAction: ((feedID: String) -> Void)?
    var conversationDirtyAction: (() -> Void)?
    var conversationIsDirty = false
    var syncPlayFeedAudioAction: (() -> Void)?

    private var needDetectMention = false {
        didSet {
            messageToolbar.needDetectMention = needDetectMention
        }
    }

    private var selectedIndexPathForMenu: NSIndexPath?

    private var realm: Realm!

    private var groupShareURLString: String?

    private lazy var messages: Results<Message> = {
        return messagesOfConversation(self.conversation, inRealm: self.realm)
    }()

    private let messagesBunchCount = 20 // TODO: 分段载入的“一束”消息的数量
    private var displayedMessagesRange = NSRange() {
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
    private var lastTimeMessagesCount: Int = 0

    // 位于后台时收到的消息
    private var inActiveNewMessageIDSet = Set<String>()

    private lazy var sectionDateFormatter: NSDateFormatter =  {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        return dateFormatter
    }()

    private lazy var sectionDateInCurrentWeekFormatter: NSDateFormatter =  {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEEE HH:mm"
        return dateFormatter
    }()

    //var messagePreviewTransitionManager: ConversationMessagePreviewTransitionManager?
    //var navigationControllerDelegate: ConversationMessagePreviewNavigationControllerDelegate?

    private var conversationCollectionViewHasBeenMovedToBottomOnce = false

    private var checkTypingStatusTimer: NSTimer?
    private var typingResetDelay: Float = 0

    // KeyboardMan 帮助我们做键盘动画
    private let keyboardMan = KeyboardMan()
    private var giveUpKeyboardHideAnimationWhenViewControllerDisapeear = false

    private var isFirstAppear = true

    private lazy var titleView: ConversationTitleView = {
        let titleView = ConversationTitleView(frame: CGRect(origin: CGPointZero, size: CGSize(width: 150, height: 44)))

        if nameOfConversation(self.conversation) != "" {
            titleView.nameLabel.text = nameOfConversation(self.conversation)
        } else {
            titleView.nameLabel.text = NSLocalizedString("Discussion", comment: "")
        }

        self.updateStateInfoOfTitleView(titleView)

        titleView.userInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: "showFriendProfile:")

        titleView.addGestureRecognizer(tap)

        return titleView
    }()

    @objc private func showFriendProfile(sender: UITapGestureRecognizer) {
        if let user = conversation.withFriend {
            performSegueWithIdentifier("showProfile", sender: user)
        }
    }

    private lazy var moreViewManager: ConversationMoreViewManager = {

        let manager = ConversationMoreViewManager()

        manager.conversation = self.conversation

        manager.showProfileAction = { [weak self] in
            self?.performSegueWithIdentifier("showProfile", sender: nil)
        }

        manager.toggleDoNotDisturbAction = { [weak self] in
            self?.toggleDoNotDisturb()
        }

        manager.reportAction = { [weak self] in
            self?.tryReport()
        }

        manager.toggleBlockAction = { [weak self] in
            self?.toggleBlock()
        }

        manager.shareFeedAction = { [weak self] in
            guard let
                description = self?.conversation.withGroup?.withFeed?.body,
                groupID = self?.conversation.withGroup?.groupID else {
                    return
            }

            guard let groupShareURLString = self?.groupShareURLString else {

                shareURLStringOfGroupWithGroupID(groupID, failureHandler: nil, completion: { [weak self] groupShareURLString in

                    self?.groupShareURLString = groupShareURLString

                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        self?.shareFeedWithDescripion(description, groupShareURLString: groupShareURLString)
                    }
                })

                return
            }

            self?.shareFeedWithDescripion(description, groupShareURLString: groupShareURLString)
        }

        manager.updateGroupAffairAction = { [weak self, weak manager] in
            self?.tryUpdateGroupAffair(afterSubscribed: { [weak self] in
                guard let strongSelf = self else { return }
                manager?.updateForGroupAffair()

                if strongSelf.isSubscribeViewShowing {
                    strongSelf.subscribeView.hide()
                }
            })
        }

        manager.afterGotSettingsForUserAction = { [weak self] userID, blocked, doNotDisturb in
            self?.updateNotificationEnabled(!doNotDisturb, forUserWithUserID: userID)
            self?.updateBlocked(blocked, forUserWithUserID: userID)
        }

        manager.afterGotSettingsForGroupAction = { [weak self] groupID, notificationEnabled in
            self?.updateNotificationEnabled(notificationEnabled, forGroupWithGroupID: groupID)
        }

        return manager
    }()

    private lazy var moreMessageTypesView: MoreMessageTypesView = {

        let view =  MoreMessageTypesView()

        view.alertCanNotAccessCameraRollAction = { [weak self] in
            self?.alertCanNotAccessCameraRoll()
        }

        view.sendImageAction = { [weak self] image in
            self?.sendImage(image)
        }

        view.takePhotoAction = { [weak self] in

            let openCamera: ProposerAction = { [weak self] in

                guard UIImagePickerController.isSourceTypeAvailable(.Camera) else {
                    self?.alertCanNotOpenCamera()
                    return
                }

                if let strongSelf = self {
                    strongSelf.imagePicker.sourceType = .Camera
                    strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
                }
            }

            proposeToAccess(.Camera, agreed: openCamera, rejected: {
                self?.alertCanNotOpenCamera()
            })
        }

        view.choosePhotoAction = { [weak self] in

            let openCameraRoll: ProposerAction = { [weak self] in

                guard UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) else {
                    self?.alertCanNotAccessCameraRoll()
                    return
                }

                if let strongSelf = self {
                    strongSelf.imagePicker.sourceType = .PhotoLibrary
                    strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
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

    /*
    private lazy var pullToRefreshView: PullToRefreshView = {

        let pullToRefreshView = PullToRefreshView()
        pullToRefreshView.delegate = self

        self.conversationCollectionView.insertSubview(pullToRefreshView, atIndex: 0)

        pullToRefreshView.translatesAutoresizingMaskIntoConstraints = false

        let viewsDictionary = [
            "pullToRefreshView": pullToRefreshView,
            "view": self.view,
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(-200)-[pullToRefreshView(200)]", options: [], metrics: nil, views: viewsDictionary)

        // 非常奇怪，若直接用 "H:|[pullToRefreshView]|" 得到的实际宽度为 0
        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[pullToRefreshView(==view)]|", options: [], metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints(constraintsH)

        return pullToRefreshView
    }()
    */

    private lazy var waverView: YepWaverView = {
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
    private var samplesCount = 0
    private let samplingInterval = 6

    private var feedView: FeedView?
    private var dragBeginLocation: CGPoint?

    private var isSubscribeViewShowing = false
    private lazy var subscribeView: SubscribeView = {
        let view = SubscribeView()

        self.view.insertSubview(view, belowSubview: self.messageToolbar)

        view.translatesAutoresizingMaskIntoConstraints = false

        let leading = NSLayoutConstraint(item: view, attribute: .Leading, relatedBy: .Equal, toItem: self.messageToolbar, attribute: .Leading, multiplier: 1.0, constant: 0)
        let trailing = NSLayoutConstraint(item: view, attribute: .Trailing, relatedBy: .Equal, toItem: self.messageToolbar, attribute: .Trailing, multiplier: 1.0, constant: 0)
        let bottom = NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: self.messageToolbar, attribute: .Top, multiplier: 1.0, constant: SubscribeView.height)
        let height = NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: SubscribeView.height)

        NSLayoutConstraint.activateConstraints([leading, trailing, bottom, height])
        self.view.layoutIfNeeded()

        view.bottomConstraint = bottom

        return view
    }()

    private lazy var mentionView: MentionView = {
        let view = MentionView()

        self.view.insertSubview(view, belowSubview: self.messageToolbar)

        view.translatesAutoresizingMaskIntoConstraints = false

        let top = NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .GreaterThanOrEqual, toItem: self.topLayoutGuide, attribute: .Bottom, multiplier: 1.0, constant: 0)

        let leading = NSLayoutConstraint(item: view, attribute: .Leading, relatedBy: .Equal, toItem: self.messageToolbar, attribute: .Leading, multiplier: 1.0, constant: 0)
        let trailing = NSLayoutConstraint(item: view, attribute: .Trailing, relatedBy: .Equal, toItem: self.messageToolbar, attribute: .Trailing, multiplier: 1.0, constant: 0)
        let bottom = NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: self.messageToolbar, attribute: .Top, multiplier: 1.0, constant: MentionView.height)
        let height = NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: MentionView.height)

        bottom.priority = UILayoutPriorityDefaultHigh

        NSLayoutConstraint.activateConstraints([top, leading, trailing, bottom, height])
        self.view.layoutIfNeeded()

        view.heightConstraint = height
        view.bottomConstraint = bottom

        view.pickUserAction = { [weak self] username in
            self?.messageToolbar.replaceMentionedUsername(username)
            self?.mentionView.hide()
        }

        return view
    }()

    @IBOutlet private weak var conversationCollectionView: UICollectionView!
    private let conversationCollectionViewContentInsetYOffset: CGFloat = 5

    @IBOutlet private weak var messageToolbar: MessageToolbar!
    @IBOutlet private weak var messageToolbarBottomConstraint: NSLayoutConstraint!

    @IBOutlet private weak var swipeUpView: UIView!
    @IBOutlet private weak var swipeUpPromptLabel: UILabel!

    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private var isTryingShowFriendRequestView = false

    //var originalNavigationControllerDelegate: UINavigationControllerDelegate?

    private let sectionInsetTop: CGFloat = 10
    private let sectionInsetBottom: CGFloat = 10

    private lazy var messageTextLabelMaxWidth: CGFloat = {
        let maxWidth = self.collectionViewWidth - (YepConfig.chatCellGapBetweenWallAndAvatar() + YepConfig.chatCellAvatarSize() + YepConfig.chatCellGapBetweenTextContentLabelAndAvatar() + YepConfig.chatTextGapBetweenWallAndContentLabel())
        return maxWidth
    }()

    private lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.conversationCollectionView.bounds)
    }()

    private lazy var messageImagePreferredWidth: CGFloat = {
        return YepConfig.ChatCell.mediaPreferredWidth
    }()
    private lazy var messageImagePreferredHeight: CGFloat = {
        return YepConfig.ChatCell.mediaPreferredHeight
    }()

    private let messageImagePreferredAspectRatio: CGFloat = 4.0 / 3.0

    private lazy var imagePicker: UIImagePickerController = {
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

    private let loadMoreCollectionViewCellID = "LoadMoreCollectionViewCell"
    private let chatSectionDateCellIdentifier = "ChatSectionDateCell"
    private let chatLeftTextCellIdentifier = "ChatLeftTextCell"
    private let chatRightTextCellIdentifier = "ChatRightTextCell"
    private let chatLeftTextURLCellIdentifier = "ChatLeftTextURLCell"
    private let chatRightTextURLCellIdentifier = "ChatRightTextURLCell"
    private let chatLeftImageCellIdentifier = "ChatLeftImageCell"
    private let chatRightImageCellIdentifier = "ChatRightImageCell"
    private let chatLeftAudioCellIdentifier = "ChatLeftAudioCell"
    private let chatRightAudioCellIdentifier = "ChatRightAudioCell"
    private let chatLeftVideoCellIdentifier = "ChatLeftVideoCell"
    private let chatRightVideoCellIdentifier = "ChatRightVideoCell"
    private let chatLeftLocationCellIdentifier =  "ChatLeftLocationCell"
    private let chatRightLocationCellIdentifier =  "ChatRightLocationCell"
    private let chatLeftRecallCellIdentifier =  "ChatLeftRecallCell"
    private let chatLeftSocialWorkCellIdentifier = "ChatLeftSocialWorkCell"

    private struct Listener {
        static let Avatar = "ConversationViewController"
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)

        YepUserDefaults.avatarURLString.removeListenerWithName(Listener.Avatar)

        conversationCollectionView?.delegate = nil

        println("deinit ConversationViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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


        let moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_more"), style: UIBarButtonItemStyle.Plain, target: self, action: "moreAction:")
        navigationItem.rightBarButtonItem = moreBarButtonItem


        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleReceivedNewMessagesNotification:", name: YepConfig.Notification.newMessages, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleDeletedMessagesNotification:", name: YepConfig.Notification.deletedMessages, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "cleanForLogout:", name: EditProfileViewController.Notification.Logout, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "tryInsertInActiveNewMessages:", name: AppDelegate.Notification.applicationDidBecomeActive, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didRecieveMenuWillShowNotification:", name: UIMenuControllerWillShowMenuNotification, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didRecieveMenuWillHideNotification:", name: UIMenuControllerWillHideMenuNotification, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "messagesMarkAsReadByRecipient:", name: MessageNotification.MessageBatchMarkAsRead, object: nil)

        YepUserDefaults.avatarURLString.bindListener(Listener.Avatar) { [weak self] _ in
            dispatch_async(dispatch_get_main_queue()) {
                self?.reloadConversationCollectionView()
            }
        }

        swipeUpView.hidden = true

        conversationCollectionView.keyboardDismissMode = .OnDrag

        conversationCollectionView.alwaysBounceVertical = true

        conversationCollectionView.registerNib(UINib(nibName: loadMoreCollectionViewCellID, bundle: nil), forCellWithReuseIdentifier: loadMoreCollectionViewCellID)

        conversationCollectionView.registerNib(UINib(nibName: chatSectionDateCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatSectionDateCellIdentifier)

        conversationCollectionView.registerClass(ChatLeftTextCell.self, forCellWithReuseIdentifier: chatLeftTextCellIdentifier)
        conversationCollectionView.registerClass(ChatRightTextCell.self, forCellWithReuseIdentifier: chatRightTextCellIdentifier)

        conversationCollectionView.registerClass(ChatLeftTextURLCell.self, forCellWithReuseIdentifier: chatLeftTextURLCellIdentifier)
        conversationCollectionView.registerClass(ChatRightTextURLCell.self, forCellWithReuseIdentifier: chatRightTextURLCellIdentifier)

        conversationCollectionView.registerClass(ChatLeftImageCell.self, forCellWithReuseIdentifier: chatLeftImageCellIdentifier)
        conversationCollectionView.registerClass(ChatRightImageCell.self, forCellWithReuseIdentifier: chatRightImageCellIdentifier)

        conversationCollectionView.registerClass(ChatLeftAudioCell.self, forCellWithReuseIdentifier: chatLeftAudioCellIdentifier)
        conversationCollectionView.registerClass(ChatRightAudioCell.self, forCellWithReuseIdentifier: chatRightAudioCellIdentifier)

        conversationCollectionView.registerClass(ChatLeftVideoCell.self, forCellWithReuseIdentifier: chatLeftVideoCellIdentifier)
        conversationCollectionView.registerClass(ChatRightVideoCell.self, forCellWithReuseIdentifier: chatRightVideoCellIdentifier)

        conversationCollectionView.registerClass(ChatLeftLocationCell.self, forCellWithReuseIdentifier: chatLeftLocationCellIdentifier)
        conversationCollectionView.registerClass(ChatRightLocationCell.self, forCellWithReuseIdentifier: chatRightLocationCellIdentifier)

        conversationCollectionView.registerClass(ChatLeftRecallCell.self, forCellWithReuseIdentifier: chatLeftRecallCellIdentifier)

        conversationCollectionView.registerNib(UINib(nibName: chatLeftSocialWorkCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatLeftSocialWorkCellIdentifier)

        conversationCollectionView.bounces = true

        let tap = UITapGestureRecognizer(target: self, action: "tapToCollapseMessageToolBar:")
        conversationCollectionView.addGestureRecognizer(tap)

        messageToolbarBottomConstraint.constant = 0

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

        // sync messages

        let syncMessages: (failedAction: (() -> Void)?, successAction: (() -> Void)?) -> Void = { failedAction, successAction in
            dispatch_async(dispatch_get_main_queue()) { [weak self] in

                if let recipient = self?.conversation.recipient {

                    let timeDirection: TimeDirection
                    if let minMessageID = self?.messages.last?.messageID {
                        timeDirection = .Future(minMessageID: minMessageID)
                    } else {
                        timeDirection = .None

                        self?.activityIndicator.startAnimating()
                    }

                    dispatch_async(realmQueue) { [weak self] in

                        messagesFromRecipient(recipient, withTimeDirection: timeDirection, failureHandler: { reason, errorMessage in
                            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                            failedAction?()

                        }, completion: { messageIDs in
                            println("messagesFromRecipient: \(messageIDs.count)")

                            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                                tryPostNewMessagesReceivedNotificationWithMessageIDs(messageIDs, messageAge: timeDirection.messageAge)
                                //self?.fayeRecievedNewMessages(messageIDs, messageAgeRawValue: timeDirection.messageAge.rawValue)

                                self?.activityIndicator.stopAnimating()
                            }

                            successAction?()
                        })
                    }
                }
            }
        }

        switch conversation.type {

        case ConversationType.OneToOne.rawValue:
            syncMessages(failedAction: nil, successAction: nil)
            syncMessagesReadStatus()

        case ConversationType.Group.rawValue:

            if let group = conversation.withGroup {

                let groupIncludeMe = group.includeMe
                let groupID = group.groupID

                // 直接同步消息
                syncMessages(failedAction: {
                }, successAction: {
                    if groupIncludeMe {
                        FayeService.sharedManager.subscribeGroup(groupID: groupID)
                    }
                })
            }

        default:
            break
        }

        tryShowSubscribeView()

        needDetectMention = conversation.needDetectMention

        #if DEBUG
            //view.addSubview(conversationFPSLabel)
        #endif
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

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
                        dispatch_async(dispatch_get_main_queue()) { [weak self] in

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
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
        setNeedsStatusBarAppearanceUpdate()

        conversationCollectionViewHasBeenMovedToBottomOnce = true

        FayeService.sharedManager.delegate = self

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
            checkTypingStatusTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("checkTypingStatus:"), userInfo: nil, repeats: true)
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

                self?.trySnapContentOfConversationCollectionViewToBottom()

                if text.isEmpty {
                    return
                }

                if let withFriend = self?.conversation.withFriend {

                    sendText(text, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { [weak self] message in

                        dispatch_async(dispatch_get_main_queue()) {
                            self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                            })
                        }

                    }, failureHandler: { [weak self] reason, errorMessage in
                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

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
                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                        dispatch_async(dispatch_get_main_queue()) {
                            YepAlert.alertSorry(message: NSLocalizedString("Failed to send text!\nTry tap on message to resend.", comment: ""), inViewController: self)
                        }

                    }, completion: { success in
                        println("sendText to group: \(success)")
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
                            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

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

    private func batchMarkMessagesAsReaded(updateOlderMessagesIfNeeded updateOlderMessagesIfNeeded: Bool = true) {

        if let recipient = conversation.recipient, latestMessage = messages.last {

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

                let filteredMessages = messages.filter(predicate)

                println("filteredMessages.count: \(filteredMessages.count)")
                println("conversation.unreadMessagesCount: \(conversation.unreadMessagesCount)")

                needMarkInServer = (!filteredMessages.isEmpty || (conversation.unreadMessagesCount > 0))

                filteredMessages.forEach { message in
                    let _ = try? realm.write {
                        message.readed = true
                    }
                }

            } else {
                let _ = try? realm.write {
                    latestMessage.readed = true
                }

                needMarkInServer = true

                println("mark latestMessage readed")
            }

            // 群组里没有我，不需要标记
            if recipient.type == .Group {
                if let group = conversation.withGroup where !group.includeMe {

                    // 此情况强制所有消息“已读”
                    let _ = try? realm.write {
                        messages.forEach { message in
                            message.readed = true
                        }
                    }

                    needMarkInServer = false
                }
            }

            if needMarkInServer {

                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.markAsReaded, object: nil)
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
            conversationDirtyAction?()
        }

        if let checkTypingStatusTimer = checkTypingStatusTimer {
            checkTypingStatusTimer.invalidate()
        }

        NSNotificationCenter.defaultCenter().postNotificationName(MessageToolbar.Notification.updateDraft, object: nil)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        FayeService.sharedManager.delegate = nil
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

            // 尽量滚到底部
            tryScrollToBottom()
        }
    }

    // MARK: UI

    private func tryShowFriendRequestView() {

        if let user = conversation.withFriend {

            // 若是陌生人或还未收到回应才显示 FriendRequestView
            if user.friendState != UserFriendState.Stranger.rawValue && user.friendState != UserFriendState.IssuedRequest.rawValue {
                return
            }

            let userID = user.userID
            let userNickname = user.nickname

            stateOfFriendRequestWithUser(user, failureHandler: { reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

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

    private func makeFriendRequestViewWithUser(user: User, state: FriendRequestView.State) {

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

        feedView.syncPlayAudioAction = { [weak self] in
            self?.syncPlayFeedAudioAction?()
        }

        feedView.tapAvatarAction = { [weak self] in
            self?.performSegueWithIdentifier("showProfileFromFeedView", sender: nil)
        }

        feedView.foldAction = { [weak self] in
            if let strongSelf = self {
                UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
                    self?.conversationCollectionView.contentInset.top = 64 + FeedView.foldHeight + strongSelf.conversationCollectionViewContentInsetYOffset
                }, completion: { _ in })
            }
        }

        feedView.unfoldAction = { [weak self] feedView in
            if let strongSelf = self {
                UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
                    self?.conversationCollectionView.contentInset.top = 64 + feedView.normalHeight + strongSelf.conversationCollectionViewContentInsetYOffset
                }, completion: { _ in })
            }
        }

        feedView.tapMediaAction = { [weak self] transitionView, image, attachments, index in

            guard image != nil else {
                return
            }

            let vc = UIStoryboard(name: "MediaPreview", bundle: nil).instantiateViewControllerWithIdentifier("MediaPreviewViewController") as! MediaPreviewViewController

            vc.previewMedias = attachments.map({ PreviewMedia.AttachmentType(attachment: $0) })
            vc.startIndex = index

            let transitionView = transitionView
            let frame = transitionView.convertRect(transitionView.frame, toView: self?.view)
            vc.previewImageViewInitalFrame = frame
            vc.bottomPreviewImage = image

            vc.transitionView = transitionView

            self?.view.endEditing(true)

            delay(0.3, work: { () -> Void in
                transitionView.alpha = 0 // 加 Delay 避免图片闪烁
            })

            vc.afterDismissAction = { [weak self] in
                transitionView.alpha = 1
                self?.view.window?.makeKeyAndVisible()
            }

            mediaPreviewWindow.rootViewController = vc
            mediaPreviewWindow.windowLevel = UIWindowLevelAlert - 1
            mediaPreviewWindow.makeKeyAndVisible()
        }

        feedView.tapGithubRepoAction = { [weak self] URL in
            self?.yep_openURL(URL)
        }

        feedView.tapDribbbleShotAction = { [weak self] URL in
            self?.yep_openURL(URL)
        }

        feedView.tapLocationAction = { locationName, locationCoordinate in

            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
            mapItem.name = locationName

            mapItem.openInMapsWithLaunchOptions(nil)
        }

        feedView.tapURLInfoAction = { [weak self] URL in
            println("tapURLInfoAction URL: \(URL)")
            self?.yep_openURL(URL)
        }

        feedView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(feedView)

        let views = [
            "feedView": feedView
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[feedView]|", options: [], metrics: nil, views: views)

        let top = NSLayoutConstraint(item: feedView, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1.0, constant: 64)
        let height = NSLayoutConstraint(item: feedView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: feedView.normalHeight)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints([top, height])

        feedView.heightConstraint = height

        self.feedView = feedView

        // set messageToolbar's top limited to feedView
        do {
            let top = NSLayoutConstraint(item: messageToolbar, attribute: .Top, relatedBy: .GreaterThanOrEqual, toItem: feedView, attribute: .Bottom, multiplier: 1.0, constant: 0)
            NSLayoutConstraint.activateConstraints([top])
        }
    }

    private func tryUpdateConversationCollectionViewWith(newContentInsetBottom bottom: CGFloat, newContentOffsetY: CGFloat) {

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

    private func setConversaitonCollectionViewOriginalContentInset() {

        let feedViewHeight: CGFloat = (feedView == nil) ? 0 : feedView!.height
        conversationCollectionView.contentInset.top = 64 + feedViewHeight + conversationCollectionViewContentInsetYOffset

        let messageToolbarHeight = messageToolbar.bounds.height
        conversationCollectionView.contentInset.bottom = messageToolbarHeight + sectionInsetBottom
        conversationCollectionView.scrollIndicatorInsets.bottom = messageToolbarHeight
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

            if message.deletedByCreator {
                height = 26

            } else {
                let rect = message.textContent.boundingRectWithSize(CGSize(width: messageTextLabelMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.ChatCell.textAttributes, context: nil)

                height = max(ceil(rect.height) + (11 * 2), YepConfig.chatCellAvatarSize())

                if message.openGraphInfo != nil {
                    height += 100 + 10
                }

                if !key.isEmpty {
                    textContentLabelWidths[key] = ceil(rect.width)
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

        default:
            height = 20
        }

        // inGroup, plus height for show name
        if conversation.withGroup != nil {
            if message.mediaType != MessageMediaType.SectionDate.rawValue && !message.deletedByCreator {
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
    private func clearHeightOfMessageWithKey(key: String) {
        messageHeights[key] = nil
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

    private var audioPlayedDurations = [String: NSTimeInterval]()

    private func audioPlayedDurationOfMessage(message: Message) -> NSTimeInterval {
        let key = message.messageID

        if !key.isEmpty {
            if let playedDuration = audioPlayedDurations[key] {
                return playedDuration
            }
        }

        return 0
    }

    private func setAudioPlayedDuration(audioPlayedDuration: NSTimeInterval, ofMessage message: Message) {
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

    @objc private func updateAudioPlaybackProgress(timer: NSTimer) {

        func updateAudioCellOfMessage(message: Message, withCurrentTime currentTime: NSTimeInterval) {

            if let messageIndex = messages.indexOf(message) {

                let indexPath = NSIndexPath(forItem: messageIndex - displayedMessagesRange.location, inSection: Section.Message.rawValue)

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

    private func syncMessagesReadStatus() {

        if let recipient = conversation.recipient {
            lastMessageReadByRecipient(recipient, failureHandler: nil, completion: { [weak self] lastMessageRead in

                if let lastMessageRead = lastMessageRead {
                    self?.markAsReadAllSentMesagesBeforeUnixTime(lastMessageRead.unixTime, lastReadMessageID: lastMessageRead.messageID)
                }
            })
        }
    }

    private func markAsReadAllSentMesagesBeforeUnixTime(unixTime: NSTimeInterval, lastReadMessageID: String? = nil) {

        dispatch_async(dispatch_get_main_queue()) { [weak self] in

            guard let recipient = self?.conversation.recipient else {
                return
            }

            dispatch_async(realmQueue) {

                guard let realm = try? Realm(), conversation = recipient.conversationInRealm(realm) else {
                    return
                }

                var lastMessageCreatedUnixTime = unixTime
                //println("markAsReadAllSentMesagesBeforeUnixTime: \(unixTime), \(lastReadMessageID)")
                if let lastReadMessageID = lastReadMessageID, message = messageWithMessageID(lastReadMessageID, inRealm: realm) {
                    let createdUnixTime = message.createdUnixTime
                    //println("lastMessageCreatedUnixTime: \(createdUnixTime)")
                    if createdUnixTime > lastMessageCreatedUnixTime {
                        println("NOTICE: markAsReadAllSentMesagesBeforeUnixTime: \(unixTime), lastMessageCreatedUnixTime: \(createdUnixTime)")
                        lastMessageCreatedUnixTime = createdUnixTime
                    }
                }

                let predicate = NSPredicate(format: "readed = false AND fromFriend != nil AND fromFriend.friendState = %d AND createdUnixTime <= %lf", UserFriendState.Me.rawValue, lastMessageCreatedUnixTime)

                let unreadMessages = messagesOfConversation(conversation, inRealm: realm).filter(predicate)

                let _ = try? realm.write {
                    unreadMessages.forEach {

                        $0.readed = true
                        $0.sendState = MessageSendState.Read.rawValue
                    }
                }

                delay(0.5) {
                    NSNotificationCenter.defaultCenter().postNotificationName(MessageNotification.MessageStateChanged, object: nil)
                }
            }
        }
    }

    private func tryShowSubscribeView() {

        guard let group = conversation.withGroup where !group.includeMe else {
            return
        }

        let groupID = group.groupID

        meIsMemberOfGroup(groupID: groupID, failureHandler: nil, completion: { meIsMember in

            println("meIsMember: \(meIsMember)")

            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                if let strongSelf = self {
                    let _ = try? strongSelf.realm.write {
                        group.includeMe = meIsMember
                    }
                }
            }

            guard !meIsMember else {
                return
            }

            delay(3) { [weak self] in

                guard !group.includeMe else {
                    return
                }

                self?.subscribeView.subscribeAction = { [weak self] in
                    joinGroup(groupID: groupID, failureHandler: nil, completion: {
                        println("subscribe OK")

                        dispatch_async(dispatch_get_main_queue()) { [weak self] in
                            if let strongSelf = self {
                                let _ = try? strongSelf.realm.write {
                                    group.includeMe = true
                                    strongSelf.moreViewManager.updateForGroupAffair()
                                }
                            }
                        }
                    })
                }

                self?.subscribeView.showWithChangeAction = { [weak self] in
                    if let strongSelf = self {

                        let bottom = strongSelf.view.bounds.height - strongSelf.messageToolbar.frame.origin.y + SubscribeView.height

                        let extraPart = strongSelf.conversationCollectionView.contentSize.height - (strongSelf.messageToolbar.frame.origin.y - SubscribeView.height)

                        let newContentOffsetY: CGFloat
                        if extraPart > 0 {
                            newContentOffsetY = strongSelf.conversationCollectionView.contentOffset.y + SubscribeView.height
                        } else {
                            newContentOffsetY = strongSelf.conversationCollectionView.contentOffset.y
                        }

                        //println("extraPart: \(extraPart), newContentOffsetY: \(newContentOffsetY)")

                        self?.tryUpdateConversationCollectionViewWith(newContentInsetBottom: bottom, newContentOffsetY: newContentOffsetY)

                        self?.isSubscribeViewShowing = true
                    }
                }

                self?.subscribeView.hideWithChangeAction = { [weak self] in
                    if let strongSelf = self {

                        let bottom = strongSelf.view.bounds.height - strongSelf.messageToolbar.frame.origin.y

                        let newContentOffsetY = strongSelf.conversationCollectionView.contentSize.height - strongSelf.messageToolbar.frame.origin.y

                        self?.tryUpdateConversationCollectionViewWith(newContentInsetBottom: bottom, newContentOffsetY: newContentOffsetY)

                        self?.isSubscribeViewShowing = false
                    }
                }

                self?.subscribeView.show()
            }
        })
    }

    private var isLoadingPreviousMessages = false
    private func tryLoadPreviousMessages(completion: () -> Void) {

        if isLoadingPreviousMessages {
            completion()
            return
        }

        isLoadingPreviousMessages = true

        println("tryLoadPreviousMessages")

        if displayedMessagesRange.location == 0 {

            if let recipient = conversation.recipient {

                let timeDirection: TimeDirection
                if let maxMessageID = messages.first?.messageID {
                    timeDirection = .Past(maxMessageID: maxMessageID)
                } else {
                    timeDirection = .None
                }

                messagesFromRecipient(recipient, withTimeDirection: timeDirection, failureHandler: { reason, errorMessage in
                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                    dispatch_async(dispatch_get_main_queue()) {
                        completion()
                    }

                }, completion: { messageIDs in
                    println("messagesFromRecipient: \(messageIDs.count)")

                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        tryPostNewMessagesReceivedNotificationWithMessageIDs(messageIDs, messageAge: timeDirection.messageAge)
                        //self?.fayeRecievedNewMessages(messageIDs, messageAgeRawValue: timeDirection.messageAge.rawValue)

                        self?.isLoadingPreviousMessages = false
                        completion()
                    }
                })
            }

        } else {

            var newMessagesCount = self.messagesBunchCount

            if (self.displayedMessagesRange.location - newMessagesCount) < 0 {
                newMessagesCount = self.displayedMessagesRange.location
            }

            if newMessagesCount > 0 {
                self.displayedMessagesRange.location -= newMessagesCount
                self.displayedMessagesRange.length += newMessagesCount

                self.lastTimeMessagesCount = self.messages.count // 同样需要纪录它

                var indexPaths = [NSIndexPath]()
                for i in 0..<newMessagesCount {
                    let indexPath = NSIndexPath(forItem: Int(i), inSection: Section.Message.rawValue)
                    indexPaths.append(indexPath)
                }

                let bottomOffset = self.conversationCollectionView.contentSize.height - self.conversationCollectionView.contentOffset.y

                CATransaction.begin()
                CATransaction.setDisableActions(true)

                self.conversationCollectionView.performBatchUpdates({ [weak self] in
                    self?.conversationCollectionView.insertItemsAtIndexPaths(indexPaths)

                }, completion: { [weak self] finished in
                    if let strongSelf = self {
                        var contentOffset = strongSelf.conversationCollectionView.contentOffset
                        contentOffset.y = strongSelf.conversationCollectionView.contentSize.height - bottomOffset

                        strongSelf.conversationCollectionView.setContentOffset(contentOffset, animated: false)
                        
                        CATransaction.commit()
                        
                        // 上面的 CATransaction 保证了 CollectionView 在插入后不闪动

                        self?.isLoadingPreviousMessages = false
                        completion()
                    }
                })
            }
        }
    }

    // MARK: Actions

    @objc private func messagesMarkAsReadByRecipient(notifictaion: NSNotification) {

        guard let
            messageDataInfo = notifictaion.object as? [String: AnyObject],
            lastReadUnixTime = messageDataInfo["last_read_at"] as? NSTimeInterval,
            lastReadMessageID = messageDataInfo["last_read_id"] as? String,
            recipientType = messageDataInfo["recipient_type"] as? String,
            recipientID = messageDataInfo["recipient_id"] as? String else {
                return
        }

        if recipientID == conversation.recipient?.ID && recipientType == conversation.recipient?.type.nameForServer {
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

        typingResetDelay = typingResetDelay - 0.5

        if typingResetDelay < 0 {
            self.updateStateInfoOfTitleView(titleView)
        }
    }

    private func tryScrollToBottom() {

        if displayedMessagesRange.length > 0 {

            let messageToolBarTop = messageToolbarBottomConstraint.constant + CGRectGetHeight(messageToolbar.bounds)

            let feedViewHeight: CGFloat = (feedView == nil) ? 0 : feedView!.height
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

    private func shareFeedWithDescripion(description: String, groupShareURLString: String) {

        let info = MonkeyKing.Info(
            title: NSLocalizedString("Join Us", comment: ""),
            description: description,
            thumbnail: feedView?.mediaView.imageView1.image,
            media: .URL(NSURL(string: groupShareURLString)!)
        )

        let timeLineinfo = MonkeyKing.Info(
            title: "\(NSLocalizedString("Join Us", comment: "")) \(description)",
            description: description,
            thumbnail: feedView?.mediaView.imageView1.image,
            media: .URL(NSURL(string: groupShareURLString)!)
        )

        let sessionMessage = MonkeyKing.Message.WeChat(.Session(info: info))

        let weChatSessionActivity = WeChatActivity(
            type: .Session,
            message: sessionMessage,
            finish: { success in
                println("share Feed to WeChat Session success: \(success)")
            }
        )

        let timelineMessage = MonkeyKing.Message.WeChat(.Timeline(info: timeLineinfo))

        let weChatTimelineActivity = WeChatActivity(
            type: .Timeline,
            message: timelineMessage,
            finish: { success in
                println("share Feed to WeChat Timeline success: \(success)")
            }
        )

        let shareText = "\(description) \(groupShareURLString)\n\(NSLocalizedString("From Yep", comment: ""))"

        let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: [weChatSessionActivity, weChatTimelineActivity])

        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.presentViewController(activityViewController, animated: true, completion: nil)
        }
    }

    private func updateNotificationEnabled(enabled: Bool, forUserWithUserID userID: String) {

        guard let realm = try? Realm() else {
            return
        }

        if let user = userWithUserID(userID, inRealm: realm) {
            let _ = try? realm.write {
                user.notificationEnabled = enabled
            }

            moreViewManager.userNotificationEnabled = enabled
        }
    }

    private func updateNotificationEnabled(enabled: Bool, forGroupWithGroupID: String) {

        guard let realm = try? Realm() else {
            return
        }

        if let group = groupWithGroupID(forGroupWithGroupID, inRealm: realm) {
            let _ = try? realm.write {
                group.notificationEnabled = enabled
            }

            moreViewManager.groupNotificationEnabled = enabled
        }
    }

    private func toggleDoNotDisturb() {

        if let user = conversation.withFriend {

            let userID = user.userID

            if user.notificationEnabled {
                disableNotificationFromUserWithUserID(userID, failureHandler: nil, completion: { success in
                    println("disableNotificationFromUserWithUserID \(success)")
                })

                updateNotificationEnabled(false, forUserWithUserID: userID)

            } else {
                enableNotificationFromUserWithUserID(userID, failureHandler: nil, completion: {  success in
                    println("enableNotificationFromUserWithUserID \(success)")
                })

                updateNotificationEnabled(true, forUserWithUserID: userID)
            }

        } else if let group = conversation.withGroup {

            let groupID = group.groupID

            if group.notificationEnabled {

                disableNotificationFromCircleWithCircleID(groupID, failureHandler: nil, completion: { success in
                    println("disableNotificationFromUserWithUserID \(success)")
                })

                updateNotificationEnabled(false, forGroupWithGroupID: groupID)

            } else {
                enableNotificationFromCircleWithCircleID(groupID, failureHandler: nil, completion: {success in
                    println("enableNotificationFromCircleWithCircleID \(success)")

                })

                updateNotificationEnabled(true, forGroupWithGroupID: groupID)
            }
        }
    }

    private func tryReport() {

        guard let user = conversation.withFriend else {
            return
        }

        let profileUser = ProfileUser.UserType(user)
        report(.User(profileUser))
    }

    private func updateBlocked(blocked: Bool, forUserWithUserID userID: String, needUpdateUI: Bool = true) {

        guard let realm = try? Realm() else {
            return
        }

        if let user = userWithUserID(userID, inRealm: realm) {
            let _ = try? realm.write {
                user.blocked = blocked
            }

            if needUpdateUI {
                moreViewManager.userBlocked = blocked
            }
        }
    }

    private func toggleBlock() {

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

    private func tryUpdateGroupAffair(afterSubscribed afterSubscribed: (() -> Void)? = nil) {

        guard let group = conversation.withGroup, feed = group.withFeed, feedCreator = feed.creator else {
            return
        }

        func doDeleteConversation(afterLeaveGroup afterLeaveGroup: (() -> Void)? = nil) -> Void {

            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                if let checkTypingStatusTimer = self?.checkTypingStatusTimer {
                    checkTypingStatusTimer.invalidate()
                }

                guard let conversation = self?.conversation, realm = conversation.realm else {
                    return
                }

                realm.beginWrite()

                deleteConversation(conversation, inRealm: realm, afterLeaveGroup: {
                    afterLeaveGroup?()
                })

                let _ = try? realm.commitWrite()

                NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.changedConversation, object: nil)

                self?.navigationController?.popViewControllerAnimated(true)
            }
        }

        let isMyFeed = feedCreator.isMe
        // 若是创建者，再询问是否删除 Feed
        if isMyFeed {
            let feedID = feed.feedID

            YepAlert.confirmOrCancel(title: NSLocalizedString("Delete", comment: ""), message: NSLocalizedString("Also delete this feed?", comment: ""), confirmTitle: NSLocalizedString("Delete", comment: ""), cancelTitle: NSLocalizedString("Not now", comment: ""), inViewController: self, withConfirmAction: {

                doDeleteConversation(afterLeaveGroup: {
                    deleteFeedWithFeedID(feedID, failureHandler: nil, completion: { [weak self] in
                        println("deleted feed: \(feedID)")
                        self?.afterDeletedFeedAction?(feedID: feedID)
                    })
                })

            }, cancelAction: {
                doDeleteConversation()
            })

        } else {
            let includeMe = group.includeMe
            // 不然考虑订阅或取消订阅
            if includeMe {
                doDeleteConversation()

            } else {
                let groupID = group.groupID
                joinGroup(groupID: groupID, failureHandler: nil, completion: {
                    println("subscribe OK")

                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        if let strongSelf = self {
                            let _ = try? strongSelf.realm.write {
                                group.includeMe = true
                            }

                            afterSubscribed?()
                        }
                    }
                })
            }
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

    @objc private func tryInsertInActiveNewMessages(notification: NSNotification) {

        if UIApplication.sharedApplication().applicationState == .Active {

            if inActiveNewMessageIDSet.count > 0 {
                updateConversationCollectionViewWithMessageIDs(Array(inActiveNewMessageIDSet), messageAge: .New, scrollToBottom: false, success: { _ in
                })

                inActiveNewMessageIDSet = []

                println("insert inActiveNewMessageIDSet to CollectionView")
            }
        }
    }

    private func updateConversationCollectionViewWithMessageIDs(messageIDs: [String]?, messageAge: MessageAge, scrollToBottom: Bool, success: (Bool) -> Void) {

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

        if messageIDs == nil {
            afterSentMessageAction?()

            conversationIsDirty = true

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

        let lastDisplayedMessagesRange = displayedMessagesRange

        displayedMessagesRange.length += newMessagesCount

        let needReloadLoadPreviousSection = self.needReloadLoadPreviousSection

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
                    }, completion: { _ in
                    })

                case .Old:
                    let bottomOffset = conversationCollectionView.contentSize.height - conversationCollectionView.contentOffset.y
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)

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

                            // 上面的 CATransaction 保证了 CollectionView 在插入后不闪动
                            /*
                            // 此时再做个 scroll 动画比较自然
                            let indexPath = NSIndexPath(forItem: newMessagesCount - 1, inSection: Section.Message.rawValue)
                            strongSelf.conversationCollectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredVertically, animated: true)
                            */
                        }
                    })
                }

                println("insert messages A")

            } else {
                println("self message")

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
                }, completion: { _ in
                })

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

            let blockedHeight = topBarsHeight + (feedView != nil ? FeedView.foldHeight : 0) + keyboardAndToolBarHeight

            let visibleHeight = conversationCollectionView.frame.height - blockedHeight

            // cal the height can be used
            let useableHeight = visibleHeight - conversationCollectionView.contentSize.height

            if newMessagesTotalHeight > useableHeight {

                UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { [weak self] in

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
        dispatch_async(dispatch_get_main_queue()) {
            self.conversationCollectionView.reloadData()
        }
    }

    private func cleanTextInput() {
        messageToolbar.messageTextView.text = ""
        messageToolbar.state = .BeginTextInput
    }

    private func updateStateInfoOfTitleView(titleView: ConversationTitleView) {
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            if let strongSelf = self {
                guard !strongSelf.conversation.invalidated else {
                    return
                }

                if let timeAgo = lastSignDateOfConversation(strongSelf.conversation)?.timeAgo {
                    titleView.stateInfoLabel.text = String(format:NSLocalizedString("Last seen %@", comment: ""), timeAgo.lowercaseString)
                } else if let friend = strongSelf.conversation.withFriend {
                    titleView.stateInfoLabel.text = String(format:NSLocalizedString("Last seen %@", comment: ""), NSDate(timeIntervalSince1970: friend.lastSignInUnixTime).timeAgo.lowercaseString)
                } else {
                    titleView.stateInfoLabel.text = NSLocalizedString("Begin chat just now", comment: "")
                }

                titleView.stateInfoLabel.textColor = UIColor.grayColor()
            }
        }
    }

    private func playMessageAudioWithMessage(message: Message?) {

        if let audioPlayer = YepAudioService.sharedManager.audioPlayer {
            if let playingMessage = YepAudioService.sharedManager.playingMessage {
                if audioPlayer.playing {

                    audioPlayer.pause()

                    if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
                        playbackTimer.invalidate()
                    }

                    if let sender = playingMessage.fromFriend, playingMessageIndex = messages.indexOf(playingMessage) {

                        let indexPath = NSIndexPath(forItem: playingMessageIndex - displayedMessagesRange.location, inSection: Section.Message.rawValue)

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
                            YepAudioService.sharedManager.resetToDefault()
                            return
                        }
                    }
                }
            }
        }

        if let message = message {
            let audioPlayedDuration = audioPlayedDurationOfMessage(message)
            YepAudioService.sharedManager.playAudioWithMessage(message, beginFromTime: audioPlayedDuration, delegate: self) {
                let playbackTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: self, selector: "updateAudioPlaybackProgress:", userInfo: nil, repeats: true)
                YepAudioService.sharedManager.playbackTimer = playbackTimer
            }
        } else {
            YepAudioService.sharedManager.resetToDefault()
        }
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

            let box = sender as! Box<ProfileUser>
            vc.profileUser = box.value

            vc.fromType = .GroupConversation
            vc.setBackButtonWithTitle()

        case "showProfileFromFeedView":

            let vc = segue.destinationViewController as! ProfileViewController

            if let user = feedView?.feed?.creator {
                vc.profileUser = ProfileUser.UserType(user)
            }

            vc.fromType = .GroupConversation
            vc.setBackButtonWithTitle()

        case "showProfile":

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

                if let withFriend = self?.conversation.withFriend {

                    sendLocationWithLocationInfo(locationInfo, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { message in

                        dispatch_async(dispatch_get_main_queue()) {
                            self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                            })
                        }

                    }, failureHandler: { [weak self] reason, errorMessage in
                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

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
                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                        YepAlert.alertSorry(message: NSLocalizedString("Failed to send location!\nTry tap on message to resend.", comment: ""), inViewController: self)

                    }, completion: { success -> Void in
                        println("sendLocation to group: \(success)")
                    })
                }
            }

        default:
            break
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

    @objc private func didRecieveMenuWillHideNotification(notification: NSNotification) {

        println("Menu Will hide")

        selectedIndexPathForMenu = nil
    }

    @objc private func didRecieveMenuWillShowNotification(notification: NSNotification) {

        println("Menu Will show")

        guard let menu = notification.object as? UIMenuController, selectedIndexPathForMenu = selectedIndexPathForMenu, cell = conversationCollectionView.cellForItemAtIndexPath(selectedIndexPathForMenu) as? ChatBaseCell else {
            return
        }

        var bubbleFrame = CGRectZero

        if let cell = cell as? ChatLeftTextCell {
            bubbleFrame = cell.convertRect(cell.textContentTextView.frame, toView: view)

        } else if let cell = cell as? ChatRightTextCell {
            bubbleFrame = cell.convertRect(cell.textContainerView.frame, toView: view)

        } else if let cell = cell as? ChatLeftTextURLCell {
            bubbleFrame = cell.convertRect(cell.textContentTextView.frame, toView: view)

        } else if let cell = cell as? ChatRightTextURLCell {
            bubbleFrame = cell.convertRect(cell.textContainerView.frame, toView: view)

        } else if let cell = cell as? ChatLeftImageCell {
            bubbleFrame = cell.convertRect(cell.messageImageView.frame, toView: view)

        } else if let cell = cell as? ChatRightImageCell {
            bubbleFrame = cell.convertRect(cell.messageImageView.frame, toView: view)

        } else if let cell = cell as? ChatLeftAudioCell {
            bubbleFrame = cell.convertRect(cell.audioContainerView.frame, toView: view)

        } else if let cell = cell as? ChatRightAudioCell {
            bubbleFrame = cell.convertRect(cell.audioContainerView.frame, toView: view)

        } else if let cell = cell as? ChatLeftVideoCell {
            bubbleFrame = cell.convertRect(cell.thumbnailImageView.frame, toView: view)

        } else if let cell = cell as? ChatRightVideoCell {
            bubbleFrame = cell.convertRect(cell.thumbnailImageView.frame, toView: view)

        } else if let cell = cell as? ChatLeftLocationCell {
            bubbleFrame = cell.convertRect(cell.mapImageView.frame, toView: view)

        } else if let cell = cell as? ChatRightLocationCell {
            bubbleFrame = cell.convertRect(cell.mapImageView.frame, toView: view)

        } else {
            return
        }

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIMenuControllerWillShowMenuNotification, object: nil)

        menu.setTargetRect(bubbleFrame, inView: view)
        menu.setMenuVisible(true, animated: true)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didRecieveMenuWillShowNotification:", name: UIMenuControllerWillShowMenuNotification, object: nil)
    }

    func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {

        selectedIndexPathForMenu = indexPath

        if let _ = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatBaseCell {

            // must configure it before show

            let title: String
            if let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] {
                let isMyMessage = message.fromFriend?.isMe ?? false
                if isMyMessage {
                    title = NSLocalizedString("Recall", comment: "")
                } else {
                    title = NSLocalizedString("Hide", comment: "")
                }
            } else {
                title = NSLocalizedString("Delete", comment: "")
            }

            UIMenuController.sharedMenuController().menuItems = [
                UIMenuItem(title: title, action: "deleteMessage:")
            ]

            return true

        } else {
            selectedIndexPathForMenu = nil
        }

        return false
    }

    func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {

        if let _ = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatRightTextCell {
            if action == "copy:" {
                return true
            }

        } else if let _ = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatLeftTextCell {
            if action == "copy:" {
                return true
            }
        }

        if action == "deleteMessage:" {
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

    private func deleteMessageAtIndexPath(message: Message, indexPath: NSIndexPath) {
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            if let strongSelf = self, realm = message.realm {

                let isMyMessage = message.fromFriend?.isMe ?? false

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
                        message.deleteAttachmentInRealm(realm)

                        realm.delete(sectionDateMessage)

                        if isMyMessage {

                            let messageID = message.messageID

                            realm.delete(message)

                            deleteMessageFromServer(messageID: messageID, failureHandler: nil, completion: {
                                println("deleteMessageFromServer: \(messageID)")
                            })

                        } else {
                            message.hidden = true
                        }
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
                        message.deleteAttachmentInRealm(realm)

                        if isMyMessage {

                            let messageID = message.messageID

                            realm.delete(message)

                            deleteMessageFromServer(messageID: messageID, failureHandler: nil, completion: {
                                println("deleteMessageFromServer: \(messageID)")
                            })

                        } else {
                            message.hidden = true
                        }
                    }

                    strongSelf.conversationCollectionView.deleteItemsAtIndexPaths([currentIndexPath])
                }

                // 必须更新，插入时需要
                strongSelf.lastTimeMessagesCount = strongSelf.messages.count
            }
        }
    }

    enum Section: Int {
        case LoadPrevious
        case Message
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else {
            return 0
        }

        switch section {

        case .LoadPrevious:
            return 1

        case .Message:
            return displayedMessagesRange.length
        }
    }

    private func tryShowMessageMediaFromMessage(message: Message) {

        if let messageIndex = messages.indexOf(message) {

            let indexPath = NSIndexPath(forRow: messageIndex - displayedMessagesRange.location , inSection: Section.Message.rawValue)

            if let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) {

                var frame = CGRectZero
                var image: UIImage?
                var transitionView: UIView?

                if let sender = message.fromFriend {
                    if sender.friendState != UserFriendState.Me.rawValue {
                        switch message.mediaType {

                        case MessageMediaType.Image.rawValue:
                            let cell = cell as! ChatLeftImageCell
                            image = cell.messageImageView.image
                            transitionView = cell.messageImageView
                            frame = cell.convertRect(cell.messageImageView.frame, toView: view)

                        case MessageMediaType.Video.rawValue:
                            let cell = cell as! ChatLeftVideoCell
                            image = cell.thumbnailImageView.image
                            transitionView = cell.thumbnailImageView
                            frame = cell.convertRect(cell.thumbnailImageView.frame, toView: view)

                        default:
                            break
                        }

                    } else {
                        switch message.mediaType {

                        case MessageMediaType.Image.rawValue:
                            let cell = cell as! ChatRightImageCell
                            image = cell.messageImageView.image
                            transitionView = cell.messageImageView
                            frame = cell.convertRect(cell.messageImageView.frame, toView: view)

                        case MessageMediaType.Video.rawValue:
                            let cell = cell as! ChatRightVideoCell
                            image = cell.thumbnailImageView.image
                            transitionView = cell.thumbnailImageView
                            frame = cell.convertRect(cell.thumbnailImageView.frame, toView: view)

                        default:
                            break
                        }
                    }
                }

                guard image != nil else {
                    return
                }

                let vc = UIStoryboard(name: "MediaPreview", bundle: nil).instantiateViewControllerWithIdentifier("MediaPreviewViewController") as! MediaPreviewViewController

                if message.mediaType == MessageMediaType.Video.rawValue {
                    vc.previewMedias = [PreviewMedia.MessageType(message: message)]
                    vc.startIndex = 0

                } else {
                    let predicate = NSPredicate(format: "mediaType = %d", MessageMediaType.Image.rawValue)
                    let mediaMessagesResult = messages.filter(predicate)
                    let mediaMessages = mediaMessagesResult.map({ $0 })

                    if let index = mediaMessagesResult.indexOf(message) {
                        vc.previewMedias = mediaMessages.map({ PreviewMedia.MessageType(message: $0) })
                        vc.startIndex = index
                    }
                }

                vc.previewImageViewInitalFrame = frame
                vc.topPreviewImage = message.thumbnailImage
                vc.bottomPreviewImage = image

                vc.transitionView = transitionView

                delay(0.0, work: { () -> Void in
                    transitionView?.alpha = 0 // 放到下一个 Runloop 避免太快消失产生闪烁
                })

                vc.afterDismissAction = { [weak self] in
                    transitionView?.alpha = 1
                    self?.view.window?.makeKeyAndVisible()
                }

                mediaPreviewWindow.rootViewController = vc
                mediaPreviewWindow.windowLevel = UIWindowLevelAlert - 1
                mediaPreviewWindow.makeKeyAndVisible()
            }
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(loadMoreCollectionViewCellID, forIndexPath: indexPath) as! LoadMoreCollectionViewCell
            return cell

        case .Message:

            guard let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] else {
                println("🐌 Conversation: message NOT found!")

                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatSectionDateCellIdentifier, forIndexPath: indexPath) as! ChatSectionDateCell
                cell.sectionDateLabel.text = "🐌"

                return cell
            }

            if message.mediaType == MessageMediaType.SectionDate.rawValue {

                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatSectionDateCellIdentifier, forIndexPath: indexPath) as! ChatSectionDateCell
                return cell
            }

            guard let sender = message.fromFriend else {
                println("🐌🐌 Conversation: message has NOT fromFriend!")

                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatSectionDateCellIdentifier, forIndexPath: indexPath) as! ChatSectionDateCell
                cell.sectionDateLabel.text = "🐌🐌"

                return cell
            }

            if sender.friendState != UserFriendState.Me.rawValue { // from Friend

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

                case MessageMediaType.SocialWork.rawValue:

                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftSocialWorkCellIdentifier, forIndexPath: indexPath) as! ChatLeftSocialWorkCell
                    return cell

                default:

                    if message.deletedByCreator {
                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftRecallCellIdentifier, forIndexPath: indexPath) as! ChatLeftRecallCell
                        return cell

                    } else {
                        if message.openGraphInfo != nil {
                            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftTextURLCellIdentifier, forIndexPath: indexPath) as! ChatLeftTextURLCell
                            return cell

                        } else {
                            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftTextCellIdentifier, forIndexPath: indexPath) as! ChatLeftTextCell
                            return cell
                        }
                    }
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

                    if message.openGraphInfo != nil {
                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightTextURLCellIdentifier, forIndexPath: indexPath) as! ChatRightTextURLCell
                        return cell

                    } else {
                        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightTextCellIdentifier, forIndexPath: indexPath) as! ChatRightTextCell
                        return cell
                    }
                }
            }
        }
    }

    private func tryShowProfileWithUsername(username: String) {

        if let realm = try? Realm(), user = userWithUsername(username, inRealm: realm) {
            let profileUser = ProfileUser.UserType(user)

            delay(0.1) { [weak self] in
                self?.performSegueWithIdentifier("showProfileWithUsername", sender: Box<ProfileUser>(profileUser))
            }

        } else {
            discoverUserByUsername(username, failureHandler: { [weak self] reason, errorMessage in
                YepAlert.alertSorry(message: errorMessage ?? NSLocalizedString("User not found.", comment: ""), inViewController: self)

            }, completion: { discoveredUser in
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    let profileUser = ProfileUser.DiscoveredUserType(discoveredUser)
                    self?.performSegueWithIdentifier("showProfileWithUsername", sender: Box<ProfileUser>(profileUser))
                }
            })
        }
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:
            /*
            guard let cell = cell as? LoadMoreCollectionViewCell else {
                break
            }

            cell.loadingActivityIndicator.startAnimating()
            */
            break

        case .Message:
            guard let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] else {
                return
            }

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

            guard let sender = message.fromFriend else {
                return
            }

            if let cell = cell as? ChatBaseCell {

                if let _ = self.conversation.withGroup {
                    cell.inGroup = true
                } else {
                    cell.inGroup = false
                }

                cell.tapAvatarAction = { [weak self] user in
                    self?.performSegueWithIdentifier("showProfile", sender: user)
                }

                cell.deleteMessageAction = { [weak self] in
                    self?.deleteMessageAtIndexPath(message, indexPath: indexPath)
                }
            }

            if sender.friendState != UserFriendState.Me.rawValue { // from Friend

                switch message.mediaType {

                case MessageMediaType.Image.rawValue:

                    if let cell = cell as? ChatLeftImageCell {

                        cell.configureWithMessage(message, messageImagePreferredWidth: messageImagePreferredWidth, messageImagePreferredHeight: messageImagePreferredHeight, messageImagePreferredAspectRatio: messageImagePreferredAspectRatio, mediaTapAction: { [weak self] in

                            if message.downloadState == MessageDownloadState.Downloaded.rawValue {

                                if let messageTextView = self?.messageToolbar.messageTextView {
                                    if messageTextView.isFirstResponder() {
                                        self?.messageToolbar.state = .Default
                                        return
                                    }
                                }

                                self?.tryShowMessageMediaFromMessage(message)

                            } else {
                                //YepAlert.alertSorry(message: NSLocalizedString("Please wait while the image is not ready!", comment: ""), inViewController: self)
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
                                //YepAlert.alertSorry(message: NSLocalizedString("Please wait while the audio is not ready!", comment: ""), inViewController: self)
                            }

                        }, collectionView: collectionView, indexPath: indexPath)
                    }

                case MessageMediaType.Video.rawValue:

                    if let cell = cell as? ChatLeftVideoCell {

                        cell.configureWithMessage(message, messageImagePreferredWidth: messageImagePreferredWidth, messageImagePreferredHeight: messageImagePreferredHeight, messageImagePreferredAspectRatio: self.messageImagePreferredAspectRatio, mediaTapAction: { [weak self] in

                            if message.downloadState == MessageDownloadState.Downloaded.rawValue {

                                if let messageTextView = self?.messageToolbar.messageTextView {
                                    if messageTextView.isFirstResponder() {
                                        self?.messageToolbar.state = .Default
                                        return
                                    }
                                }

                                self?.tryShowMessageMediaFromMessage(message)

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

                case MessageMediaType.SocialWork.rawValue:

                    if let cell = cell as? ChatLeftSocialWorkCell {
                        cell.configureWithMessage(message)

                        cell.createFeedAction = { [weak self] socialWork in

                            self?.performSegueWithIdentifier("presentNewFeed", sender: socialWork)
                        }
                    }

                default:

                    if message.deletedByCreator {
                        if let cell = cell as? ChatLeftRecallCell {
                            cell.configureWithMessage(message)
                        }

                    } else {
                        if message.openGraphInfo != nil {

                            if let cell = cell as? ChatLeftTextURLCell {

                                cell.configureWithMessage(message, textContentLabelWidth: textContentLabelWidthOfMessage(message), collectionView: collectionView, indexPath: indexPath)

                                cell.tapUsernameAction = { [weak self] username in
                                    println("left textURL cell.tapUsernameAction: \(username)")
                                    self?.tryShowProfileWithUsername(username)
                                }

                                cell.tapOpenGraphURLAction = { [weak self] URL in
                                    self?.yep_openURL(URL)
                                }
                            }

                        } else {

                            if let cell = cell as? ChatLeftTextCell {

                                cell.configureWithMessage(message, textContentLabelWidth: textContentLabelWidthOfMessage(message), collectionView: collectionView, indexPath: indexPath)

                                cell.tapUsernameAction = { [weak self] username in
                                    println("left text cell.tapUsernameAction: \(username)")
                                    self?.tryShowProfileWithUsername(username)
                                }
                            }
                        }

                        tryDetectOpenGraphForMessage(message)
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
                                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

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

                                self?.tryShowMessageMediaFromMessage(message)
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
                                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

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

                        cell.configureWithMessage(message, messageImagePreferredWidth:messageImagePreferredWidth, messageImagePreferredHeight: messageImagePreferredHeight, messageImagePreferredAspectRatio: messageImagePreferredAspectRatio, mediaTapAction: { [weak self] in

                            if message.sendState == MessageSendState.Failed.rawValue {

                                YepAlert.confirmOrCancel(title: NSLocalizedString("Action", comment: ""), message: NSLocalizedString("Resend video?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: {

                                    resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

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

                                self?.tryShowMessageMediaFromMessage(message)
                            }

                        }, collectionView: collectionView, indexPath: indexPath)
                    }

                case MessageMediaType.Location.rawValue:

                    if let cell = cell as? ChatRightLocationCell {

                        cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                            if message.sendState == MessageSendState.Failed.rawValue {

                                YepAlert.confirmOrCancel(title: NSLocalizedString("Action", comment: ""), message: NSLocalizedString("Resend location?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: {

                                    resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

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

                    let mediaTapAction: () -> Void = { [weak self] in

                        guard message.sendState == MessageSendState.Failed.rawValue else {
                            return
                        }

                        YepAlert.confirmOrCancel(title: NSLocalizedString("Action", comment: ""), message: NSLocalizedString("Resend text?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: {

                            resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                                YepAlert.alertSorry(message: NSLocalizedString("Failed to resend text!\nPlease make sure your iPhone is connected to the Internet.", comment: ""), inViewController: self)

                                }, completion: { success in
                                    println("resendText: \(success)")
                            })

                        }, cancelAction: {
                        })
                    }

                    if message.openGraphInfo != nil {

                        if let cell = cell as? ChatRightTextURLCell {

                            cell.configureWithMessage(message, textContentLabelWidth: textContentLabelWidthOfMessage(message), mediaTapAction: mediaTapAction, collectionView: collectionView, indexPath: indexPath)

                            cell.tapUsernameAction = { [weak self] username in
                                println("right textURL cell.tapUsernameAction: \(username)")
                                self?.tryShowProfileWithUsername(username)
                            }

                            cell.tapOpenGraphURLAction = { [weak self] URL in
                                self?.yep_openURL(URL)
                            }
                        }

                    } else {

                        if let cell = cell as? ChatRightTextCell {

                            cell.configureWithMessage(message, textContentLabelWidth: textContentLabelWidthOfMessage(message), mediaTapAction: mediaTapAction, collectionView: collectionView, indexPath: indexPath)

                            cell.tapUsernameAction = { [weak self] username in
                                println("right text cell.tapUsernameAction: \(username)")
                                self?.tryShowProfileWithUsername(username)
                            }
                        }
                    }

                    tryDetectOpenGraphForMessage(message)
                }
            }
        }
    }

    private func tryDetectOpenGraphForMessage(message: Message) {

        guard !message.openGraphDetected else {
            return
        }

        func markMessageOpenGraphDetected() {
            guard !message.invalidated else {
                return
            }

            let _ = try? realm.write {
                message.openGraphDetected = true
            }
        }

        let text = message.textContent
        guard let fisrtURL = text.yep_embeddedURLs.first else {
            markMessageOpenGraphDetected()
            return
        }

        openGraphWithURL(fisrtURL, failureHandler: { reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            dispatch_async(dispatch_get_main_queue()) {
                markMessageOpenGraphDetected()
            }

        }, completion: { _openGraph in
            println("message_openGraph: \(_openGraph)")

            guard _openGraph.isValid else {
                return
            }

            dispatch_async(dispatch_get_main_queue()) { [weak self] in

                guard let strongSelf = self else {
                    return
                }

                let openGraphInfo = OpenGraphInfo(URLString: _openGraph.URL.absoluteString, siteName: _openGraph.siteName ?? "", title: _openGraph.title ?? "", infoDescription: _openGraph.description ?? "", thumbnailImageURLString: _openGraph.previewImageURLString ?? "")

                let _ = try? strongSelf.realm.write {
                    strongSelf.realm.add(openGraphInfo, update: true)
                    message.openGraphInfo = openGraphInfo
                }

                markMessageOpenGraphDetected()

                // update UI
                strongSelf.clearHeightOfMessageWithKey(message.messageID)

                if let index = strongSelf.messages.indexOf(message) {
                    let realIndex = index - strongSelf.displayedMessagesRange.location
                    let indexPath = NSIndexPath(forItem: realIndex, inSection: Section.Message.rawValue)
                    strongSelf.conversationCollectionView.reloadItemsAtIndexPaths([indexPath])

                    // only for latest one need to scroll
                    if index == (strongSelf.displayedMessagesRange.location + strongSelf.displayedMessagesRange.length - 1) {
                        strongSelf.conversationCollectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
                    }
                }
            }
        })
    }

    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:
            guard let cell = cell as? LoadMoreCollectionViewCell else {
                break
            }

            cell.loadingActivityIndicator.stopAnimating()
            
        case .Message:
            break
        }
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:
            return CGSize(width: collectionViewWidth, height: 20)

        case .Message:
            guard let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] else {
                return CGSize(width: collectionViewWidth, height: 0)
            }

            let height = heightOfMessage(message)

            return CGSize(width: collectionViewWidth, height: height)
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        guard let section = Section(rawValue: section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:
            return UIEdgeInsetsZero

        case .Message:
            return UIEdgeInsets(top: 5, left: 0, bottom: sectionInsetBottom, right: 0)
        }
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

        //pullToRefreshView.scrollViewDidScroll(scrollView)

        if let dragBeginLocation = dragBeginLocation {
            let location = scrollView.panGestureRecognizer.locationInView(view)
            let deltaY = location.y - dragBeginLocation.y

            if deltaY < -30 {
                tryFoldFeedView()
            }
        }

        func tryTriggerLoadPrevious() {
            guard scrollView.yep_isNearTop && (scrollView.dragging || scrollView.decelerating) else {
                return
            }

            let indexPath = NSIndexPath(forItem: 0, inSection: Section.LoadPrevious.rawValue)
            guard conversationCollectionViewHasBeenMovedToBottomOnce, let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? LoadMoreCollectionViewCell else {
                return
            }

            guard !isLoadingPreviousMessages else {
                cell.loadingActivityIndicator.stopAnimating()
                return
            }

            cell.loadingActivityIndicator.startAnimating()

            if scrollView.yep_isAtTop {
                delay(0.5) { [weak self] in
                    self?.tryLoadPreviousMessages { [weak cell] in
                        cell?.loadingActivityIndicator.stopAnimating()
                    }
                }
            }
        }

        tryTriggerLoadPrevious()
    }

    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {

        //pullToRefreshView.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)

        dragBeginLocation = nil
    }
}

// MARK: FayeServiceDelegate

extension ConversationViewController: FayeServiceDelegate {

    func fayeRecievedInstantStateType(instantStateType: FayeService.InstantStateType, userID: String) {

        if let withFriend = conversation.withFriend {

            if userID == withFriend.userID {

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

    /*
    func fayeRecievedNewMessages(messageIDs: [String], messageAgeRawValue: MessageAge.RawValue) {

        guard let
            messageAge = MessageAge(rawValue: messageAgeRawValue) else {
                println("Can NOT handleReceivedNewMessagesNotification")
                return
        }

        handleRecievedNewMessages(messageIDs, messageAge: messageAge)
    }

    func fayeMessagesMarkAsReadByRecipient(lastReadAt: NSTimeInterval, recipientType: String, recipientID: String) {

        if recipientID == conversation.recipient?.ID && recipientType == conversation.recipient?.type.nameForServer {
            self.markAsReadAllSentMesagesBeforeUnixTime(lastReadAt)
        }
    }
    */
}

/*
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

                    delay(0.3) { // 人为延迟，增加等待感
                        pulllToRefreshView.endRefreshingAndDoFurtherAction() {
                            dispatch_async(dispatch_get_main_queue()) {
                                tryPostNewMessagesReceivedNotificationWithMessageIDs(messageIDs, messageAge: timeDirection.messageAge)
                                //self?.fayeRecievedNewMessages(messageIDs, messageAgeRawValue: timeDirection.messageAge.rawValue)
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
                                let indexPath = NSIndexPath(forItem: Int(i), inSection: Section.Message.rawValue)
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
                                    let indexPath = NSIndexPath(forItem: newMessagesCount - 1, inSection: Section.Message.rawValue)
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
*/

// MARK: AVAudioRecorderDelegate

extension ConversationViewController: AVAudioRecorderDelegate {

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

        func nextUnplayedAudioMessageFrom(message: Message) -> Message? {

            if let index = messages.indexOf(message) {
                for i in (index + 1)..<messages.count {
                    if let message = messages[safe: i], friend = message.fromFriend {
                        if friend.friendState != UserFriendState.Me.rawValue {
                            if (message.mediaType == MessageMediaType.Audio.rawValue) && (message.mediaPlayed == false) {
                                return message
                            }
                        }
                    }
                }
            }

            return nil
        }

        // 尝试播放下一个未播放过的语音消息
        if let playingMessage = YepAudioService.sharedManager.playingMessage {
            let message = nextUnplayedAudioMessageFrom(playingMessage)
            playMessageAudioWithMessage(message)

        } else {
            YepAudioService.sharedManager.resetToDefault()
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

                    if let fixedImage = image.resizeToSize(fixedSize, withInterpolationQuality: CGInterpolationQuality.High) {
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

        let metaDataString = metaDataStringOfImage(image, needBlurThumbnail: true)

        // Do send

        let imageData = UIImageJPEGRepresentation(image, YepConfig.messageImageCompressionQuality())!
        /*
        var imageData = UIImageJPEGRepresentation(image, YepConfig.messageImageCompressionQuality())!

        if let progressiveImage = UIImage(data: imageData)?.yep_progressiveImage {

            imageData = UIImageJPEGRepresentation(progressiveImage, YepConfig.messageImageCompressionQuality())!
        }
        */

        let messageImageName = NSUUID().UUIDString

        if let withFriend = conversation.withFriend {

            sendImageInFilePath(nil, orFileData: imageData, metaData: metaDataString, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { [weak self] message in

                dispatch_async(dispatch_get_main_queue()) {

                    if let _ = NSFileManager.saveMessageImageData(imageData, withName: messageImageName) {
                        if let realm = message.realm {
                            let _ = try? realm.write {
                                message.localAttachmentName = messageImageName
                                message.mediaType = MessageMediaType.Image.rawValue
                                if let metaDataString = metaDataString {
                                    message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                                }
                            }
                        }
                    }

                    self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                    })
                }

            }, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                YepAlert.alertSorry(message: NSLocalizedString("Failed to send image!\nTry tap on message to resend.", comment: ""), inViewController: self)

            }, completion: { success -> Void in
                println("sendImage to friend: \(success)")
            })

        } else if let withGroup = conversation.withGroup {

            sendImageInFilePath(nil, orFileData: imageData, metaData: metaDataString, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { [weak self] message in

                dispatch_async(dispatch_get_main_queue()) {
                    if let _ = NSFileManager.saveMessageImageData(imageData, withName: messageImageName) {
                        if let realm = message.realm {
                            let _ = try? realm.write {
                                message.localAttachmentName = messageImageName
                                message.mediaType = MessageMediaType.Image.rawValue
                                if let metaDataString = metaDataString {
                                    message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                                }
                            }
                        }
                    }

                    self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                    })
                }

            }, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                YepAlert.alertSorry(message: NSLocalizedString("Failed to send image!\nTry tap on message to resend.", comment: ""), inViewController: self)

            }, completion: { success in
                println("sendImage to group: \(success)")
            })
        }
    }

    private func sendVideoWithVideoURL(videoURL: NSURL) {

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

            let thumbnailSize = CGSize(width: thumbnailWidth, height: thumbnailHeight)

            if let thumbnail = image.resizeToSize(thumbnailSize, withInterpolationQuality: CGInterpolationQuality.Low) {
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
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                YepAlert.alertSorry(message: NSLocalizedString("Failed to send video!\nTry tap on message to resend.", comment: ""), inViewController: self)

            }, completion: { success in
                println("sendVideo to friend: \(success)")
            })

        } else if let withGroup = conversation.withGroup {

            sendVideoInFilePath(videoURL.path!, orFileData: nil, metaData: metaData, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: afterCreatedMessageAction, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                YepAlert.alertSorry(message: NSLocalizedString("Failed to send video!\nTry tap on message to resend.", comment: ""), inViewController: self)

            }, completion: { success in
                println("sendVideo to group: \(success)")
            })
        }
    }
}
