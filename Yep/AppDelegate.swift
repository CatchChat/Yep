//
//  AppDelegate.swift
//  Yep
//
//  Created by kevinzhow on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import AVFoundation
import RealmSwift
import MonkeyKing
import Navi
import Appsee


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var deviceToken: NSData?
    var notRegisteredPush = true

    private var isFirstActive = true

    enum LaunchStyle {
        case Default
        case Message
    }
    var lauchStyle = Listenable<LaunchStyle>(.Default) { _ in }

    struct Notification {
        static let applicationDidBecomeActive = "applicationDidBecomeActive"
    }

    private func realmConfig() -> Realm.Configuration {

        // 默认将 Realm 放在 App Group 里

        let directory: NSURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(YepConfig.appGroupID)!
        let realmPath = directory.URLByAppendingPathComponent("db.realm").path!

        return Realm.Configuration(path: realmPath, schemaVersion: 28, migrationBlock: { migration, oldSchemaVersion in
        })
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

        Realm.Configuration.defaultConfiguration = realmConfig()

        cacheInAdvance()

        delay(0.5) {
            //Fabric.with([Crashlytics.self])
            Fabric.with([Crashlytics.self, Appsee.self])

            /*
            #if STAGING
                let apsForProduction = false
            #else
                let apsForProduction = true
            #endif
            JPUSHService.setupWithOption(launchOptions, appKey: "e521aa97cd4cd4eba5b73669", channel: "AppStore", apsForProduction: apsForProduction)
            */
            APService.setupWithOption(launchOptions)
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
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        
        println("Resign active")

        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
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

    func applicationDidBecomeActive(application: UIApplication) {

        println("Did Active")
        
        if !isFirstActive {
            syncUnreadMessages() {}

        } else {
            sync() // 确保该任务不是被 Remote Notification 激活 App 的时候执行
            startFaye()
        }

        application.applicationIconBadgeNumber = -1

        /*
        if YepUserDefaults.isLogined {
            syncMessagesReadStatus()
        }
        */

        NSNotificationCenter.defaultCenter().postNotificationName(Notification.applicationDidBecomeActive, object: nil)

        isFirstActive = false
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

        if let pusherID = YepUserDefaults.pusherID.value {
            if notRegisteredPush {
                notRegisteredPush = false

                registerThirdPartyPushWithDeciveToken(deviceToken, pusherID: pusherID)
            }
        }

        // 纪录下来，用于初次登录或注册有 pusherID 后，或“注销再登录”
        self.deviceToken = deviceToken
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], withResponseInfo responseInfo: [NSObject : AnyObject], completionHandler: () -> Void) {

        defer {
            completionHandler()
        }

        guard #available(iOS 9, *) else {
            return
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
        //JPUSHService.handleRemoteNotification(userInfo)
        APService.handleRemoteNotification(userInfo)
        
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
                completionHandler(UIBackgroundFetchResult.NewData)
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

        case .Mentioned:

            syncUnreadMessagesAndDoFurtherAction({ _ in
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.changedConversation, object: nil)
                }

                completionHandler(UIBackgroundFetchResult.NewData)
            })
        }
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {

        println(error.description)
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

        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {

            guard let webpageURL = userActivity.webpageURL else {
                return false
            }

            if !handleUniversalLink(webpageURL) {
                UIApplication.sharedApplication().openURL(webpageURL)
            }
        }

        return true
    }
    
    private func handleUniversalLink(URL: NSURL) -> Bool {

        guard let
            tabBarVC = window?.rootViewController as? UITabBarController,
            nvc = tabBarVC.selectedViewController as? UINavigationController else {
                return false
        }

        // Feed (Group)

        return URL.yep_matchSharedFeed({ feed in

            //println("matchSharedFeed: \(feed)")

            guard let
                vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ConversationViewController") as? ConversationViewController,
                realm = try? Realm() else {
                    return
            }

            realm.beginWrite()
            let feedConversation = vc.prepareConversationForFeed(feed, inRealm: realm)
            let _ = try? realm.commitWrite()

            vc.conversation = feedConversation
            vc.conversationFeed = ConversationFeed.DiscoveredFeedType(feed)

            nvc.pushViewController(vc, animated: true)

        // Profile (Last)

        }) || URL.yep_matchProfile({ discoveredUser in

            //println("matchProfile: \(discoveredUser)")

            guard let
                vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ProfileViewController") as? ProfileViewController else {
                    return
            }

            vc.profileUser = ProfileUser.DiscoveredUserType(discoveredUser)
            vc.fromType = .None
            vc.setBackButtonWithTitle()

            vc.hidesBottomBarWhenPushed = true

            nvc.pushViewController(vc, animated: true)
        })
    }

    // MARK: Public

    var inMainStory: Bool = true

    func startShowStory() {

        let storyboard = UIStoryboard(name: "Show", bundle: nil)
        let rootViewController = storyboard.instantiateViewControllerWithIdentifier("ShowNavigationController") as! UINavigationController
        window?.rootViewController = rootViewController

        inMainStory = false
    }

    func startMainStory() {

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let rootViewController = storyboard.instantiateViewControllerWithIdentifier("MainTabBarController") as! UITabBarController
        window?.rootViewController = rootViewController

        inMainStory = true
    }

    func sync() {

        guard YepUserDefaults.isLogined else {
            return
        }
        
        syncUnreadMessages {
            syncFriendshipsAndDoFurtherAction {
                syncGroupsAndDoFurtherAction {
                    syncSocialWorksToMessagesForYepTeam()
                }
            }
        }

        officialMessages { messagesCount in
            println("new officialMessages count: \(messagesCount)")
        }
    }

    func startFaye() {

        guard YepUserDefaults.isLogined else {
            return
        }

        dispatch_async(fayeQueue) {
            FayeService.sharedManager.startConnect()
        }
    }

    func registerThirdPartyPushWithDeciveToken(deviceToken: NSData, pusherID: String) {

        //JPUSHService.registerDeviceToken(deviceToken)
        //JPUSHService.setTags(Set(["iOS"]), alias: pusherID, callbackSelector:nil, object: nil)
        APService.registerDeviceToken(deviceToken)
        APService.setTags(Set(["iOS"]), alias: pusherID, callbackSelector:nil, object: nil)
    }

    func tagsAliasCallback(iResCode: Int, tags: NSSet, alias: NSString) {

        println("tagsAliasCallback \(iResCode), \(tags), \(alias)")
    }

    // MARK: Private

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

        let textAttributes = [
            NSForegroundColorAttributeName: UIColor.yepNavgationBarTitleColor(),
            NSShadowAttributeName: shadow,
            NSFontAttributeName: UIFont.navigationBarTitleFont()
        ]

        /*
        let barButtonTextAttributes = [
            NSForegroundColorAttributeName: UIColor.yepTintColor(),
            NSFontAttributeName: UIFont.barButtonFont()
        ]
        */

        UINavigationBar.appearance().titleTextAttributes = textAttributes
        UINavigationBar.appearance().barTintColor = UIColor.whiteColor()
        //UIBarButtonItem.appearance().setTitleTextAttributes(barButtonTextAttributes, forState: UIControlState.Normal)
        //UINavigationBar.appearance().setBackgroundImage(UIImage(named:"white"), forBarMetrics: .Default)
        //UINavigationBar.appearance().shadowImage = UIImage()
        //UINavigationBar.appearance().translucent = false

        // TabBar

        //UITabBar.appearance().backgroundImage = UIImage(named:"white")
        //UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().tintColor = UIColor.yepTintColor()
        UITabBar.appearance().barTintColor = UIColor.whiteColor()
        //UITabBar.appearance().translucent = false
    }
}

