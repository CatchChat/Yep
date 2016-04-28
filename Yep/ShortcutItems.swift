//
//  ShortcutItems.swift
//  Yep
//
//  Created by NIX on 16/4/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

func shortcutItems() -> [UIApplicationShortcutItem] {

    let type = "com.Catch-Inc.Yep.Feeds"
    let item = UIApplicationShortcutItem(
        type: type,
        localizedTitle: NSLocalizedString("", comment: ""),
        localizedSubtitle: NSLocalizedString("", comment: ""),
        icon: UIApplicationShortcutIcon(type: .Share),
        userInfo: nil
    )

    return [item]
}

