//
//  YepUserDefaults.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import CoreSpotlight
import CoreLocation
import RealmSwift

private let v1AccessTokenKey = "v1AccessToken"
private let userIDKey = "userID"
private let nicknameKey = "nickname"
private let introductionKey = "introduction"
private let avatarURLStringKey = "avatarURLString"
private let badgeKey = "badge"
private let blogURLStringKey = "blogURLString"
private let blogTitleKey = "blogTitle"
private let pusherIDKey = "pusherID"
private let adminKey = "admin"

private let areaCodeKey = "areaCode"
private let mobileKey = "mobile"

private let discoveredUserSortStyleKey = "discoveredUserSortStyle"
private let feedSortStyleKey = "feedSortStyle"

private let latitudeShiftKey = "latitudeShift"
private let longitudeShiftKey = "longitudeShift"
private let userCoordinateLatitudeKey = "userCoordinateLatitude"
private let userCoordinateLongitudeKey = "userCoordinateLongitude"
private let userLocationNameKey = "userLocationName"

private let syncedConversationsKey = "syncedConversations"

private let appLaunchCountKey = "appLaunchCount"
private let tabBarItemTextEnabledKey = "tabBarItemTextEnabled"

public struct Listener<T>: Hashable {

    let name: String

    public typealias Action = (T) -> Void
    let action: Action

    public var hashValue: Int {
        return name.hashValue
    }
}

public func ==<T>(lhs: Listener<T>, rhs: Listener<T>) -> Bool {
    return lhs.name == rhs.name
}

final public class Listenable<T> {

    public var value: T {
        didSet {
            setterAction(value)

            for listener in listenerSet {
                listener.action(value)
            }
        }
    }

    public typealias SetterAction = (T) -> Void
    var setterAction: SetterAction

    var listenerSet = Set<Listener<T>>()

    public func bindListener(_ name: String, action: @escaping Listener<T>.Action) {
        let listener = Listener(name: name, action: action)

        listenerSet.insert(listener)
    }

    public func bindAndFireListener(_ name: String, action: @escaping Listener<T>.Action) {
        bindListener(name, action: action)

        action(value)
    }

    public func removeListenerWithName(_ name: String) {
        for listener in listenerSet {
            if listener.name == name {
                listenerSet.remove(listener)
                break
            }
        }
    }

    public func removeAllListeners() {
        listenerSet.removeAll(keepingCapacity: false)
    }

    public init(_ v: T, setterAction action: @escaping SetterAction) {
        value = v
        setterAction = action
    }
}

final public class YepUserDefaults {

    static let defaults = UserDefaults(suiteName: Config.appGroupID)!

    public static let appLaunchCountThresholdForTabBarItemTextEnabled: Int = 30

    public static var isLogined: Bool {

        if let _ = YepUserDefaults.v1AccessToken.value {
            return true
        } else {
            return false
        }
    }

    public static var isSyncedConversations: Bool {

        if let syncedConversations = YepUserDefaults.syncedConversations.value {
            return syncedConversations
        } else {
            return false
        }
    }

    public static var blogString: String? {

        if let blogURLString = YepUserDefaults.blogURLString.value {

            guard !blogURLString.isEmpty else {
                return nil
            }

            if let blogTitle = YepUserDefaults.blogTitle.value, !blogTitle.isEmpty {
                return blogTitle

            } else {
                return blogURLString
            }
        }

        return nil
    }

