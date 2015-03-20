//
//  YepServiceSync.swift
//  Yep
//
//  Created by NIX on 15/3/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import Realm

func syncFriendshipsAndDoFurtherAction(furtherAction: () -> Void) {
    friendships { allFriendships in
        println("friendships result: \(allFriendships)")

        // 先整理出所有的 friend 的 userID
        var remoteUerIDSet = Set<String>()
        for friendshipInfo in allFriendships {
            if let friendInfo = friendshipInfo["friend"] as? JSONDictionary {
                if let userID = friendInfo["id"] as? String {
                    remoteUerIDSet.insert(userID)
                }
            }
        }

        // 改变没有 friendship 的 user 的状态

        let realm = RLMRealm.defaultRealm()

        let localUsers = User.allObjects()

        for i in 0..<localUsers.count {
            let localUser = localUsers[i] as! User

            if !remoteUerIDSet.contains(localUser.userID) {

                realm.beginWriteTransaction()

                localUser.friendshipID = ""
                if let myUserID = YepUserDefaults.userID() {
                    if myUserID == localUser.userID {
                        localUser.friendState = UserFriendState.Me.rawValue
                    } else if localUser.friendState == UserFriendState.Normal.rawValue {
                        localUser.friendState = UserFriendState.Stranger.rawValue
                    }
                }
                localUser.isBestfriend = false

                realm.commitWriteTransaction()
            }
        }

        // 添加有 friendship 但本地存储还没有的 user，更新信息

        for friendshipInfo in allFriendships {
            if let friendInfo = friendshipInfo["friend"] as? JSONDictionary {
                if let userID = friendInfo["id"] as? String {
                    let predicate = NSPredicate(format: "userID = %@", userID)
                    var user = User.objectsWithPredicate(predicate).firstObject() as? User

                    if user == nil {
                        let newUser = User()
                        newUser.userID = userID

                        realm.beginWriteTransaction()
                        realm.addObject(newUser)
                        realm.commitWriteTransaction()
                        
                        user = newUser
                    }

                    if let user = user {
                        realm.beginWriteTransaction()

                        if let nickname = friendInfo["nickname"] as? String {
                            user.nickname = nickname
                        }

                        if let avatarURLString = friendInfo["avatar_url"] as? String {
                            user.avatarURLString = avatarURLString
                        }

                        if let friendshipID = friendshipInfo["id"] as? String {
                            user.friendshipID = friendshipID
                        }

                        user.friendState = UserFriendState.Normal.rawValue

                        if let isBestfriend = friendInfo["favored"] as? Bool {
                            user.isBestfriend = isBestfriend
                        }
                        
                        if let bestfriendIndex = friendInfo["favored_position"] as? Int {
                            user.bestfriendIndex = bestfriendIndex
                        }

                        realm.commitWriteTransaction()
                    }
                }
            }
        }

        // do further action

        furtherAction()
    }
}