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

func configureDynamicShortcuts() {

    var shortcutItems = [UIApplicationShortcutItem]()

    do {
        let type = ShortcutType.feeds.rawValue

        let item = UIApplicationShortcutItem(
            type: type,
            localizedTitle: String.trans_titleFeeds,
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

            let conversations = [a, b, c, d, e, f].flatMap({ $0 }).sorted(by: { $0.updatedUnixTime > $1.updatedUnixTime })

            for (index, conversation) in conversations.enumerated() {

                if index > 2 {
                    break
                }

                if let user = conversation.withFriend {

                    let type = ShortcutType.latestOneToOneConversation.rawValue

                    let item = UIApplicationShortcutItem(
                        type: type,
                        localizedTitle: user.nickname,
                        localizedSubtitle: conversation.latestMessageTextContentOrPlaceholder,
                        icon: UIApplicationShortcutIcon(templateImageName: "icon_chat_active"),
                        userInfo: ["userID": user.userID]
                    )

                    shortcutItems.append(item)

                } else if let feed = conversation.withGroup?.withFeed {

                    let type = ShortcutType.latestFeedConversation.rawValue

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

    UIApplication.shared.shortcutItems = shortcutItems
}

func tryQuickActionWithShortcutItem(_ shortcutItem: UIApplicationShortcutItem, inWindow window: UIWindow) {

    guard let shortcutType = ShortcutType(rawValue: shortcutItem.type) else {
        return
    }

    guard let tabBarVC = window.rootViewController as? YepTabBarController else {
        return
    }

    if let nvc = tabBarVC.selectedViewController as? UINavigationController {
        if nvc.viewControllers.count > 1 {
            nvc.popToRootViewController(animated: false)
        }
    }

    switch shortcutType {

    case .feeds:

        tabBarVC.tab = .feeds

        if let nvc = tabBarVC.selectedViewController as? UINavigationController {

            func tryScrollsToTopOfFeedsViewController() {

                if let vc = nvc.topViewController as? CanScrollsToTop {
                    vc.scrollsToTopIfNeed()
                }
            }

            if nvc.viewControllers.count > 1 {
                nvc.popToRootViewController(animated: false)

                tryScrollsToTopOfFeedsViewController()

            } else {
                tryScrollsToTopOfFeedsViewController()
            }
        }

    case .latestOneToOneConversation:

        tabBarVC.tab = .conversations

        if let nvc = tabBarVC.selectedViewController as? UINavigationController {

            func tryShowConversationFromConversationsViewController(_ vc: ConversationsViewController) {

                if let userID = shortcutItem.userInfo?["userID"] as? String {
                    if let realm = try? Realm() {
                        let user = userWithUserID(userID, inRealm: realm)
                        if let conversation = user?.conversation {
                            vc.performSegue(withIdentifier: "showConversation", sender: conversation)
                        }
                    }
                }
            }

            if nvc.viewControllers.count > 1 {
                nvc.popToRootViewController(animated: false)

                if let vc = nvc.topViewController as? ConversationsViewController {
                    tryShowConversationFromConversationsViewController(vc)
                }

            } else {
                if let vc = nvc.topViewController as? ConversationsViewController {
                    tryShowConversationFromConversationsViewController(vc)
                }
            }
        }

    case .latestFeedConversation:

        tabBarVC.tab = .conversations

        if let nvc = tabBarVC.selectedViewController as? UINavigationController {

            func tryShowConversationFromConversationsViewController(_ vc: ConversationsViewController) {

                if let feedID = shortcutItem.userInfo?["feedID"] as? String {
                    if let realm = try? Realm() {
                        let feed = feedWithFeedID(feedID, inRealm: realm)
                        if let conversation = feed?.group?.conversation {
                            vc.performSegue(withIdentifier: "showConversation", sender: conversation)
                        }
                    }
                }
            }

            if nvc.viewControllers.count > 1 {
                nvc.popToRootViewController(animated: false)

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

    UIApplication.shared.shortcutItems = nil
}

