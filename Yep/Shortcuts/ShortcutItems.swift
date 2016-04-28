//
//  ShortcutItems.swift
//  Yep
//
//  Created by NIX on 16/4/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

func configureDynamicShortcuts() {

    var shortcutItems = [UIApplicationShortcutItem]()

    do {
        let type = ShortcutType.Feeds.rawValue

        let item = UIApplicationShortcutItem(
            type: type,
            localizedTitle: NSLocalizedString("Feeds", comment: ""),
            localizedSubtitle: NSLocalizedString("What's new?", comment: ""),
            icon: UIApplicationShortcutIcon(templateImageName: "icon_feeds_active"),
            userInfo: nil
        )

        shortcutItems.append(item)
    }

    do {
        if let realm = try? Realm() {
            if let
                latestOneToOneConversation = oneToOneConversationsInRealm(realm).first,
                user = latestOneToOneConversation.withFriend {

                let type = ShortcutType.LatestOneToOneConversation.rawValue

                let latestTextMessageOrUpdatedTime = latestOneToOneConversation.latestValidMessage?.textContent ??
                    NSDate(timeIntervalSince1970: latestOneToOneConversation.updatedUnixTime).timeAgo

                let item = UIApplicationShortcutItem(
                    type: type,
                    localizedTitle: user.nickname,
                    localizedSubtitle: latestTextMessageOrUpdatedTime,
                    icon: UIApplicationShortcutIcon(templateImageName: "icon_chat_active"),
                    userInfo: ["userID": user.userID]
                )

                shortcutItems.append(item)
            }
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
    }
}

