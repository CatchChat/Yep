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

    var deviceToken: NSData? {
        didSet {
            guard let deviceToken = deviceToken else { return }
            guard let pusherID = YepUserDefaults.pusherID.value else { return }

            registerThirdPartyPushWithDeciveToken(deviceToken, pusherID: pusherID)
        }
    }
    var notRegisteredThirdPartyPush = true

    private var isFirstActive = true

    enum LaunchStyle {
        case Default
        case Message
    }
    var lauchStyle = Listenable<LaunchStyle>(.Default) { _ in }

    struct Notification {
        static let applicationDidBecomeActive = "applicationDidBecomeActive"
    }

    enum RemoteNotificationType: String {
        case Message = "message"
        case OfficialMessage = "official_message"
        case FriendRequest = "friend_request"
        case MessageDeleted = "message_deleted"
        case Mentioned = "mentioned"
    }

    private var remoteNotificationType: RemoteNotificationType? {
        willSet {
            if let type = newValue {
                switch type {

                case .Message, .OfficialMessage:
                    lauchStyle.value = .Message

                default:
                    break
                }
            }
        }
    }

    // MARK: Life Circle

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        BuddyBuildSDK.setup()

        Realm.Configuration.defaultConfiguration = realmConfig()

        configureYepKit()
        configureYepNetworking()

        cacheInAdvance()

        delay(0.5) {
            //Fabric.with([Crashlytics.self])
            Fabric.with([Appsee.self])

            #if STAGING
                let apsForProduction = false
            #else
                let apsForProduction = true
            #endif
            JPUSHService.setupWithOption([:], appKey: "e521aa97cd4cd4eba5b73669", channel: "AppStore", apsForProduction: apsForProduction)
        }
        
        let _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.DefaultToSpeaker)

        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)

        // 全局的外观自定义
        customAppearce()
        
        let isLogined = YepUserDefaults.isLogined

        if isLogined {

            // 记录启动通知类型
            if let
                notification = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? UILocalNotification,
                userInfo = notification.userInfo,
                type = userInfo["type"] as? String {
                    remoteNotificationType = RemoteNotificationType(rawValue: type)
            }

        } else {
            startShowStory()
        }

        YepUserDefaults.appLaunchCount.value += 1

        return true
    }

    func applicationDidBecomeActive(application: UIApplication) {

        println("Did Active")

        if !isFirstActive {
            syncUnreadMessages() {}

        } else {
            sync() // 确保该任务不是被 Remote Notification 激活 App 的时候执行
            startFaye()
        }

        application.applicationIconBadgeNumber = -1

        NSNotificationCenter.defaultCenter().postNotificationName(Notification.applicationDidBecomeActive, object: nil)
        
        isFirstActive = false
    }

    func applicationWillResignActive(application: UIApplication) {

        println("Resign active")

        UIApplication.sharedApplication().applicationIconBadgeNumber = 0

        // dynamic shortcut items

        configureDynamicShortcuts()

        // index searchable items

        if YepUserDefaults.isLogined {
            CSSearchableIndex.defaultSearchableIndex().deleteAllSearchableItemsWithCompletionHandler { [weak self] error in

                guard error == nil else {
                    return
                }

                self?.indexUserSearchableItems()
                self?.indexFeedSearchableItems()
            }

        } else {
            CSSearchableIndex.defaultSearchableIndex().deleteAllSearchableItemsWithCompletionHandler(nil)
        }
    }

    func applicationDidEnterBackground(application: UIApplication) {
        
        println("Enter background")

        NSNotificationCenter.defaultCenter().postNotificationName(MessageToolbar.Notification.updateDraft, object: nil)

        #if DEBUG
        //clearUselessRealmObjects() // only for test
        #endif
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

        println("Will Foreground")
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

        clearUselessRealmObjects()
    }

    // MARK: APNs

    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {

        println("Fetch Back")
        syncUnreadMessages() {
            completionHandler(UIBackgroundFetchResult.NewData)
        }
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {

        // 纪录下来，用于初次登录或注册有 pusherID 后，或“注销再登录”
        self.deviceToken = deviceToken
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], withResponseInfo responseInfo: [NSObject : AnyObject], completionHandler: () -> Void) {

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

            tryReplyText("OK", withUserInfo: userInfo)

        default:
            break
        }
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {

        println("didReceiveRemoteNotification: \(userInfo)")

        JPUSHService.handleRemoteNotification(userInfo)

        guard YepUserDefaults.isLogined, let type = userInfo["type"] as? String, remoteNotificationType = RemoteNotificationType(rawValue: type) else {
            completionHandler(UIBackgroundFetchResult.NoData)
            return
        }

        defer {
            // 非前台才记录启动通知类型
            if application.applicationState != .Active {
                self.remoteNotificationType = remoteNotificationType
            }
        }

        switch remoteNotificationType {

        case .Message:

            syncUnreadMessages() {
                SafeDispatch.async {
                    NSNotificationCenter.defaultCenter().postNotificationName(Config.Notification.changedFeedConversation, object: nil)

                    configureDynamicShortcuts()

                    completionHandler(UIBackgroundFetchResult.NewData)
                }
            }

        case .OfficialMessage:

            officialMessages { messagesCount in
                completionHandler(UIBackgroundFetchResult.NewData)
                println("new officialMessages count: \(messagesCount)")
            }

        case .FriendRequest:

            if let subType = userInfo["subtype"] as? String {
                if subType == "accepted" {
                    syncFriendshipsAndDoFurtherAction {
                        completionHandler(UIBackgroundFetchResult.NewData)
                    }
                } else {
                    completionHandler(UIBackgroundFetchResult.NoData)
                }
            } else {
                completionHandler(UIBackgroundFetchResult.NoData)
            }

        case .MessageDeleted:

            defer {
                completionHandler(UIBackgroundFetchResult.NoData)
            }

            guard let
                messageInfo = userInfo["message"] as? JSONDictionary,
                messageID = messageInfo["id"] as? String
                else {
                    break
            }

            handleMessageDeletedFromServer(messageID: messageID)

            configureDynamicShortcuts()

        case .Mentioned:

            syncUnreadMessagesAndDoFurtherAction({ _ in
                SafeDispatch.async {
                    NSNotificationCenter.defaultCenter().postNotificationName(Config.Notification.changedFeedConversation, object: nil)

                    configureDynamicShortcuts()

                    completionHandler(UIBackgroundFetchResult.NewData)
                }
            })
        }
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {

        println(error.description)
    }

    // MARK: Shortcuts

    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {

        handleShortcutItem(shortcutItem)

        completionHandler(true)
    }

    private func handleShortcutItem(shortcutItem: UIApplicationShortcutItem) {

        if let window = window {
            tryQuickActionWithShortcutItem(shortcutItem, inWindow: window)
        }
    }

    // MARK: Open URL

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {

        if url.absoluteString.contains("/auth/success") {
            NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.OAuthResult, object: NSNumber(int: 1))
            
        } else if url.absoluteString.contains("/auth/failure") {
            NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.OAuthResult, object: NSNumber(int: 0))
        }
        
        if MonkeyKing.handleOpenURL(url) {
            return true
        }

        return false
    }
    
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {

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
    
    private func handleUniversalLink(URL: NSURL) -> Bool {

        guard let
            tabBarVC = window?.rootViewController as? UITabBarController,
            nvc = tabBarVC.selectedViewController as? UINavigationController else {
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
            let feedConversation = vc.prepareConversationForFeed(feed, inRealm: realm)
            let _ = try? realm.commitWrite()

            // 如果已经显示了就不用push
            if let topVC = nvc.topViewController as? ConversationViewController, let oldFakeID = topVC.conversation?.fakeID, let newFakeID = feedConversation?.fakeID where newFakeID == oldFakeID {
                return
            }

            vc.conversation = feedConversation
            vc.conversationFeed = ConversationFeed.DiscoveredFeedType(feed)

            delay(0.25) {
                nvc.pushViewController(vc, animated: true)
            }

        // Profile (Last)

        }) || URL.yep_matchProfile({ discoveredUser in

            //println("matchProfile: \(discoveredUser)")

            // 如果已经显示了就不用push
            if let topVC = nvc.topViewController as? ProfileViewController, let userID = topVC.profileUser?.userID where userID == discoveredUser.id {
                return
            }

            let vc = UIStoryboard.Scene.profile
            vc.prepare(withDiscoveredUser: discoveredUser)

            delay(0.25) {
                nvc.pushViewController(vc, animated: true)
            }
        })
    }

    private func handleUserSearchActivity(userID userID: String) -> Bool {

        guard let
            realm = try? Realm(),
            user = userWithUserID(userID, inRealm: realm),
            tabBarVC = window?.rootViewController as? UITabBarController,
            nvc = tabBarVC.selectedViewController as? UINavigationController else {
                return false
        }

        // 如果已经显示了就不用push
        if let topVC = nvc.topViewController as? ProfileViewController, let _userID = topVC.profileUser?.userID where _userID == userID {
            return true

        } else {
            let vc = UIStoryboard.Scene.profile
            vc.prepare(withUser: user)

            delay(0.25) {
                nvc.pushViewController(vc, animated: true)
            }

            return true
        }
    }

    private func handleFeedSearchActivity(feedID feedID: String) -> Bool {

        guard let
            realm = try? Realm(),
            feed = feedWithFeedID(feedID, inRealm: realm),
            conversation = feed.group?.conversation,
            tabBarVC = window?.rootViewController as? UITabBarController,
            nvc = tabBarVC.selectedViewController as? UINavigationController else {
                return false
        }

        // 如果已经显示了就不用push
        if let topVC = nvc.topViewController as? ConversationViewController, let feed = topVC.conversation?.withGroup?.withFeed where feed.feedID == feedID {
            return true

        } else {
            let vc = UIStoryboard.Scene.conversation
            vc.conversation = conversation

            delay(0.25) {
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

    func registerThirdPartyPushWithDeciveToken(deviceToken: NSData, pusherID: String) {

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
            SafeDispatch.async {
                UIApplication.sharedApplication().applicationIconBadgeNumber = 0
            }
        }

        guard !notRegisteredThirdPartyPush else {
            return
        }

        notRegisteredThirdPartyPush = true

        JPUSHService.setAlias(nil, callbackSelector: nil, object: nil)

        println("unregisterThirdPartyPush")
    }

    @objc private func tagsAliasCallBack(iResCode: CInt, tags: NSSet, alias: NSString) {

        println("tagsAliasCallback: \(iResCode), \(tags), \(alias)")
    }

    // MARK: Private

    private lazy var sendMessageSoundEffect: YepSoundEffect = {
        let bundle = NSBundle.mainBundle()
        guard let fileURL = bundle.URLForResource("bub3", withExtension: "caf") else {
            fatalError("YepSoundEffect: file no found!")
        }
        return YepSoundEffect(fileURL: fileURL)
    }()

    private func configureYepKit() {

        YepKit.Config.updatedAccessTokenAction = {

            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                // 注册或初次登录时同步数据的好时机
                appDelegate.sync()

                // 也是注册或初次登录时启动 Faye 的好时机
                appDelegate.startFaye()
            }
        }

        YepKit.Config.updatedPusherIDAction = { pusherID in

            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
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
            let state = UIApplication.sharedApplication().applicationState
            return state == .Active
        }
    }

    private func configureYepNetworking() {

        YepNetworking.Manager.accessToken = {
            return YepUserDefaults.v1AccessToken.value
        }

        YepNetworking.Manager.authFailedAction = { statusCode, host in
            if statusCode == 401 {
                // 确保是自家服务
                if host == yepBaseURL.host {
                    SafeDispatch.async {
                        YepUserDefaults.maybeUserNeedRelogin(prerequisites: {
                            guard let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate where appDelegate.inMainStory else {
                                return false
                            }
                            return true

                        }, confirm: { [weak self] in
                            self?.unregisterThirdPartyPush()

                            cleanRealmAndCaches()

                            if let rootViewController = self?.window?.rootViewController {
                                YepAlert.alert(title: NSLocalizedString("Sorry", comment: ""), message: NSLocalizedString("User authentication error, you need to login again!", comment: ""), dismissTitle: NSLocalizedString("Relogin", comment: ""), inViewController: rootViewController, withDismissAction: { () -> Void in
                                    
                                    self?.startShowStory()
                                })
                            }
                        })
                    }
                }
            }
        }

        YepNetworking.Manager.networkActivityCountChangedAction = { count in
            SafeDispatch.async {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = (count > 0)
            }
        }
    }

    private func tryReplyText(text: String, withUserInfo userInfo: [NSObject: AnyObject]) {

        guard let
            recipientType = userInfo["recipient_type"] as? String,
            recipientID = userInfo["recipient_id"] as? String else {
                return
        }

        println("try reply \"\(text)\" to [\(recipientType): \(recipientID)]")
        
        sendText(text, toRecipient: recipientID, recipientType: recipientType, afterCreatedMessage: { _ in }, failureHandler: nil, completion: { success in
            println("reply to [\(recipientType): \(recipientID)], \(success)")
        })
    }

    private func indexUserSearchableItems() {

        let users = normalFriends()

        let searchableItems = users.map({
            CSSearchableItem(
                uniqueIdentifier: searchableItemID(searchableItemType: .User, itemID: $0.userID),
                domainIdentifier: userDomainIdentifier,
                attributeSet: $0.attributeSet
            )
        })

        println("userSearchableItems: \(searchableItems.count)")

        CSSearchableIndex.defaultSearchableIndex().indexSearchableItems(searchableItems) { error in
            if error != nil {
                println(error!.localizedDescription)

            } else {
                println("indexUserSearchableItems OK")
            }
        }
    }

    private func indexFeedSearchableItems() {

        guard let realm = try? Realm() else {
            return
        }

        let feeds = filterValidFeeds(realm.objects(Feed))

        let searchableItems = feeds.map({
            CSSearchableItem(
                uniqueIdentifier: searchableItemID(searchableItemType: .Feed, itemID: $0.feedID),
                domainIdentifier: feedDomainIdentifier,
                attributeSet: $0.attributeSet
            )
        })

        println("feedSearchableItems: \(searchableItems.count)")

        CSSearchableIndex.defaultSearchableIndex().indexSearchableItems(searchableItems) { error in
            if error != nil {
                println(error!.localizedDescription)

            } else {
                println("indexFeedSearchableItems OK")
            }
        }
    }

    private func syncUnreadMessages(furtherAction: () -> Void) {

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

    private func cacheInAdvance() {

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {

            guard let realm = try? Realm() else {
                return
            }

            // 主界面的头像

            let predicate = NSPredicate(format: "type = %d", ConversationType.OneToOne.rawValue)
            let conversations = realm.objects(Conversation).filter(predicate).sorted("updatedUnixTime", ascending: false)

            conversations.forEach { conversation in
                if let latestMessage = conversation.messages.last, user = latestMessage.fromFriend {
                    let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: miniAvatarStyle)
                    AvatarPod.wakeAvatar(userAvatar, completion: { _ , _, _ in })
                }
            }
        }
    }

    private func customAppearce() {

        window?.backgroundColor = UIColor.whiteColor()

        // Global Tint Color

        window?.tintColor = UIColor.yepTintColor()
        window?.tintAdjustmentMode = .Normal

        // NavigationBar Item Style

        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.yepTintColor()], forState: .Normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.yepTintColor().colorWithAlphaComponent(0.3)], forState: .Disabled)

        // NavigationBar Title Style

        let shadow: NSShadow = {
            let shadow = NSShadow()
            shadow.shadowColor = UIColor.lightGrayColor()
            shadow.shadowOffset = CGSizeMake(0, 0)
            return shadow
        }()

        let textAttributes: [String: AnyObject] = [
            NSForegroundColorAttributeName: UIColor.yepNavgationBarTitleColor(),
            NSShadowAttributeName: shadow,
            NSFontAttributeName: UIFont.navigationBarTitleFont()
        ]
        UINavigationBar.appearance().titleTextAttributes = textAttributes
        UINavigationBar.appearance().barTintColor = UIColor.whiteColor()

        /*
        let barButtonTextAttributes: [String: AnyObject] = [
            NSForegroundColorAttributeName: UIColor.yepTintColor(),
            NSFontAttributeName: UIFont.barButtonFont()
        ]
        UIBarButtonItem.appearance().setTitleTextAttributes(barButtonTextAttributes, forState: UIControlState.Normal)
        UINavigationBar.appearance().setBackgroundImage(UIImage(named:"white"), forBarMetrics: .Default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().translucent = false
         */

        // TabBar

        UITabBar.appearance().tintColor = UIColor.yepTintColor()
        UITabBar.appearance().barTintColor = UIColor.whiteColor()

        /*
        UITabBar.appearance().backgroundImage = UIImage(named:"white")
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().translucent = false
         */
    }
}

