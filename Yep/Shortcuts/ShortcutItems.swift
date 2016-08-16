//
//  ShortcutItems.swift
//  Yep
//
//  Created by NIX on 16/4/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift
import DeviceGuru

func configureDynamicShortcuts() {

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

            let oneToOneConversations = oneToOneConversationsInRealm(realm)

            let a = oneToOneConversations[safe: 0]
            let b = oneToOneConversations[safe: 1]
            let c = oneToOneConversations[safe: 2]

            let feedConversations = feedConversationsInRealm(realm)

            let d = feedConversations[safe: 0]
            let e = feedConversations[safe: 1]
            let f = feedConversations[safe: 2]

            let conversations = [a, b, c, d, e, f].flatMap({ $0 }).sort({ $0.updatedUnixTime > $1.updatedUnixTime })

            for (index, conversation) in conversations.enumerate() {

                if index > 2 {
                    break
                }

                if let user = conversation.withFriend {

                    let type = ShortcutType.LatestOneToOneConversation.rawValue

                    let item = UIApplicationShortcutItem(
                        type: type,
                        localizedTitle: user.nickname,
                        localizedSubtitle: conversation.latestMessageTextContentOrPlaceholder,
                        icon: UIApplicationShortcutIcon(templateImageName: "icon_chat_active"),
                        userInfo: ["userID": user.userID]
                    )

                    shortcutItems.append(item)

                } else if let feed = conversation.withGroup?.withFeed {

                    let type = ShortcutType.LatestFeedConversation.rawValue

                    let item = UIApplicationShortcutItem(
                        type: type,
                        localizedTitle: feed.body,
                        localizedSubtitle: conversation.latestMessageTextContentOrPlaceholder,
                        icon: UIApplicationShortcutIcon(templateImageName: "icon_discussion"),
                        userInfo: ["feedID": feed.feedID]
                    )

                    shortcutItems.append(item)
                }
            }
        }
    }

    UIApplication.sharedApplication().shortcutItems = shortcutItems
}

func tryQuickActionWithShortcutItem(shortcutItem: UIApplicationShortcutItem, inWindow window: UIWindow) {

    guard let shortcutType = ShortcutType(rawValue: shortcutItem.type) else {
        return
    }

    guard let tabBarVC = window.rootViewController as? YepTabBarController else {
        return
    }

    if let nvc = tabBarVC.selectedViewController as? UINavigationController {
        if nvc.viewControllers.count > 1 {
            nvc.popToRootViewControllerAnimated(false)
        }
    }

    switch shortcutType {

    case .Feeds:

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

