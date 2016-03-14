//
//  YepServiceSync.swift
//  Yep
//
//  Created by NIX on 15/3/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import RealmSwift

enum MessageAge: String {
    case Old
    case New
}

func tryPostNewMessagesReceivedNotificationWithMessageIDs(messageIDs: [String], messageAge: MessageAge) {

    if !messageIDs.isEmpty {
        dispatch_async(dispatch_get_main_queue()) {
            let object = [
                "messageIDs": messageIDs,
                "messageAge": messageAge.rawValue,
            ]
            NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.newMessages, object: object)
        }
    }
}

func getOrCreateUserWithDiscoverUser(discoveredUser: DiscoveredUser, inRealm realm: Realm) -> User? {
    
    var user = userWithUserID(discoveredUser.id, inRealm: realm)

    if user == nil {
        let newUser = User()
        
        newUser.userID = discoveredUser.id
        
        newUser.friendState = UserFriendState.Stranger.rawValue

        realm.add(newUser)

        user = newUser
    }
    
    if let user = user {
        
        // 只更新用户信息即可

        user.lastSignInUnixTime = discoveredUser.lastSignInUnixTime

        user.username = discoveredUser.username ?? ""

        user.nickname = discoveredUser.nickname

        if let introduction = discoveredUser.introduction {
            user.introduction = introduction
        }

        user.avatarURLString = discoveredUser.avatarURLString

        user.longitude = discoveredUser.longitude

        user.latitude = discoveredUser.latitude
        
        if let badge = discoveredUser.badge {
            user.badge = badge
        }
    }

    return user
}

func skillsFromUserSkillList(userSkillList: List<UserSkill>) -> [Skill] {

    var userSkills = [UserSkill]()

    for userSkill in userSkillList {
        userSkills.append(userSkill)
    }
    
    return userSkills.map({ userSkill -> Skill in

        var skillCategory: SkillCategory?

        if let category = userSkill.category {
            skillCategory = SkillCategory(id: category.skillCategoryID, name: category.name, localName: category.localName, skills: [])
        }

        let skill = Skill(category: skillCategory, id: userSkill.skillID, name: userSkill.name, localName: userSkill.localName, coverURLString: userSkill.coverURLString)

        return skill
    })
}

func attachmentFromDiscoveredAttachment(discoverAttachments: [DiscoveredAttachment]) -> [Attachment]{

    return discoverAttachments.map({ discoverAttachment -> Attachment? in
        
        let newAttachment = Attachment()
        //newAttachment.kind = discoverAttachment.kind.rawValue
        newAttachment.metadata = discoverAttachment.metadata
        newAttachment.URLString = discoverAttachment.URLString

        return newAttachment
        
    }).filter({ $0 != nil }).map({ discoverAttachment in discoverAttachment! })
}

func userSkillsFromSkills(skills: [Skill], inRealm realm: Realm) -> [UserSkill] {

    return skills.map({ skill -> UserSkill? in

        let skillID = skill.id
        var userSkill = userSkillWithSkillID(skillID, inRealm: realm)

        if userSkill == nil {
            let newUserSkill = UserSkill()
            newUserSkill.skillID = skillID

            realm.add(newUserSkill)

            userSkill = newUserSkill
        }

        if let userSkill = userSkill {

            // create or update detail

            userSkill.name = skill.name
            userSkill.localName = skill.localName

            if let coverURLString = skill.coverURLString {
                userSkill.coverURLString = coverURLString
            }

            if let skillCategory = skill.category, skillCategoryID = skill.category?.id {
                var userSkillCategory = userSkillCategoryWithSkillCategoryID(skillCategoryID, inRealm: realm)

                if userSkillCategory == nil {
                    let newUserSkillCategory = UserSkillCategory()
                    newUserSkillCategory.skillCategoryID = skillCategoryID
                    newUserSkillCategory.name = skillCategory.name
                    newUserSkillCategory.localName = skillCategory.localName

                    realm.add(newUserSkillCategory)

                    userSkillCategory = newUserSkillCategory
                }

                if let userSkillCategory = userSkillCategory {
                    userSkill.category = userSkillCategory
                }
            }
        }

        return userSkill

    }).filter({ $0 != nil }).map({ skill in skill! })
}

