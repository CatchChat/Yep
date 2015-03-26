//
//  AppDelegate.swift
//  Yep
//
//  Created by kevinzhow on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import JPushSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var deviceToken: NSData?
    var notRegisteredPush = true


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        // 推送初始化
        APService.setupWithOption(launchOptions)

        // 全局的外观自定义
        customAppearce()

        let isLogined: Bool
        if let v1AccessToken = YepUserDefaults.v1AccessToken() {
            isLogined = true
        } else {
            isLogined = false
        }

        if !isLogined {
            startIntroStory()
        }
        

        
//        let storyboard = UIStoryboard(name: "Intro", bundle: nil)
//        let rootViewController = storyboard.instantiateViewControllerWithIdentifier("RegisterPickAvatarViewController") as! RegisterPickAvatarViewController
//        window?.rootViewController = rootViewController

        // for test

        if let token = YepUserDefaults.v1AccessToken() {
            sync()
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: APNs

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {

        if let pusherID = YepUserDefaults.pusherID() {
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

        if let v1AccessToken = YepUserDefaults.v1AccessToken() {
            APService.handleRemoteNotification(userInfo)

            if let type = userInfo["type"] as? String {
                if type == "message" {
                    syncUnreadMessagesAndDoFurtherAction() {
                        dispatch_async(dispatch_get_main_queue()) {
                            NSNotificationCenter.defaultCenter().postNotificationName(YepNewMessagesReceivedNotification, object: nil)
                        }
                    }
                }
            }
        }
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        println(error.description)
    }

    // MARK: Public

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
        syncFriendshipsAndDoFurtherAction {
            syncGroupsAndDoFurtherAction {
                syncUnreadMessagesAndDoFurtherAction {
                }
            }
        }

        // TODO: 刷新 UI，特别是对于首次登陆来说
    }

    func registerThirdPartyPushWithDeciveToken(deviceToken: NSData, pusherID: String) {
        APService.registerDeviceToken(deviceToken)
        APService.setTags(Set(["iOS"]), alias: pusherID, callbackSelector: "", object: nil)
    }

    func tagsAliasCallback(iResCode: Int, tags: NSSet, alias: String) {
        println("tagsAliasCallback \(iResCode), \(tags), \(alias)")
    }



    // MARK: Private

    private func customAppearce() {

        // Global Tint Color

        window!.tintColor = UIColor.yepTintColor()


        // NavigationBar Title Style

        let shadow: NSShadow = {
            var shadow = NSShadow()
            shadow.shadowColor = UIColor.lightGrayColor()
            shadow.shadowOffset = CGSizeMake(0, 0)
            return shadow
        }()

        let textAttributes = [
            NSForegroundColorAttributeName: UIColor.yepTintColor(),
            NSShadowAttributeName: shadow,
            NSFontAttributeName: UIFont(name: "HelveticaNeue-CondensedBlack", size: 20)!
        ]

        UINavigationBar.appearance().titleTextAttributes = textAttributes;
    }
}

