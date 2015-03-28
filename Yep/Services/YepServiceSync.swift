//
//  YepServiceSync.swift
//  Yep
//
//  Created by NIX on 15/3/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import Realm


let YepNewMessagesReceivedNotification = "YepNewMessagesReceivedNotification"


func syncFriendshipsAndDoFurtherAction(furtherAction: () -> Void) {
    friendships { allFriendships in
        //println("\n allFriendships: \(allFriendships)")

        // 先整理出所有的 friend 的 userID
        var remoteUerIDSet = Set<String>()
        for friendshipInfo in allFriendships {
            if let friendInfo = friendshipInfo["friend"] as? JSONDictionary {
                if let userID = friendInfo["id"] as? String {
                    remoteUerIDSet.insert(userID)
                }
            }
        }

        dispatch_async(realmQueue) {

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
}

func syncGroupsAndDoFurtherAction(furtherAction: () -> Void) {
    groups { allGroups in
        //println("allGroups: \(allGroups)")

        // 先整理出所有的 group 的 groupID
        var remoteGroupIDSet = Set<String>()
        for groupInfo in allGroups {
            if let groupID = groupInfo["id"] as? String {
                remoteGroupIDSet.insert(groupID)
            }
        }

        dispatch_async(realmQueue) {

            // 在本地去除远端没有的 Group

            let realm = RLMRealm.defaultRealm()

            let localGroups = Group.allObjects()

            realm.beginWriteTransaction()

            var groupsToDelete = [Group]()
            for i in 0..<localGroups.count {
                let localGroup = localGroups[i] as! Group

                if !remoteGroupIDSet.contains(localGroup.groupID) {
                    groupsToDelete.append(localGroup)
                }
            }
            for group in groupsToDelete {
                realm.deleteObject(group)
                // TODO: 级联删除关联的数据对象
            }

            realm.commitWriteTransaction()

            // 增加本地没有的 Group

            for groupInfo in allGroups {
                syncGroupWithGroupInfo(groupInfo, inRealm: realm)
            }
            
            // do further action
            
            furtherAction()
        }
    }
}

private func syncGroupWithGroupInfo(groupInfo: JSONDictionary, inRealm realm: RLMRealm) {
    if let groupID = groupInfo["id"] as? String {
        let predicate = NSPredicate(format: "groupID = %@", groupID)
        var group = Group.objectsWithPredicate(predicate).firstObject() as? Group

        if group == nil {
            let newGroup = Group()
            newGroup.groupID = groupID
            if let groupName = groupInfo["name"] as? String {
                newGroup.groupName = groupName
            }

            realm.beginWriteTransaction()
            realm.addObject(newGroup)
            realm.commitWriteTransaction()

            group = newGroup
        }

        if let group = group {

            if group.conversation == nil {
                let conversation = Conversation()
                conversation.type = ConversationType.Group.rawValue
                conversation.updatedAt = NSDate()
                conversation.withGroup = group

                realm.beginWriteTransaction()
                realm.addObject(conversation)
                realm.commitWriteTransaction()
            }

            // Group Owner

            if let ownerInfo = groupInfo["owner"] as? JSONDictionary {
                if let ownerID = ownerInfo["id"] as? String {
                    let predicate = NSPredicate(format: "userID = %@", ownerID)
                    var owner = User.objectsWithPredicate(predicate).firstObject() as? User

                    if owner == nil {
                        let newUser = User()

                        newUser.userID = ownerID

                        if let nickname = ownerInfo["nickname"] as? String {
                            newUser.nickname = nickname
                        }

                        if let avatarURLString = ownerInfo["avatar_url"] as? String {
                            newUser.avatarURLString = avatarURLString
                        }

                        if let myUserID = YepUserDefaults.userID() {
                            if myUserID == ownerID {
                                newUser.friendState = UserFriendState.Me.rawValue
                            } else {
                                newUser.friendState = UserFriendState.Stranger.rawValue
                            }
                        } else {
                            newUser.friendState = UserFriendState.Stranger.rawValue
                        }

                        realm.beginWriteTransaction()
                        realm.addObject(newUser)
                        realm.commitWriteTransaction()
                        
                        owner = newUser
                    }
                    
                    if let owner = owner {
                        realm.beginWriteTransaction()
                        group.owner = owner
                        realm.commitWriteTransaction()
                    }
                }
            }

            // 同步 Group 的成员

            if let remoteMembers = groupInfo["members"] as? [JSONDictionary] {
                var memberIDSet = Set<String>()
                for memberInfo in remoteMembers {
                    if let memberID = memberInfo["id"] as? String {
                        memberIDSet.insert(memberID)
                    }
                }

                var localMembers = group.members

                // 去除远端没有的 member

                for (index, member) in enumerate(localMembers) {
                    let user = member as! User
                    if !memberIDSet.contains(user.userID) {
                        localMembers.removeObjectAtIndex(UInt(index))
                    }
                }

                // 加上本地没有的 member

                for memberInfo in remoteMembers {
                    if let memberID = memberInfo["id"] as? String {
                        let predicate = NSPredicate(format: "userID = %@", memberID)
                        var member = User.objectsWithPredicate(predicate).firstObject() as? User

                        if member == nil {
                            let newMember = User()

                            newMember.userID = memberID

                            realm.beginWriteTransaction()
                            realm.addObject(newMember)
                            realm.commitWriteTransaction()

                            member = newMember
                        }

                        if let member = member {
                            realm.beginWriteTransaction()

                            if let nickname = memberInfo["nickname"] as? String {
                                member.nickname = nickname
                            }

                            if let avatarURLString = memberInfo["avatar_url"] as? String {
                                member.avatarURLString = avatarURLString
                            }

                            if let myUserID = YepUserDefaults.userID() {
                                if myUserID == memberID {
                                    member.friendState = UserFriendState.Me.rawValue
                                } else {
                                    member.friendState = UserFriendState.Stranger.rawValue
                                }
                            } else {
                                member.friendState = UserFriendState.Stranger.rawValue
                            }

                            localMembers.addObject(member)

                            realm.commitWriteTransaction()
                        }
                    }
                }

                realm.beginWriteTransaction()
                group.members = localMembers
                realm.commitWriteTransaction()
            }
        }
    }
}

func syncUnreadMessagesAndDoFurtherAction(furtherAction: () -> Void) {
    unreadMessages { allUnreadMessages in
        //println("\n allUnreadMessages: \(allUnreadMessages)")

        dispatch_async(realmQueue) {

            let realm = RLMRealm.defaultRealm()

            for messageInfo in allUnreadMessages {
                syncMessageWithMessageInfo(messageInfo, inRealm: realm, andDoFurtherAction: nil)
            }
            
            // do futher action
            println("加个打印，希望能等到 Realm 在线程间同步好")
            furtherAction()
        }
    }
}

func syncMessageWithMessageInfo(messageInfo: JSONDictionary, inRealm realm: RLMRealm, andDoFurtherAction furtherAction: (() -> Void)? ) {

    func deleteMessage(message: Message, inRealm realm: RLMRealm) {
        realm.beginWriteTransaction()
        realm.deleteObject(message)
        realm.commitWriteTransaction()
    }

    if let messageID = messageInfo["id"] as? String {
        let predicate = NSPredicate(format: "messageID = %@", messageID)
        var message = Message.objectsWithPredicate(predicate).firstObject() as? Message

        if message == nil {
            let newMessage = Message()
            newMessage.messageID = messageID
            // TODO: createdAt use message's updated_at

            realm.beginWriteTransaction()
            realm.addObject(newMessage)
            realm.commitWriteTransaction()

            message = newMessage
        }

        // 开始填充消息

        if let message = message {

            // 纪录消息的发送者

            if let senderInfo = messageInfo["sender"] as? JSONDictionary {
                if let senderID = senderInfo["id"] as? String {
                    let predicate = NSPredicate(format: "userID = %@", senderID)
                    var sender = User.objectsWithPredicate(predicate).firstObject() as? User

                    if sender == nil {
                        let newUser = User()

                        newUser.userID = senderID

                        newUser.friendState = UserFriendState.Stranger.rawValue

                        realm.beginWriteTransaction()
                        realm.addObject(newUser)
                        realm.commitWriteTransaction()

                        sender = newUser
                    }

                    if let sender = sender {
                        realm.beginWriteTransaction()

                        if let nickname = senderInfo["nickname"] as? String {
                            sender.nickname = nickname
                        }

                        if let avatarURLString = senderInfo["avatar_url"] as? String {
                            sender.avatarURLString = avatarURLString
                        }

                        message.fromFriend = sender

                        realm.commitWriteTransaction()


                        // 查询消息来自的 Group，为空就表示来自 User

                        var sendFromGroup: Group? = nil

                        if let recipientType = messageInfo["recipient_type"] as? String {
                            if recipientType == "Circle" {
                                if let groupID = messageInfo["recipient_id"] as? String {
                                    let predicate = NSPredicate(format: "groupID = %@", groupID)
                                    sendFromGroup = Group.objectsWithPredicate(predicate).firstObject() as? Group

                                    if sendFromGroup == nil {
                                        let newGroup = Group()
                                        newGroup.groupID = groupID

                                        if let groupInfo = messageInfo["circle"] as? JSONDictionary {
                                            if let groupName = groupInfo["name"] as? String {
                                                newGroup.groupName = groupName
                                            }
                                        }

                                        realm.beginWriteTransaction()
                                        realm.addObject(newGroup)
                                        realm.commitWriteTransaction()

                                        sendFromGroup = newGroup
                                    }
                                }
                            }
                        }

                        // 纪录消息所属的 Conversation

                        var conversation: Conversation? = nil

                        if let sendFromGroup = sendFromGroup {
                            conversation = sendFromGroup.conversation
                        } else {
                            conversation = sender.conversation
                        }

                        // 没有 Conversation 就尝试建立它

                        if conversation == nil {
                            let newConversation = Conversation()

                            if let sendFromGroup = sendFromGroup {
                                newConversation.type = ConversationType.Group.rawValue
                                newConversation.withGroup = sendFromGroup
                            } else {
                                newConversation.type = ConversationType.OneToOne.rawValue
                                newConversation.withFriend = sender
                            }

                            realm.beginWriteTransaction()
                            realm.addObject(newConversation)
                            realm.commitWriteTransaction()

                            conversation = newConversation
                        }

                        // 在保证有 Conversation 的情况下继续，不然消息没有必要保留
                        if let conversation = conversation {
                            realm.beginWriteTransaction()

                            conversation.updatedAt = message.createdAt

                            message.conversation = conversation


                            // 纪录消息的 detail 信息

                            if let textContent = messageInfo["text_content"] as? String {
                                message.textContent = textContent
                            }

                            if
                                let longitude = messageInfo["longitude"] as? Double,
                                let latitude = messageInfo["latitude"] as? Double {

                                    let newCoordinate = Coordinate()
                                    newCoordinate.longitude = longitude
                                    newCoordinate.latitude = latitude

                                    message.coordinate = newCoordinate
                            }

                            if let attachments = messageInfo["attachments"] as? [JSONDictionary] {
                                for attachmentInfo in attachments {
                                    // TODO: 若未来没有 Qiniu，需要改动
                                    // S3: fallback file，尽量用它
                                    if let fallbackFileInfo = attachmentInfo["fallback_file"] as? JSONDictionary {
                                        if let fileURLString = fallbackFileInfo["url"] as? String {
                                            if let kind = attachmentInfo["kind"] as? String {
                                                if kind == "thumbnail" {
                                                    message.thumbnailURLString = fileURLString
                                                } else {
                                                    message.attachmentURLString = fileURLString
                                                }
                                            }
                                        }

                                    } else {
                                        // Qiniu: normal file, Qiniu
                                        if let normalFileInfo = attachmentInfo["file"] as? JSONDictionary {
                                            if let fileURLString = normalFileInfo["url"] as? String {
                                                if let kind = attachmentInfo["kind"] as? String {
                                                    if kind == "thumbnail" {
                                                        message.thumbnailURLString = fileURLString
                                                    } else {
                                                        message.attachmentURLString = fileURLString
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                if let mediaType = messageInfo["media_type"] as? String {
                                    if mediaType == "image" {
                                        message.mediaType = MessageMediaType.Image.rawValue
                                    } else if mediaType == "video" {
                                        message.mediaType = MessageMediaType.Video.rawValue
                                    } else if mediaType == "audio" {
                                        message.mediaType = MessageMediaType.Audio.rawValue
                                    }
                                    // TODO: 若有更多的 Media Type
                                }
                            }

                            realm.commitWriteTransaction()


                            // Do furtherAction after sync

                            if let furtherAction = furtherAction {
                                //println("syncMessageWithMessageInfo do furtherAction")
                                furtherAction()
                            }

                        } else {
                            deleteMessage(message, inRealm: realm)
                        }
                    }
                }
            }
        }
    }
}