func userSocialAccountProvidersFromSocialAccountProviders(socialAccountProviders: [DiscoveredUser.SocialAccountProvider]) -> [UserSocialAccountProvider] {
    return socialAccountProviders.map({ _provider -> UserSocialAccountProvider in
        let provider = UserSocialAccountProvider()
        provider.name = _provider.name
        provider.enabled = _provider.enabled

        return provider
    })
}

func userSkillsFromSkillsData(skillsData: [JSONDictionary], inRealm realm: Realm) -> [UserSkill] {
    var userSkills = [UserSkill]()

    for skillInfo in skillsData {
        if let
            skillID = skillInfo["id"] as? String,
            skillName = skillInfo["name"] as? String,
            skillLocalName = skillInfo["name_string"] as? String {

                var userSkill = userSkillWithSkillID(skillID, inRealm: realm)

                if userSkill == nil {
                    let newUserSkill = UserSkill()
                    newUserSkill.skillID = skillID

                    realm.add(newUserSkill)

                    userSkill = newUserSkill
                }

                if let userSkill = userSkill {

                    // create or update detail
                    
                    userSkill.name = skillName
                    userSkill.localName = skillLocalName

                    if let coverURLString = skillInfo["cover_url"] as? String {
                        userSkill.coverURLString = coverURLString
                    }

                    if let
                        categoryData = skillInfo["category"] as? JSONDictionary,
                        skillCategoryID = categoryData["id"] as? String,
                        skillCategoryName = categoryData["name"] as? String,
                        skillCategoryLocalName = categoryData["name_string"] as? String {

                            var userSkillCategory = userSkillCategoryWithSkillCategoryID(skillCategoryID, inRealm: realm)

                            if userSkillCategory == nil {
                                let newUserSkillCategory = UserSkillCategory()
                                newUserSkillCategory.skillCategoryID = skillCategoryID
                                newUserSkillCategory.name = skillCategoryName
                                newUserSkillCategory.localName = skillCategoryLocalName

                                realm.add(newUserSkillCategory)

                                userSkillCategory = newUserSkillCategory
                            }

                            if let userSkillCategory = userSkillCategory {
                                userSkill.category = userSkillCategory
                            }
                    }

                    userSkills.append(userSkill)
                }
        }
    }

    return userSkills
}

