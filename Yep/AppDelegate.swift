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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var deviceToken: NSData?
    var notRegisteredPush = true

    var isColdLaunch = true

    struct Notification {
        static let applicationDidBecomeActive = "applicationDidBecomeActive"
    }

    private func realmConfig() -> Realm.Configuration {

        // 默认将 Realm 放在 App Group 里

        let directory: NSURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(YepConfig.appGroupID)!
        let realmPath = directory.URLByAppendingPathComponent("db.realm").path!

        return Realm.Configuration(path: realmPath, schemaVersion: 1, migrationBlock: { migration, oldSchemaVersion in
        })
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        Fabric.with([Crashlytics.self()])

        Realm.Configuration.defaultConfiguration = realmConfig()

        cacheInAdvance()

        delay(0.5, work: {
            // 推送初始化
            APService.setupWithOption(launchOptions)
        })
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.DefaultToSpeaker)
        } catch _ {
        }
        
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)


        // 全局的外观自定义
        customAppearce()

        let isLogined = YepUserDefaults.isLogined

        if !isLogined {
            //startIntroStory()

            startShowStory()
        }

//        let storyboard = UIStoryboard(name: "Intro", bundle: nil)
//        let rootViewController = storyboard.instantiateViewControllerWithIdentifier("RegisterPickSkillsViewController") as! RegisterPickSkillsViewController
//        window?.rootViewController = rootViewController

//        let storyboard = UIStoryboard(name: "Intro", bundle: nil)
//        let rootViewController = storyboard.instantiateViewControllerWithIdentifier("RegisterPickAvatarViewController") as! RegisterPickAvatarViewController
//        window?.rootViewController = UINavigationController(rootViewController: rootViewController)

        if isLogined {
            sync()

            startFaye()
        }

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        NSNotificationCenter.defaultCenter().postNotificationName(MessageToolbar.Notification.updateDraft, object: nil)
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

        if !isColdLaunch {
            isColdLaunch = false

            if YepUserDefaults.isLogined {
                syncUnreadMessages() {
                }
            }
        }

        if YepUserDefaults.isLogined {
            syncMessagesReadStatus()
        }

        NSNotificationCenter.defaultCenter().postNotificationName(Notification.applicationDidBecomeActive, object: nil)
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {

        syncUnreadMessages() {
            completionHandler(UIBackgroundFetchResult.NewData)
        }
        
    }

    // MARK: APNs

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

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {

        println("didReceiveRemoteNotification: \(userInfo)")

        if YepUserDefaults.isLogined {
            
            if let type = userInfo["type"] as? String {

                switch type {

                case "message":
                    syncUnreadMessages() {
                        completionHandler(UIBackgroundFetchResult.NewData)
                        APService.handleRemoteNotification(userInfo)
                    }

                case "official_message":
                    officialMessages { messagesCount in
                        println("new officialMessages count: \(messagesCount)")

                        completionHandler(UIBackgroundFetchResult.NewData)
                        APService.handleRemoteNotification(userInfo)
                    }

                case "friend_request":
                    if let subType = userInfo["subtype"] as? String {
                        if subType == "accepted" {
                            syncFriendshipsAndDoFurtherAction {
                                completionHandler(UIBackgroundFetchResult.NewData)
                                APService.handleRemoteNotification(userInfo)
                            }
                        }
                    }

                default:
                    break
                }
            }
        }
    }
    
    func syncUnreadMessages(furtherAction: () -> Void) {
        syncUnreadMessagesAndDoFurtherAction() { messageIDs in
            furtherAction()
            dispatch_async(dispatch_get_main_queue()) {
                let object = ["messageIDs": messageIDs]
                NSNotificationCenter.defaultCenter().postNotificationName(YepNewMessagesReceivedNotification, object: object)
            }
        }
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        println(error.description)
    }

    // MARK: Public

    func startShowStory() {
        let storyboard = UIStoryboard(name: "Show", bundle: nil)
        let rootViewController = storyboard.instantiateViewControllerWithIdentifier("ShowViewController") as! ShowViewController
        window?.rootViewController = rootViewController
    }

    func startIntroStory() {
        let storyboard = UIStoryboard(name: "Intro", bundle: nil)
        let rootViewController = storyboard.instantiateViewControllerWithIdentifier("IntroNavigationController") as! UINavigationController
        window?.rootViewController = rootViewController
    }

    func startMainStory() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let rootViewController = storyboard.instantiateViewControllerWithIdentifier("MainTabBarController") as! UITabBarController
        window?.rootViewController = rootViewController
    }

    func sync() {
        syncMyInfoAndDoFurtherAction {
            syncFriendshipsAndDoFurtherAction {
                syncGroupsAndDoFurtherAction {
                    syncUnreadMessagesAndDoFurtherAction { messageIDs in
                        dispatch_async(dispatch_get_main_queue()) {
                            let object = ["messageIDs": messageIDs]
                            NSNotificationCenter.defaultCenter().postNotificationName(YepNewMessagesReceivedNotification, object: object)
                        }
                    }
                }
            }
        }

        officialMessages { messagesCount in
            println("new officialMessages count: \(messagesCount)")
        }
    }

    func startFaye() {
        FayeService.sharedManager.startConnect()
    }

    func cacheInAdvance() {

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {

            // 主界面的头像

            guard let realm = try? Realm() else {
                return
            }

            let conversations = realm.objects(Conversation)

            for conversation in conversations {
                if let latestMessage = conversation.messages.last, user = latestMessage.fromFriend {
                    AvatarCache.sharedInstance.roundAvatarOfUser(user, withRadius: YepConfig.ConversationCell.avatarSize * 0.5, completion: { _ in
                    })
                }
            }
        }
    }

    func registerThirdPartyPushWithDeciveToken(deviceToken: NSData, pusherID: String) {
        APService.registerDeviceToken(deviceToken)
        APService.setTags(Set(["iOS"]), alias: pusherID, callbackSelector:nil, object: nil)
    }

    func tagsAliasCallback(iResCode: Int, tags: NSSet, alias: NSString) {
        println("tagsAliasCallback \(iResCode), \(tags), \(alias)")
    }

    // MARK: Private

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
            NSForegroundColorAttributeName: UIColor.yepTintColor(),
            NSShadowAttributeName: shadow,
            NSFontAttributeName: UIFont.navigationBarTitleFont()
        ]
        
        let barButtonTextAttributes = [
            NSForegroundColorAttributeName: UIColor.yepTintColor(),
            NSFontAttributeName: UIFont.barButtonFont()
        ]

        UINavigationBar.appearance().titleTextAttributes = textAttributes
        UINavigationBar.appearance().barTintColor = UIColor.whiteColor()
        UIBarButtonItem.appearance().setTitleTextAttributes(barButtonTextAttributes, forState: UIControlState.Normal)
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

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {

        if MonkeyKing.handleOpenURL(url) {
            return true
        }
        
        return false
    }
}

