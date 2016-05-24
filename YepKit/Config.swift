//
//  Config.swift
//  Yep
//
//  Created by NIX on 16/5/24.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

final public class Config {

    public static var updatedAccessTokenAction: (() -> Void)?
    public static var updatedPusherIDAction: ((pusherID: String) -> Void)?

    public static var sentMessageSoundEffectAction: (() -> Void)?

    public static var timeAgoAction: ((date: NSDate) -> String)?

    public static var isAppActive: (() -> Bool)?
}