    public static var userCoordinate: CLLocationCoordinate2D? {

        guard let latitude = YepUserDefaults.userCoordinateLatitude.value, let longitude = YepUserDefaults.userCoordinateLongitude.value else {
            return nil
        }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // MARK: ReLogin

    public class func cleanAllUserDefaults() {

        do {
            v1AccessToken.removeAllListeners()
            userID.removeAllListeners()
            nickname.removeAllListeners()
            introduction.removeAllListeners()
            avatarURLString.removeAllListeners()
            badge.removeAllListeners()
            blogURLString.removeAllListeners()
            blogTitle.removeAllListeners()
            pusherID.removeAllListeners()
            admin.removeAllListeners()
            areaCode.removeAllListeners()
            mobile.removeAllListeners()
            discoveredUserSortStyle.removeAllListeners()
            feedSortStyle.removeAllListeners()
            latitudeShift.removeAllListeners()
            longitudeShift.removeAllListeners()
            userCoordinateLatitude.removeAllListeners()
            userCoordinateLongitude.removeAllListeners()
            userLocationName.removeAllListeners()
            syncedConversations.removeAllListeners()
            appLaunchCount.removeAllListeners()
            tabBarItemTextEnabled.removeAllListeners()
        }

        do { // manually reset
            YepUserDefaults.v1AccessToken.value = nil
            YepUserDefaults.userID.value = nil
            YepUserDefaults.nickname.value = nil
            YepUserDefaults.introduction.value = nil
            YepUserDefaults.badge.value = nil
            YepUserDefaults.blogURLString.value = nil
            YepUserDefaults.blogTitle.value = nil
            YepUserDefaults.pusherID.value = nil
            YepUserDefaults.admin.value = nil
            YepUserDefaults.areaCode.value = nil
            YepUserDefaults.mobile.value = nil
            YepUserDefaults.discoveredUserSortStyle.value = nil
            YepUserDefaults.feedSortStyle.value = nil
            // not reset Location related keys
            YepUserDefaults.syncedConversations.value = false
            YepUserDefaults.appLaunchCount.value = 0
            YepUserDefaults.tabBarItemTextEnabled.value = nil
            defaults.synchronize()
        }

        do { // reset standardUserDefaults
            let standardUserDefaults = UserDefaults.standard
            standardUserDefaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            standardUserDefaults.synchronize()
        }
    }

    public class func maybeUserNeedRelogin(prerequisites: () -> Bool, confirm: () -> Void) {

        guard v1AccessToken.value != nil else {
            return
        }

        CSSearchableIndex.default().deleteAllSearchableItems(completionHandler: nil)

        guard prerequisites() else {
            return
        }

        cleanAllUserDefaults()

        confirm()
    }

    public static var v1AccessToken: Listenable<String?> = {
        let v1AccessToken = defaults.string(forKey: v1AccessTokenKey)

        return Listenable<String?>(v1AccessToken) { v1AccessToken in
            defaults.set(v1AccessToken, forKey: v1AccessTokenKey)

            Config.updatedAccessTokenAction?()
        }
    }()

    public static var userID: Listenable<String?> = {
        let userID = defaults.string(forKey: userIDKey)

        return Listenable<String?>(userID) { userID in
            defaults.set(userID, forKey: userIDKey)
        }
    }()

    public static var nickname: Listenable<String?> = {
        let nickname = defaults.string(forKey: nicknameKey)

        return Listenable<String?>(nickname) { nickname in
            defaults.set(nickname, forKey: nicknameKey)

            guard let realm = try? Realm() else {
                return
            }

            if let nickname = nickname, let me = meInRealm(realm) {
                let _ = try? realm.write {
                    me.nickname = nickname
                }
            }
        }
    }()

    public static var introduction: Listenable<String?> = {
        let introduction = defaults.string(forKey: introductionKey)

        return Listenable<String?>(introduction) { introduction in
            defaults.set(introduction, forKey: introductionKey)

            guard let realm = try? Realm() else {
                return
            }

            if let introduction = introduction, let me = meInRealm(realm) {
                let _ = try? realm.write {
                    me.introduction = introduction
                }
            }
        }
    }()

    public static var avatarURLString: Listenable<String?> = {
        let avatarURLString = defaults.string(forKey: avatarURLStringKey)

        return Listenable<String?>(avatarURLString) { avatarURLString in
            defaults.set(avatarURLString, forKey: avatarURLStringKey)

            guard let realm = try? Realm() else {
                return
            }

            if let avatarURLString = avatarURLString, let me = meInRealm(realm) {
                let _ = try? realm.write {
                    me.avatarURLString = avatarURLString
                }
            }
        }
    }()

    public static var badge: Listenable<String?> = {
        let badge = defaults.string(forKey: badgeKey)

        return Listenable<String?>(badge) { badge in
            defaults.set(badge, forKey: badgeKey)

            guard let realm = try? Realm() else {
                return
            }

            if let badge = badge, let me = meInRealm(realm) {
                let _ = try? realm.write {
                    me.badge = badge
                }
            }
        }
    }()

    public static var blogURLString: Listenable<String?> = {
        let blogURLString = defaults.string(forKey: blogURLStringKey)

        return Listenable<String?>(blogURLString) { blogURLString in
            defaults.set(blogURLString, forKey: blogURLStringKey)

            guard let realm = try? Realm() else {
                return
            }

            if let blogURLString = blogURLString, let me = meInRealm(realm) {
                let _ = try? realm.write {
                    me.blogURLString = blogURLString
                }
            }
        }
    }()

    public static var blogTitle: Listenable<String?> = {
        let blogTitle = defaults.string(forKey: blogTitleKey)

        return Listenable<String?>(blogTitle) { blogTitle in
            defaults.set(blogTitle, forKey: blogTitleKey)

            guard let realm = try? Realm() else {
                return
            }

            if let blogTitle = blogTitle, let me = meInRealm(realm) {
                let _ = try? realm.write {
                    me.blogTitle = blogTitle
                }
            }
        }
    }()

    public static var pusherID: Listenable<String?> = {
        let pusherID = defaults.string(forKey: pusherIDKey)

        return Listenable<String?>(pusherID) { pusherID in
            defaults.set(pusherID, forKey: pusherIDKey)

            // 注册推送的好时机
            if let pusherID = pusherID {
                Config.updatedPusherIDAction?(pusherID)
            }
        }
    }()

    public static var admin: Listenable<Bool?> = {
        let admin = defaults.bool(forKey: adminKey)

        return Listenable<Bool?>(admin) { admin in
            defaults.set(admin, forKey: adminKey)
        }
    }()

    public static var areaCode: Listenable<String?> = {
        let areaCode = defaults.string(forKey: areaCodeKey)

        return Listenable<String?>(areaCode) { areaCode in
            defaults.set(areaCode, forKey: areaCodeKey)
        }
    }()

    public static var mobile: Listenable<String?> = {
        let mobile = defaults.string(forKey: mobileKey)

        return Listenable<String?>(mobile) { mobile in
            defaults.set(mobile, forKey: mobileKey)
        }
    }()

    public static var fullPhoneNumber: String? {
        if let areaCode = areaCode.value, let mobile = mobile.value {
            return "+" + areaCode + " " + mobile
        }

        return nil
    }

    public static var discoveredUserSortStyle: Listenable<String?> = {
        let discoveredUserSortStyle = defaults.string(forKey: discoveredUserSortStyleKey)

        return Listenable<String?>(discoveredUserSortStyle) { discoveredUserSortStyle in
            defaults.set(discoveredUserSortStyle, forKey: discoveredUserSortStyleKey)
        }
    }()
    
    public static var feedSortStyle: Listenable<String?> = {
        let feedSortStyle = defaults.string(forKey: feedSortStyleKey)
        
        return Listenable<String?>(feedSortStyle) { feedSortStyle in
            defaults.set(feedSortStyle, forKey: feedSortStyleKey)
        }
    }()

    public static var latitudeShift: Listenable<Double?> = {
        let latitudeShift = defaults.double(forKey: latitudeShiftKey)

        return Listenable<Double?>(latitudeShift) { latitudeShift in
            defaults.set(latitudeShift, forKey: latitudeShiftKey)
        }
    }()

    public static var longitudeShift: Listenable<Double?> = {
        let longitudeShift = defaults.double(forKey: longitudeShiftKey)

        return Listenable<Double?>(longitudeShift) { longitudeShift in
            defaults.set(longitudeShift, forKey: longitudeShiftKey)
        }
    }()

    public static var userCoordinateLatitude: Listenable<Double?> = {
        let userCoordinateLatitude = defaults.double(forKey: userCoordinateLatitudeKey)

        return Listenable<Double?>(userCoordinateLatitude) { userCoordinateLatitude in
            defaults.set(userCoordinateLatitude, forKey: userCoordinateLatitudeKey)
        }
    }()

    public static var userCoordinateLongitude: Listenable<Double?> = {
        let userCoordinateLongitude = defaults.double(forKey: userCoordinateLongitudeKey)

        return Listenable<Double?>(userCoordinateLongitude) { userCoordinateLongitude in
            defaults.set(userCoordinateLongitude, forKey: userCoordinateLongitudeKey)
        }
    }()

    public static var userLocationName: Listenable<String?> = {
        let userLocationName = defaults.string(forKey: userLocationNameKey)

        return Listenable<String?>(userLocationName) { userLocationName in
            defaults.set(userLocationName, forKey: userLocationNameKey)
        }
    }()

    public static var syncedConversations: Listenable<Bool?> = {
        let syncedConversations = defaults.bool(forKey: syncedConversationsKey)

        return Listenable<Bool?>(syncedConversations) { syncedConversations in
            defaults.set(syncedConversations, forKey: syncedConversationsKey)
        }
    }()

    public static var appLaunchCount: Listenable<Int> = {
        let appLaunchCount = defaults.integer(forKey: appLaunchCountKey)

        return Listenable<Int>(appLaunchCount) { appLaunchCount in
            defaults.set(appLaunchCount, forKey: appLaunchCountKey)
        }
    }()

    public static var tabBarItemTextEnabled: Listenable<Bool?> = {
        let tabBarItemTextEnabled = defaults.object(forKey: tabBarItemTextEnabledKey) as? Bool

        return Listenable<Bool?>(tabBarItemTextEnabled) { tabBarItemTextEnabled in
            defaults.set(tabBarItemTextEnabled, forKey: tabBarItemTextEnabledKey)
        }
    }()
}

