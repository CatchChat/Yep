//
//  YepUserDefaults.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

let v1AccessTokenKey = "v1AccessToken"
let userIDKey = "userID"
let nicknameKey = "nickname"
let avatarURLStringKey = "avatarURLString"

class YepUserDefaults {

    // MARK: v1AccessToken

    class func v1AccessToken() -> String? {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.stringForKey(v1AccessTokenKey)
    }

    class func setV1AccessToken(accessToken: String) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(accessToken, forKey: v1AccessTokenKey)

        // 同步数据的好时机
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            appDelegate.sync()
        }
    }

    // MARK: userID

    class func userID() -> String? {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.stringForKey(userIDKey)
    }

    class func setUserID(userID: String) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(userID, forKey: userIDKey)
    }

    // MARK: nickname

    class func nickname() -> String? {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.stringForKey(nicknameKey)
    }

    class func setNickname(nickname: String) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(nickname, forKey: nicknameKey)
    }

    // MARK: avatarURLString

    class func avatarURLString() -> String? {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.stringForKey(avatarURLStringKey)
    }

    class func setAvatarURLString(avatarURLString: String) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(avatarURLString, forKey: avatarURLStringKey)
    }

}


