//
//  YepUserDefaults.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

let v1AccessTokenKey = "v1AccessToken"
let userIDKey = "userID"
let nicknameKey = "nickname"
let introductionKey = "introduction"
let avatarURLStringKey = "avatarURLString"
let badgeKey = "badge"
let pusherIDKey = "pusherID"

let areaCodeKey = "areaCode"
let mobileKey = "mobile"

let discoveredUserSortStyleKey = "discoveredUserSortStyle"
let feedSortStyleKey = "feedSortStyle"

let latitudeShiftKey = "latitudeShift"
let longitudeShiftKey = "longitudeShift"

let userLocationNameKey = "userLocationName"

struct Listener<T>: Hashable {
    let name: String

    typealias Action = T -> Void
    let action: Action

    var hashValue: Int {
        return name.hashValue
    }
}

func ==<T>(lhs: Listener<T>, rhs: Listener<T>) -> Bool {
    return lhs.name == rhs.name
}

class Listenable<T> {
    var value: T {
        didSet {
            setterAction(value)

            for listener in listenerSet {
                listener.action(value)
            }
        }
    }

    typealias SetterAction = T -> Void
    var setterAction: SetterAction

    var listenerSet = Set<Listener<T>>()

    func bindListener(name: String, action: Listener<T>.Action) {
        let listener = Listener(name: name, action: action)

        listenerSet.insert(listener)
    }

    func bindAndFireListener(name: String, action: Listener<T>.Action) {
        bindListener(name, action: action)

        action(value)
    }

    func removeListenerWithName(name: String) {
        for listener in listenerSet {
            if listener.name == name {
                listenerSet.remove(listener)
                break
            }
        }
    }

    func removeAllListeners() {
        listenerSet.removeAll(keepCapacity: false)
    }

    init(_ v: T, setterAction action: SetterAction) {
        value = v
        setterAction = action
    }
}

class YepUserDefaults {

    static let defaults = NSUserDefaults(suiteName: YepConfig.appGroupID)!

    static var isLogined: Bool {

        if let _ = YepUserDefaults.v1AccessToken.value {
            return true
        } else {
            return false
        }
    }

    // MARK: ReLogin

    class func cleanAllUserDefaults() {

        v1AccessToken.removeAllListeners()
        userID.removeAllListeners()
        nickname.removeAllListeners()
        introduction.removeAllListeners()
        avatarURLString.removeAllListeners()
        badge.removeAllListeners()
        pusherID.removeAllListeners()
        areaCode.removeAllListeners()
        mobile.removeAllListeners()
        discoveredUserSortStyle.removeAllListeners()
        feedSortStyle.removeAllListeners()
        latitudeShift.removeAllListeners()
        longitudeShift.removeAllListeners()
        userLocationName.removeAllListeners()

        defaults.removeObjectForKey(v1AccessTokenKey)
        defaults.removeObjectForKey(userIDKey)
        defaults.removeObjectForKey(nicknameKey)
        defaults.removeObjectForKey(introductionKey)
        defaults.removeObjectForKey(avatarURLStringKey)
        defaults.removeObjectForKey(badgeKey)
        defaults.removeObjectForKey(pusherIDKey)
        defaults.removeObjectForKey(areaCodeKey)
        defaults.removeObjectForKey(mobileKey)
        defaults.removeObjectForKey(discoveredUserSortStyleKey)
        defaults.removeObjectForKey(feedSortStyleKey)
        defaults.removeObjectForKey(latitudeShiftKey)
        defaults.removeObjectForKey(longitudeShiftKey)
        defaults.removeObjectForKey(userLocationNameKey)

        defaults.synchronize()
    }

    class func userNeedRelogin() {