func syncMyInfoAndDoFurtherAction(furtherAction: () -> Void) {

    userInfo(failureHandler: { (reason, errorMessage) in
        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

        furtherAction()

    }, completion: { friendInfo in

        //println("my userInfo: \(friendInfo)")

        dispatch_async(realmQueue) {

            if let myUserID = YepUserDefaults.userID.value {

                guard let realm = try? Realm() else {
                    return
                }

                var me = userWithUserID(myUserID, inRealm: realm)

                if me == nil {
                    let newUser = User()
                    newUser.userID = myUserID

                    newUser.friendState = UserFriendState.Me.rawValue

                    if let createdUnixTime = friendInfo["created_at"] as? NSTimeInterval {
                        newUser.createdUnixTime = createdUnixTime
                    }

                    let _ = try? realm.write {
                        realm.add(newUser)
                    }

                    me = newUser
                }

                if let user = me {

                    // 更新用户信息

                    let _ = try? realm.write {
                        updateUserWithUserID(user.userID, useUserInfo: friendInfo, inRealm: realm)
                    }

                    // 更新 DoNotDisturb

                    if let
                        fromString = friendInfo["mute_started_at_string"] as? String,
                        toString = friendInfo["mute_ended_at_string"] as? String {

                            if !fromString.isEmpty && !toString.isEmpty {

                                var userDoNotDisturb = user.doNotDisturb

                                if userDoNotDisturb == nil {
                                    let _userDoNotDisturb = UserDoNotDisturb()
                                    _userDoNotDisturb.isOn = true

                                    let _ = try? realm.write {
                                        user.doNotDisturb = _userDoNotDisturb
                                    }

                                    userDoNotDisturb = _userDoNotDisturb
                                }
                                
                                if let userDoNotDisturb = userDoNotDisturb {

                                    let convert: (Int, Int) -> (Int, Int) = { serverHour, serverMinute in

                                        let localHour: Int
                                        let localMinute: Int

                                        if serverMinute + userDoNotDisturb.minuteOffset >= 60 {
                                            localHour = (serverHour + userDoNotDisturb.hourOffset + 1) % 24

                                        } else {
                                            localHour = (serverHour + userDoNotDisturb.hourOffset) % 24
                                        }

                                        localMinute = (serverMinute + userDoNotDisturb.minuteOffset) % 60

                                        return (localHour, localMinute)
                                    }

                                    let _ = try? realm.write {

                                        let fromParts = fromString.componentsSeparatedByString(":")

                                        if let
                                            fromHourString = fromParts[safe: 0], fromHour = Int(fromHourString),
                                            fromMinuteString = fromParts[safe: 1], fromMinute = Int(fromMinuteString) {

                                                (userDoNotDisturb.fromHour, userDoNotDisturb.fromMinute) = convert(fromHour, fromMinute)
                                        }

                                        let toParts = toString.componentsSeparatedByString(":")

                                        if let
                                            toHourString = toParts[safe: 0], toHour = Int(toHourString),
                                            toMinuteString = toParts[safe: 1], toMinute = Int(toMinuteString) {

                                                (userDoNotDisturb.toHour, userDoNotDisturb.toMinute) = convert(toHour, toMinute)
                                        }

                                        //println("userDoNotDisturb: \(userDoNotDisturb.isOn), from \(userDoNotDisturb.fromHour):\(userDoNotDisturb.fromMinute), to \(userDoNotDisturb.toHour):\(userDoNotDisturb.toMinute)")
                                    }
                                }

                            } else {
                                if let userDoNotDisturb = user.doNotDisturb {
                                    realm.delete(userDoNotDisturb)
                                }
                            }
                    }

                    // also save some infomation in YepUserDefaults

                    if let nickname = friendInfo["nickname"] as? String {
                        YepUserDefaults.nickname.value = nickname
                    }

                    if let introduction = friendInfo["introduction"] as? String {
                        YepUserDefaults.introduction.value = introduction
                    }

                    if let avatarInfo = friendInfo["avatar"] as? JSONDictionary, avatarURLString = avatarInfo["url"] as? String {
                        YepUserDefaults.avatarURLString.value = avatarURLString
                    }

                    if let badge = friendInfo["badge"] as? String {
                        YepUserDefaults.badge.value = badge
                    }

                    if let areaCode = friendInfo["phone_code"] as? String {
                        YepUserDefaults.areaCode.value = areaCode
                    }

                    if let mobile = friendInfo["mobile"] as? String {
                        YepUserDefaults.mobile.value = mobile
                    }
                }
            }

            furtherAction()
        }
    })
}

