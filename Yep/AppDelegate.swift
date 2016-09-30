//
//  AppDelegate.swift
//  Yep
//
//  Created by kevinzhow on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepNetworking
import YepPreview
import Fabric
import AVFoundation
import RealmSwift
import MonkeyKing
import Navi
import Appsee
import CoreSpotlight

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var deviceToken: Data? {
        didSet {
            guard let deviceToken = deviceToken else { return }
            guard let pusherID = YepUserDefaults.pusherID.value else { return }

            registerThirdPartyPushWithDeciveToken(deviceToken, pusherID: pusherID)
        }
    }
    var notRegisteredThirdPartyPush = true

    fileprivate var isFirstActive = true

    enum LaunchStyle {
        case `default`
        case message
    }
    var lauchStyle = Listenable<LaunchStyle>(.default) { _ in }

    enum RemoteNotificationType: String {
        case Message = "message"
        case OfficialMessage = "official_message"
        case FriendRequest = "friend_request"
        case MessageDeleted = "message_deleted"
        case Mentioned = "mentioned"
    }

    fileprivate var remoteNotificationType: RemoteNotificationType? {
        willSet {
            if let type = newValue {
                switch type {

                case .Message, .OfficialMessage:
                    lauchStyle.value = .message

                default:
                    break
                }
            }
        }
    }

    // MARK: Life Circle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        BuddyBuildSDK.setup()

        Realm.Configuration.defaultConfiguration = realmConfig()

        configureYepKit()
        configureYepNetworking()
        configureYepPreview()

        cacheInAdvance()

        _ = delay(0.5) {
            //Fabric.with([Crashlytics.self])
            Fabric.with([Appsee.self])

            #if STAGING
                let apsForProduction = false
            #else
                let apsForProduction = true
                JPUSHService.setLogOFF()
            #endif
            JPUSHService.setup(withOption: launchOptions, appKey: "e521aa97cd4cd4eba5b73669", channel: "AppStore", apsForProduction: apsForProduction)
        }
        
        let _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)

        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)

        // 全局的外观自定义
        customAppearce()
        
        let isLogined = YepUserDefaults.isLogined

        if isLogined {

            // 记录启动通知类型
            if let
                notification = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? UILocalNotification,
                let userInfo = notification.userInfo,
                let type = userInfo["type"] as? String {
                    remoteNotificationType = RemoteNotificationType(rawValue: type)
            }

        } else {
            startShowStory()
        }

        YepUserDefaults.appLaunchCount.value += 1

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {

        println("Did Active")

        if !isFirstActive {
            syncUnreadMessages() {}

        } else {
            // 确保该任务不是被 Remote Notification 激活 App 的时候执行
            sync()

            // 延迟一些，减少线程切换压力
            _ = delay(2) { [weak self] in
                self?.startFaye()
            }
        }

        clearNotifications()

        NotificationCenter.default.post(name: YepConfig.NotificationName.applicationDidBecomeActive, object: nil)
        
        isFirstActive = false
    }

    func applicationWillResignActive(_ application: UIApplication) {

        println("Resign active")

        clearNotifications()

        // dynamic shortcut items

        configureDynamicShortcuts()

        // index searchable items

        if YepUserDefaults.isLogined {
            CSSearchableIndex.default().deleteAllSearchableItems { [weak self] error in

                guard error == nil else {
                    return
                }

                self?.indexUserSearchableItems()
                self?.indexFeedSearchableItems()
            }

        } else {
            CSSearchableIndex.default().deleteAllSearchableItems(completionHandler: nil)
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        
        println("Enter background")

        NotificationCenter.default.post(name: YepConfig.NotificationName.updateDraftOfConversation, object: nil)

        #if DEBUG
        //clearUselessRealmObjects() // only for test
        #endif
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

        println("Will Foreground")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

        clearUselessRealmObjects()
    }

    // MARK: APNs

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        println("Fetch Back")
        syncUnreadMessages() {
            completionHandler(UIBackgroundFetchResult.newData)
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        // 纪录下来，用于初次登录或注册有 pusherID 后，或“注销再登录”
        self.deviceToken = deviceToken
    }
    
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable: Any], withResponseInfo responseInfo: [AnyHashable: Any], completionHandler: @escaping () -> Void) {

        defer {
            completionHandler()
        }

        guard let identifier = identifier else {
            return
        }

        switch identifier {

        case YepNotificationCommentAction:

            if let replyText = responseInfo[UIUserNotificationActionResponseTypedTextKey] as? String {
                tryReplyText(replyText, withUserInfo: userInfo)
            }

        case YepNotificationOKAction:

            tryReplyText(String.trans_titleOK, withUserInfo: userInfo)

        default:
            break
        }
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        println("didReceiveRemoteNotification: \(userInfo)")

        JPUSHService.handleRemoteNotification(userInfo)

        guard YepUserDefaults.isLogined, let type = userInfo["type"] as? String, let remoteNotificationType = RemoteNotificationType(rawValue: type) else {
            completionHandler(UIBackgroundFetchResult.noData)
            return
        }

        defer {
            // 非前台才记录启动通知类型
            if application.applicationState != .active {
                self.remoteNotificationType = remoteNotificationType
            }
        }

        switch remoteNotificationType {

        case .Message:

            syncUnreadMessages() {
                SafeDispatch.async {
                    NotificationCenter.default.post(name: Config.NotificationName.changedFeedConversation, object: nil)

                    configureDynamicShortcuts()

                    completionHandler(.newData)
                }
            }

        case .OfficialMessage:

            officialMessages { messagesCount in
                completionHandler(.newData)
                println("new officialMessages count: \(messagesCount)")
            }

        case .FriendRequest:

            if let subType = userInfo["subtype"] as? String {
                if subType == "accepted" {
                    syncFriendshipsAndDoFurtherAction {
                        completionHandler(.newData)
                    }
                } else {
                    completionHandler(.noData)
                }
            } else {
                completionHandler(.noData)
            }

        case .MessageDeleted:

            defer {
                completionHandler(UIBackgroundFetchResult.noData)
            }

            guard let
                messageInfo = userInfo["message"] as? JSONDictionary,
                let messageID = messageInfo["id"] as? String
                else {
                    break
            }

            handleMessageDeletedFromServer(messageID: messageID)

            configureDynamicShortcuts()

        case .Mentioned:

            syncUnreadMessagesAndDoFurtherAction({ _ in
                SafeDispatch.async {
                    NotificationCenter.default.post(name: Config.NotificationName.changedFeedConversation, object: nil)

                    configureDynamicShortcuts()

                    completionHandler(UIBackgroundFetchResult.newData)
                }
            })
        }
    }