        if let _ = v1AccessToken.value {

            cleanRealmAndCaches()

            cleanAllUserDefaults()

            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                if let rootViewController = appDelegate.window?.rootViewController {
                    YepAlert.alert(title: NSLocalizedString("Sorry", comment: ""), message: NSLocalizedString("User authentication error, you need to login again!", comment: ""), dismissTitle: NSLocalizedString("Relogin", comment: ""), inViewController: rootViewController, withDismissAction: { () -> Void in

                        appDelegate.startShowStory()
                    })
                }
            }
        }
    }

    static var v1AccessToken: Listenable<String?> = {
        let v1AccessToken = defaults.stringForKey(v1AccessTokenKey)

        return Listenable<String?>(v1AccessToken) { v1AccessToken in
            defaults.setObject(v1AccessToken, forKey: v1AccessTokenKey)

            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                // 注册或初次登录时同步数据的好时机
                appDelegate.sync()

                // 也是注册或初次登录时启动 Faye 的好时机
                appDelegate.startFaye()
            }
        }
    }()

    static var userID: Listenable<String?> = {
        let userID = defaults.stringForKey(userIDKey)

        return Listenable<String?>(userID) { userID in
            defaults.setObject(userID, forKey: userIDKey)
        }
    }()

    static var nickname: Listenable<String?> = {
        let nickname = defaults.stringForKey(nicknameKey)

        return Listenable<String?>(nickname) { nickname in
            defaults.setObject(nickname, forKey: nicknameKey)

            guard let realm = try? Realm() else {
                return
            }

            if let
                nickname = nickname,
                myUserID = YepUserDefaults.userID.value,
                me = userWithUserID(myUserID, inRealm: realm) {
                    let _ = try? realm.write {
                        me.nickname = nickname
                    }
            }
        }
    }()

    static var introduction: Listenable<String?> = {
        let introduction = defaults.stringForKey(introductionKey)

        return Listenable<String?>(introduction) { introduction in
            defaults.setObject(introduction, forKey: introductionKey)

            guard let realm = try? Realm() else {
                return
            }

            if let
                introduction = introduction,
                myUserID = YepUserDefaults.userID.value,
                me = userWithUserID(myUserID, inRealm: realm) {
                    let _ = try? realm.write {
                        me.introduction = introduction
                    }
            }
        }
    }()

    static var avatarURLString: Listenable<String?> = {
        let avatarURLString = defaults.stringForKey(avatarURLStringKey)

        return Listenable<String?>(avatarURLString) { avatarURLString in
            defaults.setObject(avatarURLString, forKey: avatarURLStringKey)

            guard let realm = try? Realm() else {
                return
            }

            if let
                avatarURLString = avatarURLString,
                myUserID = YepUserDefaults.userID.value,
                me = userWithUserID(myUserID, inRealm: realm) {
                    let _ = try? realm.write {
                        me.avatarURLString = avatarURLString
                    }
            }
        }
    }()

    static var badge: Listenable<String?> = {
        let badge = defaults.stringForKey(badgeKey)

        return Listenable<String?>(badge) { badge in
            defaults.setObject(badge, forKey: badgeKey)

            guard let realm = try? Realm() else {
                return
            }

            if let
                badge = badge,
                myUserID = YepUserDefaults.userID.value,
                me = userWithUserID(myUserID, inRealm: realm) {
                    let _ = try? realm.write {
                        me.badge = badge
                    }
            }
        }
    }()

    static var pusherID: Listenable<String?> = {
        let pusherID = defaults.stringForKey(pusherIDKey)

        return Listenable<String?>(pusherID) { pusherID in
            defaults.setObject(pusherID, forKey: pusherIDKey)

            // 注册推送的好时机
            if let
                pusherID = pusherID,
                appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                    if appDelegate.notRegisteredPush {
                        appDelegate.notRegisteredPush = false

                        if let deviceToken = appDelegate.deviceToken {
                            appDelegate.registerThirdPartyPushWithDeciveToken(deviceToken, pusherID: pusherID)
                        }
                    }
            }
        }
    }()

    static var areaCode: Listenable<String?> = {
        let areaCode = defaults.stringForKey(areaCodeKey)

        return Listenable<String?>(areaCode) { areaCode in
            defaults.setObject(areaCode, forKey: areaCodeKey)
        }
    }()

    static var mobile: Listenable<String?> = {
        let mobile = defaults.stringForKey(mobileKey)

        return Listenable<String?>(mobile) { mobile in
            defaults.setObject(mobile, forKey: mobileKey)
        }
    }()

    static var fullPhoneNumber: String? {
        if let areaCode = areaCode.value, mobile = mobile.value {
            return "+" + areaCode + " " + mobile
        }

        return nil
    }

    static var discoveredUserSortStyle: Listenable<String?> = {
        let discoveredUserSortStyle = defaults.stringForKey(discoveredUserSortStyleKey)

        return Listenable<String?>(discoveredUserSortStyle) { discoveredUserSortStyle in
            defaults.setObject(discoveredUserSortStyle, forKey: discoveredUserSortStyleKey)
        }
    }()
    
    static var feedSortStyle: Listenable<String?> = {
        let feedSortStyle = defaults.stringForKey(feedSortStyleKey)
        
        return Listenable<String?>(feedSortStyle) { feedSortStyle in
            defaults.setObject(feedSortStyle, forKey: feedSortStyleKey)
        }
    }()

    static var latitudeShift: Listenable<Double?> = {
        let latitudeShift = defaults.doubleForKey(latitudeShiftKey)

        return Listenable<Double?>(latitudeShift) { latitudeShift in
            defaults.setObject(latitudeShift, forKey: latitudeShiftKey)
        }
    }()

    static var longitudeShift: Listenable<Double?> = {
        let longitudeShift = defaults.doubleForKey(longitudeShiftKey)

        return Listenable<Double?>(longitudeShift) { longitudeShift in
            defaults.setObject(longitudeShift, forKey: longitudeShiftKey)
        }
    }()

    static var userLocationName: Listenable<String?> = {
        let userLocationName = defaults.stringForKey(userLocationNameKey)

        return Listenable<String?>(userLocationName) { userLocationName in
            defaults.setObject(userLocationName, forKey: userLocationNameKey)
        }
    }()
}