func syncFriendshipsAndDoFurtherAction(furtherAction: () -> Void) {

    friendships(failureHandler: nil) { allFriendships in
        //println("\n allFriendships: \(allFriendships)")

        dispatch_async(realmQueue) {

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

            guard let realm = try? Realm() else {
                return
            }

            let localUsers = realm.objects(User)

            // 一个大的写入，减少 realm 发通知

            realm.beginWrite()

            for i in 0..<localUsers.count {
                let localUser = localUsers[i]

                if !remoteUerIDSet.contains(localUser.userID) {

                    localUser.friendshipID = ""

                    if let myUserID = YepUserDefaults.userID.value {
                        if myUserID == localUser.userID {
                            localUser.friendState = UserFriendState.Me.rawValue

                        } else if localUser.friendState == UserFriendState.Normal.rawValue {
                            localUser.friendState = UserFriendState.Stranger.rawValue
                        }
                    }
                    
                    localUser.isBestfriend = false
                }
            }

            // 添加有 friendship 但本地存储还没有的 user，更新信息

            for friendshipInfo in allFriendships {
                if let friendInfo = friendshipInfo["friend"] as? JSONDictionary {
                    if let userID = friendInfo["id"] as? String {
                        var user = userWithUserID(userID, inRealm: realm)

                        if user == nil {
                            let newUser = User()
                            newUser.userID = userID

                            if let createdUnixTime = friendInfo["created_at"] as? NSTimeInterval {
                                newUser.createdUnixTime = createdUnixTime
                            }

                            realm.add(newUser)

                            user = newUser
                        }

                        if let user = user {

                            // 更新用户信息
                            updateUserWithUserID(user.userID, useUserInfo: friendInfo, inRealm: realm)

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
                        }
                    }
                }
            }

            let _ = try? realm.commitWrite()
            
            // do further action

            furtherAction()
        }
    }
}

func syncGroupsAndDoFurtherAction(furtherAction: () -> Void) {

    groups(failureHandler: nil) { allGroups in

        //println("allGroups: \(allGroups)")
        
        dispatch_async(realmQueue) {

            // 先整理出所有的 group 的 groupID

            var remoteGroupIDSet = Set<String>()
            for groupInfo in allGroups {
                if let groupID = groupInfo["id"] as? String {
                    remoteGroupIDSet.insert(groupID)
                }
            }

            // 再在本地去除远端没有的 Group

            guard let realm = try? Realm() else {
                return
            }

            let localGroups = realm.objects(Group)

            // 一个大的写入，尽量减少 realm 发通知

            realm.beginWrite()

            var groupsToDelete = [Group]()
            for i in 0..<localGroups.count {
                let localGroup = localGroups[i]

                if !remoteGroupIDSet.contains(localGroup.groupID) {
                    groupsToDelete.append(localGroup)
                }
            }

            for group in groupsToDelete {

                // 有关联的 Feed 时就标记，不然删除

                if let feed = group.withFeed {

                    if group.includeMe {

                        feed.deleted = true

                        // 确保被删除的 Feed 的所有消息都被标记已读，重置 mentionedMe
                        group.conversation?.messages.forEach { $0.readed = true }
                        group.conversation?.mentionedMe = false
                        group.conversation?.hasUnreadMessages = false
                    }

                } else {
                    group.cascadeDeleteInRealm(realm)
                }
            }

            // 增加本地没有的 Group

            for groupInfo in allGroups {

                let group = syncGroupWithGroupInfo(groupInfo, inRealm: realm)

                group?.includeMe = true

                //Sync Feed

                if let
                    feedInfo = groupInfo["topic"] as? JSONDictionary,
                    feed = DiscoveredFeed.fromFeedInfo(feedInfo, groupInfo: groupInfo),
                    group = group {
                        //saveFeedWithFeedDataWithFullGroup(feedData, group: group, inRealm: realm)
                        saveFeedWithDiscoveredFeed(feed, group: group, inRealm: realm)
                } else {
                    println("no sync feed from groupInfo: \(groupInfo)")
                }
            }

            let _ = try? realm.commitWrite()

            dispatch_async(dispatch_get_main_queue()) {
                NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.changedConversation, object: nil)
            }

            // do further action
            
            furtherAction()
        }
    }
}