//    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//
//        println(error)
//    }

    // MARK: Shortcuts

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {

        handleShortcutItem(shortcutItem)

        completionHandler(true)
    }

    fileprivate func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {

        if let window = window {
            tryQuickActionWithShortcutItem(shortcutItem, inWindow: window)
        }
    }

    // MARK: Open URL

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {

        if url.absoluteString.contains("/auth/success") {
            NotificationCenter.default.post(name: YepConfig.NotificationName.oauthResult, object: NSNumber(value: 1 as Int32))
            
        } else if url.absoluteString.contains("/auth/failure") {
            NotificationCenter.default.post(name: YepConfig.NotificationName.oauthResult, object: NSNumber(value: 0 as Int32))
        }
        
        if MonkeyKing.handleOpenURL(url) {
            return true
        }

        return false
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {

        println("userActivity.activityType: \(userActivity.activityType)")
        println("userActivity.userInfo: \(userActivity.userInfo)")

        let activityType = userActivity.activityType

        switch  activityType {

        case NSUserActivityTypeBrowsingWeb:

            guard let webpageURL = userActivity.webpageURL else {
                return false
            }

            return handleUniversalLink(webpageURL)

        case CSSearchableItemActionType:
                
            guard let searchableItemID = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
                return false
            }

            guard let (itemType, itemID) = searchableItem(searchableItemID: searchableItemID) else {
                return false
            }

            switch itemType {

            case .User:
                return handleUserSearchActivity(userID: itemID)

            case .Feed:
                return handleFeedSearchActivity(feedID: itemID)
            }

        default:
            return false
        }
    }
    
    fileprivate func handleUniversalLink(_ URL: Foundation.URL) -> Bool {

        guard let
            tabBarVC = window?.rootViewController as? UITabBarController,
            let nvc = tabBarVC.selectedViewController as? UINavigationController else {
                return false
        }

        // Feed (Group)

        return URL.yep_matchSharedFeed({ feed in

            guard let feed = feed else {
                return
            }

            //println("matchSharedFeed: \(feed)")

            guard let realm = try? Realm() else {
                return
            }

            let vc = UIStoryboard.Scene.conversation

            realm.beginWrite()
            let feedConversation = vc.prepareConversation(for: feed, in: realm)
            let _ = try? realm.commitWrite()

            // 如果已经显示了就不用push
            if let topVC = nvc.topViewController as? ConversationViewController, let oldFakeID = topVC.conversation?.fakeID, let newFakeID = feedConversation?.fakeID , newFakeID == oldFakeID {
                return
            }

            vc.conversation = feedConversation
            vc.conversationFeed = ConversationFeed.discoveredFeedType(feed)

            _ = delay(0.25) {
                nvc.pushViewController(vc, animated: true)
            }

        // Profile (Last)

        }) || URL.yep_matchProfile({ discoveredUser in

            //println("matchProfile: \(discoveredUser)")

            // 如果已经显示了就不用push
            if let topVC = nvc.topViewController as? ProfileViewController, let userID = topVC.profileUser?.userID , userID == discoveredUser.id {
                return
            }

            let vc = UIStoryboard.Scene.profile
            vc.prepare(with: discoveredUser)

            _ = delay(0.25) {
                nvc.pushViewController(vc, animated: true)
            }
        })
    }

    fileprivate func handleUserSearchActivity(userID: String) -> Bool {

        guard let
            realm = try? Realm(),
            let user = userWithUserID(userID, inRealm: realm),
            let tabBarVC = window?.rootViewController as? UITabBarController,
            let nvc = tabBarVC.selectedViewController as? UINavigationController else {
                return false
        }

        // 如果已经显示了就不用push
        if let topVC = nvc.topViewController as? ProfileViewController, let _userID = topVC.profileUser?.userID , _userID == userID {
            return true

        } else {
            let vc = UIStoryboard.Scene.profile
            vc.prepare(withUser: user)

            _ = delay(0.25) {
                nvc.pushViewController(vc, animated: true)
            }

            return true
        }
    }

    fileprivate func handleFeedSearchActivity(feedID: String) -> Bool {

        guard let
            realm = try? Realm(),
            let feed = feedWithFeedID(feedID, inRealm: realm),
            let conversation = feed.group?.conversation,
            let tabBarVC = window?.rootViewController as? UITabBarController,
            let nvc = tabBarVC.selectedViewController as? UINavigationController else {
                return false
        }

        // 如果已经显示了就不用push
        if let topVC = nvc.topViewController as? ConversationViewController, let feed = topVC.conversation?.withGroup?.withFeed , feed.feedID == feedID {
            return true

        } else {
            let vc = UIStoryboard.Scene.conversation
            vc.conversation = conversation

            _ = delay(0.25) {
                nvc.pushViewController(vc, animated: true)
            }

            return true
        }
    }

    // MARK: Public

    var inMainStory: Bool = true

    func startShowStory() {

        let storyboard = UIStoryboard.yep_show
        window?.rootViewController = storyboard.instantiateInitialViewController()

        inMainStory = false
    }

    func startMainStory() {

        let storyboard = UIStoryboard.yep_main
        window?.rootViewController = storyboard.instantiateInitialViewController()

        inMainStory = true
    }

    func sync() {

        guard YepUserDefaults.isLogined else {
            return
        }

        refreshGroupTypeForAllGroups()

        let moreSync = {
            syncFriendshipsAndDoFurtherAction {
                syncSocialWorksToMessagesForYepTeam()

                syncMyInfoAndDoFurtherAction {}
            }

            officialMessages { messagesCount in
                println("new officialMessages count: \(messagesCount)")
            }
        }

        if YepUserDefaults.isSyncedConversations {
            syncUnreadMessages {
                moreSync()
            }
        } else {
            syncMyConversations {
                moreSync()
            }
        }
    }

    func startFaye() {

        guard YepUserDefaults.isLogined else {
            return
        }

        YepFayeService.sharedManager.tryStartConnect()
    }

    func registerThirdPartyPushWithDeciveToken(_ deviceToken: Data, pusherID: String) {

        guard notRegisteredThirdPartyPush else {
            return
        }

        notRegisteredThirdPartyPush = false

        JPUSHService.registerDeviceToken(deviceToken)

        let callbackSelector = #selector(AppDelegate.tagsAliasCallBack(_:tags:alias:))
        JPUSHService.setTags(Set(["iOS"]), alias: pusherID, callbackSelector: callbackSelector, object: self)

        println("registerThirdPartyPushWithDeciveToken: \(deviceToken), pusherID: \(pusherID)")
    }

    func unregisterThirdPartyPush() {

        defer {
            SafeDispatch.async { [weak self] in
                self?.clearNotifications()
            }
        }

        guard !notRegisteredThirdPartyPush else {
            return
        }

        notRegisteredThirdPartyPush = true

        JPUSHService.setAlias(nil, callbackSelector: nil, object: nil)

        println("unregisterThirdPartyPush")
    }

    @objc fileprivate func tagsAliasCallBack(_ iResCode: CInt, tags: NSSet, alias: NSString) {

        println("tagsAliasCallback: \(iResCode), \(tags), \(alias)")
    }

    // MARK: Private

    fileprivate func clearNotifications() {

        let application = UIApplication.shared

        application.applicationIconBadgeNumber = 1
        println("a badge: \(application.applicationIconBadgeNumber)")
        defer {
            application.applicationIconBadgeNumber = 0
            println("b badge: \(application.applicationIconBadgeNumber)")
        }
        application.cancelAllLocalNotifications()
    }

    fileprivate lazy var sendMessageSoundEffect: YepSoundEffect = {

        let bundle = Bundle.main
        guard let fileURL = bundle.url(forResource: "bub3", withExtension: "caf") else {
            fatalError("YepSoundEffect: file no found!")
        }
        return YepSoundEffect(fileURL: fileURL)
    }()

    fileprivate func configureYepKit() {

        YepKit.Config.updatedAccessTokenAction = {

            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                // 注册或初次登录时同步数据的好时机
                appDelegate.sync()

                // 也是注册或初次登录时启动 Faye 的好时机
                appDelegate.startFaye()
            }
        }

        YepKit.Config.updatedPusherIDAction = { pusherID in

            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                if let deviceToken = appDelegate.deviceToken {
                    appDelegate.registerThirdPartyPushWithDeciveToken(deviceToken, pusherID: pusherID)
                }
            }
        }

        YepKit.Config.sentMessageSoundEffectAction = { [weak self] in

            self?.sendMessageSoundEffect.play()
        }

        YepKit.Config.timeAgoAction = { date in

            return date.timeAgo
        }

        YepKit.Config.isAppActive = {

            let state = UIApplication.shared.applicationState
            return state == .active
        }
    }

    fileprivate func configureYepNetworking() {

        YepNetworking.Manager.accessToken = {

            return YepUserDefaults.v1AccessToken.value
        }

        YepNetworking.Manager.authFailedAction = { statusCode, host in

            // 确保是自家服务
            guard host == yepBaseURL.host else {
                return
            }

            switch statusCode {

            case 401:
                SafeDispatch.async {
                    YepUserDefaults.maybeUserNeedRelogin(prerequisites: {
                        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate , appDelegate.inMainStory else {
                            return false
                        }
                        return true

                    }, confirm: { [weak self] in
                        self?.unregisterThirdPartyPush()

                        cleanRealmAndCaches()

                        if let rootViewController = self?.window?.rootViewController {
                            YepAlert.alert(title: NSLocalizedString("Sorry", comment: ""), message: NSLocalizedString("User authentication error, you need to login again!", comment: ""), dismissTitle: NSLocalizedString("Relogin", comment: ""), inViewController: rootViewController, withDismissAction: { [weak self] in
                                
                                self?.startShowStory()
                            })
                        }
                    })
                }

            default:
                break
            }
        }

        YepNetworking.Manager.networkActivityCountChangedAction = { count in

            SafeDispatch.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = (count > 0)
            }
        }
    }

    fileprivate func configureYepPreview() {

        YepPreview.Config.shareImageAction = { image, vc in

            let info = MonkeyKing.Info(
                title: nil,
                description: nil,
                thumbnail: image.navi_centerCropWithSize(CGSize(width: 100, height: 100)),
                media: .image(image)
            )
            vc.yep_share(info: info, defaultActivityItem: image)
        }
    }

    fileprivate func tryReplyText(_ text: String, withUserInfo userInfo: [AnyHashable: Any]) {

        guard let info = userInfo as? JSONDictionary else {
            return
        }
        guard let recipient = Recipient(info: info) else {
            return
        }

        sendText(text, toRecipient: recipient, afterCreatedMessage: { _ in }, failureHandler: nil, completion: { success in
            println("reply to \(recipient), \(success)")
        })
    }

    fileprivate func indexUserSearchableItems() {

        let users = normalFriends()

        let searchableItems: [CSSearchableItem] = users.map({
            CSSearchableItem(
                uniqueIdentifier: searchableItemID(searchableItemType: .User, itemID: $0.userID),
                domainIdentifier: YepConfig.Domain.user,
                attributeSet: $0.attributeSet
            )
        })

        println("userSearchableItems: \(searchableItems.count)")

        CSSearchableIndex.default().indexSearchableItems(searchableItems) { (error) in
            if error != nil {
                println(error!.localizedDescription)

            } else {
                println("indexUserSearchableItems OK")
            }
        }
    }

    fileprivate func indexFeedSearchableItems() {

        guard let realm = try? Realm() else {
            return
        }

        let feeds = filterValidFeeds(realm.objects(Feed.self))

        let searchableItems = feeds.map({
            CSSearchableItem(
                uniqueIdentifier: searchableItemID(searchableItemType: .Feed, itemID: $0.feedID),
                domainIdentifier: YepConfig.Domain.feed,
                attributeSet: $0.attributeSet
            )
        })

        println("feedSearchableItems: \(searchableItems.count)")

        CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
            if error != nil {
                println(error!.localizedDescription)

            } else {
                println("indexFeedSearchableItems OK")
            }
        }
    }

    fileprivate func syncUnreadMessages(_ furtherAction: @escaping () -> Void) {

        guard YepUserDefaults.isLogined else {
            furtherAction()
            return
        }

        syncUnreadMessagesAndDoFurtherAction() { messageIDs in
            tryPostNewMessagesReceivedNotificationWithMessageIDs(messageIDs, messageAge: .New)

            /*
            // Use Delegate instead of Notification
            // Delegate 可以 保证只有一个 ConversationView 处理新消息
            // Notification 可能出现某项情况下 Conversation 没有释放而出现内存泄漏后一直后台监听，一有新消息就会 Crash 
            // 之前的 insert message crash 就是因此导致的
            
            FayeService.sharedManager.delegate?.fayeRecievedNewMessages(messageIDs, messageAgeRawValue: MessageAge.New.rawValue)
            */
            
            furtherAction()
        }
    }

    fileprivate func cacheInAdvance() {

        DispatchQueue.global(qos: .background).async {

            guard let realm = try? Realm() else {
                return
            }

            // 主界面的头像

            let predicate = NSPredicate(format: "type = %d", ConversationType.oneToOne.rawValue)
            let conversations = realm.objects(Conversation.self).filter(predicate).sorted(byProperty: "updatedUnixTime", ascending: false)

            conversations.forEach { conversation in
                if let latestMessage = conversation.messages.last, let user = latestMessage.fromFriend {
                    let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: miniAvatarStyle)
                    AvatarPod.wakeAvatar(userAvatar, completion: { _ , _, _ in })
                }
            }
        }
    }

    fileprivate func customAppearce() {

        window?.backgroundColor = UIColor.white

        // Global Tint Color

        window?.tintColor = UIColor.yepTintColor()
        window?.tintAdjustmentMode = .normal

        // NavigationBar Item Style

        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.yepTintColor()], for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.yepTintColor().withAlphaComponent(0.3)], for: .disabled)

        // NavigationBar Title Style

        let shadow: NSShadow = {
            let shadow = NSShadow()
            shadow.shadowColor = UIColor.lightGray
            shadow.shadowOffset = CGSize(width: 0, height: 0)
            return shadow
        }()
        let textAttributes: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.yepNavgationBarTitleColor(),
            NSShadowAttributeName: shadow,
            NSFontAttributeName: UIFont.navigationBarTitleFont()
        ]
        UINavigationBar.appearance().titleTextAttributes = textAttributes
        UINavigationBar.appearance().barTintColor = UIColor.white

        // TabBar

        UITabBar.appearance().tintColor = UIColor.yepTintColor()
        UITabBar.appearance().barTintColor = UIColor.white
    }
}

