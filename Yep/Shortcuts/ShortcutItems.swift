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

                let item = UIApplicationShortcutItem(
                    type: type,
                    localizedTitle: user.nickname,
                    localizedSubtitle: latestOneToOneConversation.latestValidMessage?.textContent,
                    icon: UIApplicationShortcutIcon(templateImageName: "icon_chat_active"),
                    userInfo: nil
                )

                shortcutItems.append(item)
            }
        }
    }

    UIApplication.sharedApplication().shortcutItems = shortcutItems
}