func syncGroupWithGroupInfo(groupInfo: JSONDictionary, inRealm realm: Realm) -> Group? {

    if let groupID = groupInfo["id"] as? String {
        
        var group = groupWithGroupID(groupID, inRealm: realm)

        if group == nil {
            let newGroup = Group()
            newGroup.groupID = groupID
            if let groupName = groupInfo["name"] as? String {
                newGroup.groupName = groupName
            }

            realm.add(newGroup)

            group = newGroup
        }

        if let group = group {

            // 有 topic 标记 groupType 为 Public，否则 Private
            if let _ = groupInfo["topic"] {
                group.groupType = GroupType.Public.rawValue
            } else {
                group.groupType = GroupType.Private.rawValue
            }

            if group.conversation == nil {
                let conversation = Conversation()
                conversation.type = ConversationType.Group.rawValue
                conversation.withGroup = group

                if let updatedUnixTime = groupInfo["updated_at"] as? NSTimeInterval {
                    conversation.updatedUnixTime = updatedUnixTime
                }

                realm.add(conversation)
            }

            // Group Owner

            if let ownerInfo = groupInfo["owner"] as? JSONDictionary {
                if let ownerID = ownerInfo["id"] as? String {
                    var owner = userWithUserID(ownerID, inRealm: realm)

                    if owner == nil {
                        let newUser = User()

                        newUser.userID = ownerID

                        if let createdUnixTime = ownerInfo["created_at"] as? NSTimeInterval {
                            newUser.createdUnixTime = createdUnixTime
                        }

                        if let myUserID = YepUserDefaults.userID.value {
                            if myUserID == ownerID {
                                newUser.friendState = UserFriendState.Me.rawValue
                            } else {
                                newUser.friendState = UserFriendState.Stranger.rawValue
                            }
                        } else {
                            newUser.friendState = UserFriendState.Stranger.rawValue
                        }

                        realm.add(newUser)

                        owner = newUser
                    }
                    
                    if let owner = owner {

                        // 更新个人信息
                        updateUserWithUserID(owner.userID, useUserInfo: ownerInfo, inRealm: realm)

                        group.owner = owner
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

                let localMembers = group.members

                // 去除远端没有的 member

                for (index, member) in localMembers.enumerate() {
                    let user = member
                    if !memberIDSet.contains(user.userID) {
                        localMembers.removeAtIndex(index)
                    }
                }

                // 加上本地没有的 member

                for memberInfo in remoteMembers {

                    if let memberID = memberInfo["id"] as? String {

                        var member = userWithUserID(memberID, inRealm: realm)

                        if member == nil {
                            let newMember = User()

                            newMember.userID = memberID

                            if let createdUnixTime = memberInfo["created_at"] as? NSTimeInterval {
                                newMember.createdUnixTime = createdUnixTime
                            }

                            if let myUserID = YepUserDefaults.userID.value {
                                if myUserID == memberID {
                                    newMember.friendState = UserFriendState.Me.rawValue
                                } else {
                                    newMember.friendState = UserFriendState.Stranger.rawValue
                                }
                            } else {
                                newMember.friendState = UserFriendState.Stranger.rawValue
                            }

                            realm.add(newMember)

                            localMembers.append(newMember)

                            member = newMember
                        }

                        if let member = member {

                            // 更新个人信息
                            updateUserWithUserID(member.userID, useUserInfo: memberInfo, inRealm: realm)
                        }
                    }
                }

                group.members.removeAll()
                group.members.appendContentsOf(localMembers)
            }
        }

        return group
    }

    return nil
}

var isFetchingUnreadMessages = Listenable<Bool>(false) { _ in }

func syncUnreadMessagesAndDoFurtherAction(furtherAction: (messageIDs: [String]) -> Void) {

    isFetchingUnreadMessages.value = true

    dispatch_async(dispatch_get_main_queue()) {
    
        println("Begin fetching")
        
        unreadMessages(failureHandler: { (reason, errorMessage) in

            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            dispatch_async(dispatch_get_main_queue()) {
                isFetchingUnreadMessages.value = false

                furtherAction(messageIDs: [])
            }

        }, completion: { allUnreadMessages in
            
            //println("\n allUnreadMessages: \(allUnreadMessages)")
            println("Got unread message: \(allUnreadMessages.count)")

            /*
            for message in allUnreadMessages {
                println("message.text: \(message["text_content"])")
            }
            */
            
            dispatch_async(realmQueue) {
                
                guard let realm = try? Realm() else {
                    return
                }
                
                var messageIDs = [String]()

                realm.beginWrite()
                
                for messageInfo in allUnreadMessages {
                    syncMessageWithMessageInfo(messageInfo, messageAge: .Old, inRealm: realm) { _messageIDs in
                        messageIDs += _messageIDs
                    }
                }

                let _ = try? realm.commitWrite()

                dispatch_async(dispatch_get_main_queue()) {
                    isFetchingUnreadMessages.value = false

                    furtherAction(messageIDs: messageIDs)
                }
            }
        })
    }
}

func recordMessageWithMessageID(messageID: String, detailInfo messageInfo: JSONDictionary, inRealm realm: Realm) {

    //println("messageInfo: \(messageInfo)")

    let deleted = (messageInfo["deleted"] as? Bool) ?? false

    if let message = messageWithMessageID(messageID, inRealm: realm) {

        guard !deleted else {
            message.updateForDeletedFromServerInRealm(realm)
            return
        }

        if let user = message.fromFriend where user.userID == YepUserDefaults.userID.value {
            message.sendState = MessageSendState.Read.rawValue
        }

        if let textContent = messageInfo["text_content"] as? String {
            message.textContent = textContent

            if let conversation = message.conversation where !conversation.mentionedMe {
                if textContent.yep_mentionedMeInRealm(realm) {
                    if message.createdUnixTime > conversation.lastMentionedMeUnixTime {
                        conversation.mentionedMe = true
                        conversation.lastMentionedMeUnixTime = NSDate().timeIntervalSince1970
                        println("new mentionedMe")
                    } else {
                        println("old mentionedMe: \(message.createdUnixTime), \(conversation.lastMentionedMeUnixTime)")
                    }
                }
            } else {
                println("failed mentionedMe: \(message.conversation?.mentionedMe)")
            }
        }

        if let
            longitude = messageInfo["longitude"] as? Double,
            latitude = messageInfo["latitude"] as? Double {

                let coordinate = Coordinate()
                coordinate.safeConfigureWithLatitude(latitude, longitude: longitude)

                message.coordinate = coordinate
        }

        if let attachments = messageInfo["attachments"] as? [JSONDictionary] {

            for attachmentInfo in attachments {

                if let attachmentID = attachmentInfo["id"] as? String {
                    message.attachmentID = attachmentID
                }

                if let fileInfo = attachmentInfo["file"] as? JSONDictionary {

                    if let attachmentExpiresUnixTime = fileInfo["expires_at"] as? NSTimeInterval {
                        message.attachmentExpiresUnixTime = attachmentExpiresUnixTime
                    }

                    if let URLString = fileInfo["url"] as? String {
                        message.attachmentURLString = URLString
                    }

                    if let URLString = fileInfo["thumb_url"] as? String {
                        message.thumbnailURLString = URLString
                    }
                }

                if let metaDataString = attachmentInfo["metadata"] as? String {
                    message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                }
            }

            if let mediaType = messageInfo["media_type"] as? String {

                switch mediaType {
                case MessageMediaType.Text.description:
                    message.mediaType = MessageMediaType.Text.rawValue
                case MessageMediaType.Image.description:
                    message.mediaType = MessageMediaType.Image.rawValue
                case MessageMediaType.Video.description:
                    message.mediaType = MessageMediaType.Video.rawValue
                case MessageMediaType.Audio.description:
                    message.mediaType = MessageMediaType.Audio.rawValue
                case MessageMediaType.Sticker.description:
                    message.mediaType = MessageMediaType.Sticker.rawValue
                case MessageMediaType.Location.description:
                    message.mediaType = MessageMediaType.Location.rawValue
                default:
                    break
                }
                // TODO: 若有更多的 Media Type
            }
        }
    }
}

func syncMessageWithMessageInfo(messageInfo: JSONDictionary, messageAge: MessageAge, inRealm realm: Realm, andDoFurtherAction furtherAction: ((messageIDs: [String]) -> Void)? ) {

    if let messageID = messageInfo["id"] as? String {

        var message = messageWithMessageID(messageID, inRealm: realm)

        // 如果消息被删除，且的发送者是自己，不同步且删除本地已有的
        let deleted = (messageInfo["deleted"] as? Bool) ?? false
        if deleted {
            if let senderInfo = messageInfo["sender"] as? JSONDictionary, senderID = senderInfo["id"] as? String {
                if senderID == YepUserDefaults.userID.value {
                    if let message = message {
                        message.deleteAttachmentInRealm(realm)
                        realm.delete(message)
                    }

                    return
                }
            }
        }

        if message == nil {
            let newMessage = Message()
            newMessage.messageID = messageID

            if let updatedUnixTime = messageInfo["created_at"] as? NSTimeInterval {
                newMessage.createdUnixTime = updatedUnixTime
            }

            if case .New = messageAge {
                // 确保网络来的新消息比任何已有的消息都要新，防止服务器消息延后发来导致插入到当前消息上面
                if let latestMessage = realm.objects(Message).sorted("createdUnixTime", ascending: true).last {
                    if newMessage.createdUnixTime < latestMessage.createdUnixTime {
                        println("xbefore newMessage.createdUnixTime: \(newMessage.createdUnixTime)")
                        newMessage.createdUnixTime = latestMessage.createdUnixTime + YepConfig.Message.localNewerTimeInterval
                        println("xadjust newMessage.createdUnixTime: \(newMessage.createdUnixTime)")
                    }
                }
            }

            realm.add(newMessage)

            message = newMessage
        }

        // 开始填充消息

        if let message = message {

            // 纪录消息的发送者

            if let senderInfo = messageInfo["sender"] as? JSONDictionary {
                if let senderID = senderInfo["id"] as? String {
                    var sender = userWithUserID(senderID, inRealm: realm)
                    
                    if sender == nil {
                        let newUser = User()

                        newUser.userID = senderID
                        
                        //TODO 服务器个消息的 Sender 加入一个用户状态，避免暴力标记为 Stranger

                        newUser.friendState = UserFriendState.Stranger.rawValue

                        realm.add(newUser)

                        sender = newUser
                    }

                    if let sender = sender {

                        updateUserWithUserID(sender.userID, useUserInfo: senderInfo, inRealm: realm)

                        message.fromFriend = sender

                        // 查询消息来自的 Group，为空就表示来自 User

                        var sendFromGroup: Group? = nil

                        if let recipientType = messageInfo["recipient_type"] as? String {

                            if recipientType == "Circle" {
                                if let groupID = messageInfo["recipient_id"] as? String {
                                    sendFromGroup = groupWithGroupID(groupID, inRealm: realm)

                                    if sendFromGroup == nil {
                                        
                                        let newGroup = Group()
                                        newGroup.groupID = groupID
                                        newGroup.includeMe = true
                                        // TODO: 此处还无法确定 group 类型，下面会请求 group 信息再确认

                                        realm.add(newGroup)

                                        sendFromGroup = newGroup
                                        
                                        // 若提及我，才同步group进而得到feed
                                        if let textContent = messageInfo["text_content"] as? String where textContent.yep_mentionedMeInRealm(realm) {
                                            groupWithGroupID(groupID: groupID, failureHandler: nil, completion: { (groupInfo) -> Void in
                                                dispatch_async(realmQueue) {

                                                    guard let realm = try? Realm() else {
                                                        return
                                                    }

                                                    realm.beginWrite()

                                                    if let group = syncGroupWithGroupInfo(groupInfo, inRealm: realm) {
                                                        if let
                                                            feedInfo = groupInfo["topic"] as? JSONDictionary,
                                                            feed = DiscoveredFeed.fromFeedInfo(feedInfo, groupInfo: groupInfo) {
                                                                saveFeedWithDiscoveredFeed(feed, group: group, inRealm: realm)
                                                        }
                                                    }

                                                    let _ = try? realm.commitWrite()

                                                    delay(1) {
                                                        dispatch_async(dispatch_get_main_queue()) {
                                                            NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.changedFeedConversation, object: nil)
                                                        }
                                                    }
                                                }
                                            })
                                        }
                                    }
                                }
                            }
                        }

                        // 纪录消息所属的 Conversation

                        var conversation: Conversation?

                        var conversationWithUser: User? // 注意：对于自己发送的消息被自己同步，要以其接收者来建立 Conversation

                        if let sendFromGroup = sendFromGroup {
                            conversation = sendFromGroup.conversation

                        } else {
                            if sender.userID != YepUserDefaults.userID.value {
                                conversation = sender.conversation
                                conversationWithUser = sender

                            } else {
                                guard let userID = messageInfo["recipient_id"] as? String else {
                                    message.deleteInRealm(realm)
                                    return
                                }

                                if let user = userWithUserID(userID, inRealm: realm) {
                                    conversation = user.conversation
                                    conversationWithUser = user

                                } else {
                                    let newUser = User()
                                    newUser.userID = userID

                                    realm.add(newUser)

                                    conversationWithUser = newUser
                                    
                                    userInfoOfUserWithUserID(userID, failureHandler: nil, completion: { userInfo in

                                        dispatch_async(dispatch_get_main_queue()) {
                                            guard let realm = try? Realm() else { return }

                                            realm.beginWrite()
                                            updateUserWithUserID(userID, useUserInfo: userInfo, inRealm: realm)
                                            let _ = try? realm.commitWrite()

                                            NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.updatedUser, object: nil)
                                        }
                                    })
                                }
                            }
                        }

                        //println("conversationWithUser: \(conversationWithUser)")

                        // 没有 Conversation 就尝试建立它

                        var createdNewConversation = false

                        if conversation == nil {
                            let newConversation = Conversation()

                            if let sendFromGroup = sendFromGroup {
                                newConversation.type = ConversationType.Group.rawValue
                                newConversation.withGroup = sendFromGroup
                            } else {
                                newConversation.type = ConversationType.OneToOne.rawValue
                                newConversation.withFriend = conversationWithUser
                            }

                            realm.add(newConversation)

                            conversation = newConversation

                            createdNewConversation = true
                        }

                        // 在保证有 Conversation 的情况下继续，不然消息没有必要保留

                        if let conversation = conversation {

                            // 先同步 read 状态
                            if let sender = message.fromFriend where sender.isMe {
                                message.readed = true

                            } else if let state = messageInfo["state"] as? String where state == "read" {
                                message.readed = true
                            }

                            // 再设置 conversation，调节 hasUnreadMessages 需要判定 readed
                            message.conversation = conversation

                            // 最后纪录消息余下的 detail 信息（其中设置 mentionedMe 需要 conversation）
                            recordMessageWithMessageID(messageID, detailInfo: messageInfo, inRealm: realm)

                            var sectionDateMessageID: String?

                            tryCreateSectionDateMessageInConversation(conversation, beforeMessage: message, inRealm: realm) { sectionDateMessage in
                                realm.add(sectionDateMessage)
                                sectionDateMessageID = sectionDateMessage.messageID
                            }

                            if createdNewConversation {

                                dispatch_async(dispatch_get_main_queue()) {
                                    NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.changedConversation, object: nil)
                                }
                            }

                            // Do furtherAction after sync

                            if let sectionDateMessageID = sectionDateMessageID {
                                furtherAction?(messageIDs: [sectionDateMessageID, messageID])
                            } else {
                                furtherAction?(messageIDs: [messageID])
                            }

                        } else {
                            message.deleteInRealm(realm)
                        }
                    }
                }
            }
        }
    }
}

