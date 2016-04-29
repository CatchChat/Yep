//
//  ShortcutItems.swift
//  Yep
//
//  Created by NIX on 16/4/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import DeviceGuru

func configureDynamicShortcuts() {

    guard DeviceGuru.hardware().yep_supportQuickAction else {
        UIApplication.sharedApplication().shortcutItems = nil
        return
    }

    var shortcutItems = [UIApplicationShortcutItem]()

    do {
        let type = ShortcutType.Feeds.rawValue

        let item = UIApplicationShortcutItem(
            type: type,
            localizedTitle: NSLocalizedString("Feeds", comment: ""),
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(templateImageName: "icon_feeds_active"),
            userInfo: nil
        )

        shortcutItems.append(item)
    }

    do {
        if let realm = try? Realm() {

            realm.refresh()

            let conversations = realm.objects(Conversation).sorted("updatedUnixTime", ascending: false)

            let first   = conversations[safe: 0]
            let second  = conversations[safe: 1]
            let third   = conversations[safe: 2]

            [first, second, third].forEach({

                if let conversation = $0 {

                    if let user = conversation.withFriend {

                        let type = ShortcutType.LatestOneToOneConversation.rawValue

                        let textMessageOrUpdatedTime = conversation.latestValidMessage?.textContent ??
                            NSDate(timeIntervalSince1970: conversation.updatedUnixTime).timeAgo

                        let item = UIApplicationShortcutItem(
                            type: type,
                            localizedTitle: user.nickname,
                            localizedSubtitle: textMessageOrUpdatedTime,
                            icon: UIApplicationShortcutIcon(templateImageName: "icon_chat_active"),
                            userInfo: ["userID": user.userID]
                        )
                        
                        shortcutItems.append(item)

                    } else if let feed = conversation.withGroup?.withFeed {

                        let type = ShortcutType.LatestFeedConversation.rawValue

                        let textMessageOrUpdatedTime = conversation.latestValidMessage?.textContent ??
                            NSDate(timeIntervalSince1970: conversation.updatedUnixTime).timeAgo

                        let item = UIApplicationShortcutItem(
                            type: type,
                            localizedTitle: feed.body,
                            localizedSubtitle: textMessageOrUpdatedTime,
                            icon: UIApplicationShortcutIcon(templateImageName: "icon_discussion"),
                            userInfo: ["feedID": feed.feedID]
                        )
                        
                        shortcutItems.append(item)
                    }
                }
            })
        }
    }

    UIApplication.sharedApplication().shortcutItems = shortcutItems
}

func tryQuickActionWithShortcutItem(shortcutItem: UIApplicationShortcutItem, inWindow window: UIWindow) {

    guard let shortcutType = ShortcutType(rawValue: shortcutItem.type) else {
        return
    }

    switch shortcutType {

    case .Feeds:

        guard let tabBarVC = window.rootViewController as? YepTabBarController else {
            break
        }

        tabBarVC.tab = .Feeds

        if let nvc = tabBarVC.selectedViewController as? UINavigationController {

            func tryScrollsToTopOfFeedsViewController() {

                if let vc = nvc.topViewController as? FeedsViewController {
                    tabBarVC.tryScrollsToTopOfFeedsViewController(vc)
                }
            }

            if nvc.viewControllers.count > 1 {
                nvc.popToRootViewControllerAnimated(false)

                tryScrollsToTopOfFeedsViewController()

            } else {
                tryScrollsToTopOfFeedsViewController()
            }
        }

    case .LatestOneToOneConversation:

        guard let tabBarVC = window.rootViewController as? YepTabBarController else {
            break
        }

        tabBarVC.tab = .Conversations

        if let nvc = tabBarVC.selectedViewController as? UINavigationController {

            func tryShowConversationFromConversationsViewController(vc: ConversationsViewController) {

                if let userID = shortcutItem.userInfo?["userID"] as? String {
                    if let realm = try? Realm() {
                        let user = userWithUserID(userID, inRealm: realm)
                        if let conversation = user?.conversation {
                            vc.performSegueWithIdentifier("showConversation", sender: conversation)
                        }
                    }
                }
            }

            if nvc.viewControllers.count > 1 {
                nvc.popToRootViewControllerAnimated(false)

                if let vc = nvc.topViewController as? ConversationsViewController {
                    tryShowConversationFromConversationsViewController(vc)
                }

            } else {
                if let vc = nvc.topViewController as? ConversationsViewController {
                    tryShowConversationFromConversationsViewController(vc)
                }
            }
        }

    case .LatestFeedConversation:

        guard let tabBarVC = window.rootViewController as? YepTabBarController else {
            break
        }

        tabBarVC.tab = .Conversations

        if let nvc = tabBarVC.selectedViewController as? UINavigationController {

            func tryShowConversationFromConversationsViewController(vc: ConversationsViewController) {

                if let feedID = shortcutItem.userInfo?["feedID"] as? String {
                    if let realm = try? Realm() {
                        let feed = feedWithFeedID(feedID, inRealm: realm)
                        if let conversation = feed?.group?.conversation {
                            vc.performSegueWithIdentifier("showConversation", sender: conversation)
                        }
                    }
                }
            }

            if nvc.viewControllers.count > 1 {
                nvc.popToRootViewControllerAnimated(false)

                if let vc = nvc.topViewController as? ConversationsViewController {
                    tryShowConversationFromConversationsViewController(vc)
                }

            } else {
                if let vc = nvc.topViewController as? ConversationsViewController {
                    tryShowConversationFromConversationsViewController(vc)
                }
            }
        }
    }
}

func clearDynamicShortcuts() {

    UIApplication.sharedApplication().shortcutItems = nil
}

